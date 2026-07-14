import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:moor/shared/models/lat_lng.dart' as model;
import '../helpers/marker_generator.dart';

class ExploreMapWidget extends StatefulWidget {
  final model.CameraPosition initialCameraPosition;
  final bool myLocationEnabled;
  final void Function(mapbox.MapboxMap controller)? onMapCreated;
  final void Function(double zoom)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final void Function(model.LatLng latLng)? onTap;
  final void Function(model.LatLng latLng)? onLongPress;
  final List<Map<String, dynamic>> places;
  final Map<String, dynamic>? selectedPlace;
  final int selectedMapTab;
  final void Function(Map<String, dynamic> place)? onPlaceTap;
  final VoidCallback? onGestureStart;

  const ExploreMapWidget({
    super.key,
    required this.initialCameraPosition,
    required this.myLocationEnabled,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
    required this.places,
    this.selectedPlace,
    required this.selectedMapTab,
    this.onPlaceTap,
    this.onGestureStart,
  });

  @override
  State<ExploreMapWidget> createState() => _ExploreMapWidgetState();
}

class _ExploreMapWidgetState extends State<ExploreMapWidget> {
  mapbox.MapboxMap? _mapboxMap;
  final Set<String> _registeredImageIds = {};
  double _currentZoom = 13.0;

  bool _isDeselecting = false;
  int _activePointers = 0;
  bool _needsGlobalDeselect = false;

  final List<String> _dynamicLayerIds = [];
  bool? _isBaseLayersVisible;
  bool _isUpdatingMarkers = false;
  bool _needsUpdateAgain = false;

  static const List<String> _permanentHideKeywords = [
    'poi',
    'transit',
    'airport',
    'rail',
    'bus',
    'station',
    'ferry',
    'shield',
    'motorway',
    'number',
    'crossing',
    'traffic',
    'landmark',
    'symbol',
    'monument',
    'worship',
    'cemetery',
    'lodging',
    'hotel',
    'restaurant',
    'cafe',
    'shop',
    'food',
    'beverage',
    'intersection',
    'entrance',
    'parking',
    'crosswalk',
    'turning',
    'road-label',
  ];

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialCameraPosition.zoom;
  }

  @override
  void didUpdateWidget(ExploreMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlace == null ||
        widget.selectedPlace?['id']?.toString() != oldWidget.selectedPlace?['id']?.toString()) {
      _isDeselecting = false;
    }
    final bool placesChanged = !_arePlacesEqual(
      widget.places,
      oldWidget.places,
    );
    final bool selectedChanged =
        widget.selectedPlace?['id']?.toString() !=
        oldWidget.selectedPlace?['id']?.toString();

    if (placesChanged) {
      _updateMarkers();
    } else if (selectedChanged) {
      _updateSelectionStyle();
    }
  }

  Future<void> _updateSelectionStyle() async {
    if (_mapboxMap == null) return;
    try {
      final String selectedId = widget.selectedPlace?['id']?.toString() ?? 'none';

      final String iconImageExpression = jsonEncode([
        "step",
        ["zoom"],
        ["concat", "dot-", ["get", "place_type"]],
        11.5,
        [
          "case",
          ["==", ["get", "id"], selectedId],
          ["concat", "selected-", ["get", "place_type"]],
          ["concat", "normal-", ["get", "place_type"]]
        ]
      ]);
      await _mapboxMap!.style.setStyleLayerProperty("places-layer", "icon-image", iconImageExpression);

      final String textSizeExpr = jsonEncode([
        "case",
        ["==", ["get", "id"], selectedId],
        13.5,
        12.0
      ]);
      await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-size", textSizeExpr);

      final String textRadialOffsetExpr = jsonEncode([
        "case",
        ["==", ["get", "id"], selectedId],
        1.6,
        1.4
      ]);
      await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-radial-offset", textRadialOffsetExpr);
      
      debugPrint("ExploreMapWidget: Fast selection style update succeeded. selectedId: $selectedId");
    } catch (e) {
      debugPrint("Error in _updateSelectionStyle(): $e");
    }
  }

  bool _arePlacesEqual(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['id']?.toString() != b[i]['id']?.toString()) return false;
      if (a[i]['type']?.toString() != b[i]['type']?.toString()) return false;
    }
    return true;
  }

  Future<void> _initNativeClusteringSourceAndLayers(mapbox.MapboxMap mapboxMap) async {
    try {
      try {
        final source = mapbox.GeoJsonSource(
          id: "places-source",
          data: '{"type": "FeatureCollection", "features": []}',
          cluster: true,
          clusterRadius: 20.0,
          clusterMaxZoom: 16.2,
          clusterProperties: {
            "dominant_type_code": ["max", ["get", "place_type_code"]],
          },
        );
        await mapboxMap.style.addSource(source);
      } catch (e) {
        debugPrint("places-source already exists or error: $e");
      }

      try {
        final placesLayer = mapbox.SymbolLayer(
          id: "places-layer",
          sourceId: "places-source",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textAllowOverlap: false,
          textIgnorePlacement: false,
          textVariableAnchor: ["right", "left"],
          textFont: ["DIN Pro Bold", "Arial Unicode MS Bold"],
          textHaloColor: 0xFFFFFFFF.toSigned(32),
          textHaloWidth: 1.5,
        );
        await mapboxMap.style.addLayer(placesLayer);
        await mapboxMap.style.setStyleLayerProperty("places-layer", "filter", '["!", ["has", "point_count"]]');
        await mapboxMap.style.setStyleLayerProperty("places-layer", "visibility", "visible");
      } catch (e) {
        debugPrint("places-layer already exists or error: $e");
      }

      try {
        final clustersDotsLayer = mapbox.SymbolLayer(
          id: "clusters-dots-layer",
          sourceId: "places-source",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          maxZoom: 1.5,
        );
        await mapboxMap.style.addLayer(clustersDotsLayer);
        await mapboxMap.style.setStyleLayerProperty("clusters-dots-layer", "filter", '["has", "point_count"]');
        await mapboxMap.style.setStyleLayerProperty("clusters-dots-layer", "visibility", "visible");
      } catch (e) {
        debugPrint("clusters-dots-layer already exists or error: $e");
      }

      try {
        final clustersPinsLayer = mapbox.SymbolLayer(
          id: "clusters-pins-layer",
          sourceId: "places-source",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          minZoom: 1.5,
        );
        await mapboxMap.style.addLayer(clustersPinsLayer);
        await mapboxMap.style.setStyleLayerProperty("clusters-pins-layer", "filter", '["has", "point_count"]');
        await mapboxMap.style.setStyleLayerProperty("clusters-pins-layer", "visibility", "visible");
      } catch (e) {
        debugPrint("clusters-pins-layer already exists or error: $e");
      }
    } catch (e) {
      debugPrint("ExploreMapWidget: Error initializing native clustering: $e");
    }
  }

  Future<mapbox.MbxImage> _convertPngToMbxImage(Uint8List pngBytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(pngBytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;
    return mapbox.MbxImage(
      width: image.width,
      height: image.height,
      data: pngBytes,
    );
  }

  Future<void> _hideDefaultLayers(mapbox.MapboxMap mapboxMap) async {
    try {
      final layers = await mapboxMap.style.getStyleLayers();
      for (final layerInfo in layers) {
        if (layerInfo != null) {
          final String idLower = layerInfo.id.toLowerCase();
          // Skip our own annotation layers
          if (idLower.contains('places-') ||
              idLower.contains('clusters-') ||
              idLower.contains('mapbox-android-pointannotation') ||
              idLower.contains('pointannotation') ||
              idLower.contains('custom') && idLower.contains('annotation')) {
            continue;
          }

          // Simplify default label layers' text-fields to prioritize English name_en over name field, removing inline reference shields
          if (idLower.contains('label')) {
            try {
              await mapboxMap.style.setStyleLayerProperty(
                layerInfo.id,
                'text-field',
                jsonEncode([
                  'coalesce',
                  ['get', 'name_en'],
                  ['get', 'name']
                ]),
              );
              debugPrint("ExploreMapWidget: Simplified label layer ${layerInfo.id} text-field successfully.");
            } catch (e) {
              // Ignore if layer doesn't support text-field
            }
          }

          // Try to clear default icon images (like road shields) to prevent broken placeholder dots (e.g. ••••)
          try {
            await mapboxMap.style.setStyleLayerProperty(
              layerInfo.id,
              'icon-image',
              jsonEncode(''),
            );
          } catch (e) {
            // Ignore if layer doesn't support icon-image
          }

          bool shouldHide = false;
          for (final keyword in _permanentHideKeywords) {
            if (idLower.contains(keyword)) {
              shouldHide = true;
              break;
            }
          }

          if (shouldHide) {
            try {
              await mapboxMap.style.setStyleLayerProperty(
                layerInfo.id,
                'visibility',
                'none',
              );
              debugPrint("ExploreMapWidget: Hidden layer ${layerInfo.id} successfully.");
            } catch (e) {
              debugPrint("ExploreMapWidget: Failed to hide layer ${layerInfo.id}: $e");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("ExploreMapWidget: Error dynamically hiding style layers: $e");
    }
  }

  Future<void> _initDynamicLayers(mapbox.MapboxMap mapboxMap) async {
    try {
      final layers = await mapboxMap.style.getStyleLayers();
      _dynamicLayerIds.clear();

      final List<String> keywordsToControl = [
        'label',
        'boundary',
        'border',
        'admin',
      ];

      for (final layerInfo in layers) {
        if (layerInfo != null) {
          final String idLower = layerInfo.id.toLowerCase();

          // Skip annotations
          if (idLower.contains('mapbox-android-pointannotation') ||
              idLower.contains('pointannotation') ||
              idLower.contains('custom') && idLower.contains('annotation')) {
            continue;
          }

          // Skip permanently hidden layers
          bool isPermanentlyHidden = false;
          for (final keyword in _permanentHideKeywords) {
            if (idLower.contains(keyword)) {
              isPermanentlyHidden = true;
              break;
            }
          }
          if (isPermanentlyHidden) continue;

          bool matches = false;
          for (final keyword in keywordsToControl) {
            if (idLower.contains(keyword)) {
              matches = true;
              break;
            }
          }

          if (matches) {
            _dynamicLayerIds.add(layerInfo.id);
          }
        }
      }
      debugPrint(
        "ExploreMapWidget: Initialized ${_dynamicLayerIds.length} dynamic layers for zoom control.",
      );
    } catch (e) {
      debugPrint("Error initializing dynamic layers: $e");
    }
  }

  Future<void> _applyBaseLabelVisibility(double zoom) async {
    if (_mapboxMap == null || _dynamicLayerIds.isEmpty) return;

    // Zoom threshold: 3.0
    // Zoom < 3.0 -> Hide labels/borders
    // Zoom >= 3.0 -> Show labels/borders
    final bool shouldBeVisible = zoom >= 1.5;

    if (_isBaseLayersVisible == shouldBeVisible) return;
    _isBaseLayersVisible = shouldBeVisible;

    final String visibilityValue = shouldBeVisible ? 'visible' : 'none';
    debugPrint(
      "ExploreMapWidget: Setting dynamic layers visibility to $visibilityValue for zoom $zoom",
    );

    for (final layerId in _dynamicLayerIds) {
      try {
        await _mapboxMap!.style.setStyleLayerProperty(
          layerId,
          'visibility',
          visibilityValue,
        );
      } catch (e) {
        // Ignore layers that do not support visibility property
      }
    }
  }

  Future<void> _updateMarkers() async {
    if (_mapboxMap == null) return;

    if (_isUpdatingMarkers) {
      _needsUpdateAgain = true;
      return;
    }
    _isUpdatingMarkers = true;
    _needsUpdateAgain = false;

    try {
      debugPrint(
        "ExploreMapWidget: _updateMarkers() called with ${widget.places.length} places (native)",
      );

      // 1. Gather all unique types in places, including all 10 predefined types
      final List<String> allPredefinedTypes = [
        'restaurant',
        'coffee',
        'bakery',
        'bars',
        'supermarket',
        'pharmacy',
        'hotel',
        'park',
        'airport',
        'other',
        'movies',
        'concerts',
        'sports',
      ];
      final uniqueTypes = widget.places
          .map((p) => p['type']?.toString().toLowerCase().trim() ?? 'default')
          .toSet();
      uniqueTypes.addAll(allPredefinedTypes);

      final double dpr = ui.PlatformDispatcher.instance.views.isNotEmpty
          ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio
          : 3.0;

      // 2. Register style images on demand
      for (final type in uniqueTypes) {
        bool registeredAny = false;
        if (!_registeredImageIds.contains("normal-$type")) {
          try {
            final pngBytes = await MarkerGenerator.getNormalPin(type);
            final mbxImage = await _convertPngToMbxImage(pngBytes);
            await _mapboxMap!.style.addStyleImage(
              "normal-$type",
              dpr,
              mbxImage,
              false,
              <mapbox.ImageStretches?>[],
              <mapbox.ImageStretches?>[],
              mapbox.ImageContent(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
            );
            _registeredImageIds.add("normal-$type");
            registeredAny = true;
          } catch (e) {
            debugPrint("Error registering normal-$type: $e");
          }
        }
        if (!_registeredImageIds.contains("selected-$type")) {
          try {
            final pngBytes = await MarkerGenerator.getSelectedPin(type);
            final mbxImage = await _convertPngToMbxImage(pngBytes);
            await _mapboxMap!.style.addStyleImage(
              "selected-$type",
              dpr,
              mbxImage,
              false,
              <mapbox.ImageStretches?>[],
              <mapbox.ImageStretches?>[],
              mapbox.ImageContent(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
            );
            _registeredImageIds.add("selected-$type");
            registeredAny = true;
          } catch (e) {
            debugPrint("Error registering selected-$type: $e");
          }
        }
        if (!_registeredImageIds.contains("dot-$type")) {
          try {
            final pngBytes = await MarkerGenerator.getDotPin(type);
            final mbxImage = await _convertPngToMbxImage(pngBytes);
            await _mapboxMap!.style.addStyleImage(
              "dot-$type",
              dpr,
              mbxImage,
              false,
              <mapbox.ImageStretches?>[],
              <mapbox.ImageStretches?>[],
              mapbox.ImageContent(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
            );
            _registeredImageIds.add("dot-$type");
            registeredAny = true;
          } catch (e) {
            debugPrint("Error registering dot-$type: $e");
          }
        }
        if (registeredAny) {
          debugPrint("ExploreMapWidget: Registered style images for type: $type");
        }
      }

      // 3. Construct GeoJSON features
      final List<Map<String, dynamic>> features = [];
      for (final p in widget.places) {
        final double lat = double.tryParse(p['latitude']?.toString() ?? '') ?? 0.0;
        final double lng = double.tryParse(p['longitude']?.toString() ?? '') ?? 0.0;
        if (lat == 0.0 || lng == 0.0) continue;

        final String name = p['name']?.toString() ?? '';
        final String arName = p['arabicName']?.toString() ?? '';
        final String mainName = arName.isNotEmpty ? arName : name;

        final String placeType = p['type']?.toString().toLowerCase().trim() ?? 'default';
        final double rating = double.tryParse(p['rating']?.toString() ?? '') ?? 0.0;
        final String ratingAndType = "${rating.toStringAsFixed(2)}_$placeType";

        int placeTypeCode = 1; // other / default
        if (placeType == 'restaurant') {
          placeTypeCode = 2;
        } else if (placeType == 'supermarket') {
          placeTypeCode = 3;
        } else if (placeType == 'pharmacy') {
          placeTypeCode = 4;
        } else if (placeType == 'bakery') {
          placeTypeCode = 5;
        } else if (placeType == 'bars') {
          placeTypeCode = 6;
        } else if (placeType == 'coffee') {
          placeTypeCode = 7;
        } else if (placeType == 'hotel') {
          placeTypeCode = 8;
        } else if (placeType == 'park') {
          placeTypeCode = 9;
        } else if (placeType == 'airport') {
          placeTypeCode = 10;
        }

        features.add({
          "type": "Feature",
          "id": p['id'].toString(),
          "geometry": {
            "type": "Point",
            "coordinates": [lng, lat]
          },
          "properties": {
            "id": p['id'].toString(),
            "place_type": placeType,
            "title": mainName,
            "rating_and_type": ratingAndType,
            "place_type_code": placeTypeCode,
          }
        });
      }

      final geojson = {
        "type": "FeatureCollection",
        "features": features
      };

      debugPrint("ExploreMapWidget: Generated ${features.length} GeoJSON features.");

      final String geojsonStr = jsonEncode(geojson);
      await _mapboxMap!.style.setStyleSourceProperty("places-source", "data", geojsonStr);

      // 4. Build color match expressions for labels
      String colorToHex(Color color) {
        final int r = (color.r * 255.0).round().clamp(0, 255);
        final int g = (color.g * 255.0).round().clamp(0, 255);
        final int b = (color.b * 255.0).round().clamp(0, 255);
        return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
      }

      final List<dynamic> colorMatchExpr = ["match", ["get", "place_type"]];
      for (final type in uniqueTypes) {
        final color = MarkerGenerator.getMarkerColor(type);
        final String hexStr = colorToHex(color);
        if (!colorMatchExpr.contains(type)) {
          colorMatchExpr.add(type);
          colorMatchExpr.add(hexStr);
        }
      }
      if (uniqueTypes.isEmpty) {
        colorMatchExpr.add("dummy_type");
        colorMatchExpr.add("#000000");
      }
      colorMatchExpr.add("#000000");

      final List<dynamic> clusterColorMatchExpr = ["match", ["get", "dominant_place_type"]];
      for (final type in uniqueTypes) {
        final color = MarkerGenerator.getMarkerColor(type);
        final String hexStr = colorToHex(color);
        if (!clusterColorMatchExpr.contains(type)) {
          clusterColorMatchExpr.add(type);
          clusterColorMatchExpr.add(hexStr);
        }
      }
      if (uniqueTypes.isEmpty) {
        clusterColorMatchExpr.add("dummy_type");
        clusterColorMatchExpr.add("#000000");
      }
      clusterColorMatchExpr.add("#000000");

      // 5. Set layer styling expressions
      final String selectedId = widget.selectedPlace?['id']?.toString() ?? 'none';

      // --- Places Layer Styles ---
      final String iconImageExpression = jsonEncode([
        "step",
        ["zoom"],
        ["concat", "dot-", ["get", "place_type"]],
        1.5,
        [
          "case",
          ["==", ["get", "id"], selectedId],
          ["concat", "selected-", ["get", "place_type"]],
          ["concat", "normal-", ["get", "place_type"]]
        ]
      ]);
      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "icon-image", iconImageExpression);
      } catch (e) {
        debugPrint("Error setting places-layer icon-image: $e");
      }

      final String textFieldExpression = jsonEncode([
        "step",
        ["zoom"],
        "",
        1.5,
        ["get", "title"]
      ]);
      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-field", textFieldExpression);
      } catch (e) {
        debugPrint("Error setting places-layer text-field: $e");
      }

      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-color", jsonEncode(colorMatchExpr));
      } catch (e) {
        debugPrint("Error setting places-layer text-color: $e");
      }

      final String textSizeExpr = jsonEncode([
        "case",
        ["==", ["get", "id"], selectedId],
        13.5,
        12.0
      ]);
      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-size", textSizeExpr);
      } catch (e) {
        debugPrint("Error setting places-layer text-size: $e");
      }

      final String textRadialOffsetExpr = jsonEncode([
        "case",
        ["==", ["get", "id"], selectedId],
        1.6,
        1.4
      ]);
      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-radial-offset", textRadialOffsetExpr);
      } catch (e) {
        debugPrint("Error setting places-layer text-radial-offset: $e");
      }

      // --- Clusters Layer Styles ---
      final String clusterDotsIconImageExpression = jsonEncode([
        "case",
        ["==", ["%", ["get", "cluster_id"], 7], 0],
        "dot-restaurant",
        ["==", ["%", ["get", "cluster_id"], 7], 1],
        "dot-coffee",
        ["==", ["%", ["get", "cluster_id"], 7], 2],
        "dot-hotel",
        ["==", ["%", ["get", "cluster_id"], 7], 3],
        "dot-park",
        ["==", ["%", ["get", "cluster_id"], 7], 4],
        "dot-movies",
        ["==", ["%", ["get", "cluster_id"], 7], 5],
        "dot-concerts",
        "dot-other"
      ]);

      final String clusterPinsIconImageExpression = jsonEncode([
        "case",
        ["==", ["%", ["get", "cluster_id"], 5], 0],
        [
          "case",
          ["==", ["%", ["get", "cluster_id"], 7], 0],
          "normal-restaurant",
          ["==", ["%", ["get", "cluster_id"], 7], 1],
          "normal-coffee",
          ["==", ["%", ["get", "cluster_id"], 7], 2],
          "normal-hotel",
          ["==", ["%", ["get", "cluster_id"], 7], 3],
          "normal-park",
          ["==", ["%", ["get", "cluster_id"], 7], 4],
          "normal-movies",
          ["==", ["%", ["get", "cluster_id"], 7], 5],
          "normal-concerts",
          "normal-other"
        ],
        [
          "case",
          ["==", ["%", ["get", "cluster_id"], 7], 0],
          "dot-restaurant",
          ["==", ["%", ["get", "cluster_id"], 7], 1],
          "dot-coffee",
          ["==", ["%", ["get", "cluster_id"], 7], 2],
          "dot-hotel",
          ["==", ["%", ["get", "cluster_id"], 7], 3],
          "dot-park",
          ["==", ["%", ["get", "cluster_id"], 7], 4],
          "dot-movies",
          ["==", ["%", ["get", "cluster_id"], 7], 5],
          "dot-concerts",
          "dot-other"
        ]
      ]);

      final String clusterIconSizeExpression = jsonEncode([
        "step",
        ["get", "point_count"],
        0.4, // Small clusters (< 10 points)
        10,
        0.55,  // Medium clusters (10-99 points)
        100,
        0.7   // Large clusters (>= 100 points)
      ]);

      for (final layerId in ["clusters-dots-layer", "clusters-pins-layer"]) {
        try {
          await _mapboxMap!.style.setStyleLayerProperty(
            layerId,
            "icon-image",
            layerId == "clusters-dots-layer" ? clusterDotsIconImageExpression : clusterPinsIconImageExpression
          );
        } catch (e) {
          debugPrint("Error setting $layerId icon-image: $e");
        }

        try {
          await _mapboxMap!.style.setStyleLayerProperty(layerId, "icon-size", clusterIconSizeExpression);
        } catch (e) {
          debugPrint("Error setting $layerId icon-size: $e");
        }

        try {
          await _mapboxMap!.style.setStyleLayerProperty(layerId, "text-field", "");
        } catch (e) {
          debugPrint("Error setting $layerId text-field: $e");
        }

        try {
          await _mapboxMap!.style.setStyleLayerProperty(layerId, "text-size", 0.0);
        } catch (e) {
          debugPrint("Error setting $layerId text-size: $e");
        }

        try {
          await _mapboxMap!.style.setStyleLayerProperty(layerId, "text-opacity", 0.0);
        } catch (e) {
          debugPrint("Error setting $layerId text-opacity: $e");
        }

        try {
          await _mapboxMap!.style.setStyleLayerProperty(layerId, "text-color", "#FFFFFF");
        } catch (e) {
          debugPrint("Error setting $layerId text-color: $e");
        }
      }

      // Repeatedly enforce hiding default road labels, shields, and intersections to override Mapbox async style loads
      try {
        await _mapboxMap!.style.setStyleLayerProperty("road-label", "visibility", "none");
        await _mapboxMap!.style.setStyleLayerProperty("road-number-shield", "visibility", "none");
        await _mapboxMap!.style.setStyleLayerProperty("road-exit-shield", "visibility", "none");
        await _mapboxMap!.style.setStyleLayerProperty("road-intersection", "visibility", "none");
        await _mapboxMap!.style.setStyleLayerProperty("crosswalks", "visibility", "none");
        debugPrint("ExploreMapWidget: Enforced road/shield layer visibility overrides.");
      } catch (e) {
        // Ignore if some layers do not exist
      }

      debugPrint("ExploreMapWidget: Successfully updated native GeoJSON source & styling layers.");
    } catch (e, stackTrace) {
      debugPrint("ExploreMapWidget: Outer error in _updateMarkers(): $e");
      debugPrint(stackTrace.toString());
    } finally {
      _isUpdatingMarkers = false;
      if (_needsUpdateAgain) {
        _updateMarkers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String mapboxAccessToken = String.fromEnvironment(
      "MAPBOX_ACCESS_TOKEN",
      defaultValue:
          "pk.eyJ1IjoiYmFzaWlpIiwiYSI6ImNtcmhjZ2tocDFia2YzMHF6b3NvZzE0dzEifQ.u_cHUq4ZPa-busa7KzLyew",
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (pointerEvent) {
        _activePointers++;
      },
      onPointerUp: (pointerEvent) {
        _activePointers--;
        if (_activePointers < 0) _activePointers = 0;
        if (_activePointers == 0 && _needsGlobalDeselect) {
          _needsGlobalDeselect = false;
          _isDeselecting = false;
          debugPrint("ExploreMapWidget Listener: Gesture ended, triggering global deselect.");
          if (widget.onTap != null) {
            widget.onTap!(const model.LatLng(0.0, 0.0));
          }
        }
      },
      onPointerCancel: (pointerEvent) {
        _activePointers--;
        if (_activePointers < 0) _activePointers = 0;
        if (_activePointers == 0 && _needsGlobalDeselect) {
          _needsGlobalDeselect = false;
          _isDeselecting = false;
          debugPrint("ExploreMapWidget Listener: Gesture canceled, triggering global deselect.");
          if (widget.onTap != null) {
            widget.onTap!(const model.LatLng(0.0, 0.0));
          }
        }
      },
      onPointerMove: (pointerEvent) {
        if (widget.selectedPlace != null && !_isDeselecting) {
          debugPrint("ExploreMapWidget Listener: User map gesture detected, hiding card locally.");
          _isDeselecting = true;
          _needsGlobalDeselect = true;
          if (widget.onGestureStart != null) {
            widget.onGestureStart!();
          }
        }
      },
      child: mapbox.MapWidget(
        key: const ValueKey('explore_mapbox_widget_key'),
        resourceOptions: mapbox.ResourceOptions(accessToken: mapboxAccessToken),
        styleUri: "mapbox://styles/basiii/cmri3vcu7007401qr2y7l5bue",
        onStyleLoadedListener: (styleLoaded) {
          debugPrint(
            "ExploreMapWidget: Style fully loaded. Reinitializing annotations...",
          );
          _registeredImageIds.clear();
          if (_mapboxMap != null) {
            Future.microtask(() async {
              await _hideDefaultLayers(_mapboxMap!);
              await _initDynamicLayers(_mapboxMap!);
              _isBaseLayersVisible = null;
              await _applyBaseLabelVisibility(_currentZoom);
              try {
                await _mapboxMap!.gestures.updateSettings(
                  mapbox.GesturesSettings(
                    rotateEnabled: false,
                    simultaneousRotateAndPinchToZoomEnabled: false,
                    pitchEnabled: false,
                  ),
                );
              } catch (e) {
                debugPrint("Error disabling map rotation on style load: $e");
              }
              await _initNativeClusteringSourceAndLayers(_mapboxMap!);
              await _updateMarkers();
            });
          }
        },
        cameraOptions: mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(
              widget.initialCameraPosition.target.longitude,
              widget.initialCameraPosition.target.latitude,
            ),
          ).toJson(),
          zoom: widget.initialCameraPosition.zoom,
        ),
        onMapCreated: (mapboxMap) {
          _mapboxMap = mapboxMap;

          Future.microtask(() async {
            await _hideDefaultLayers(mapboxMap);

            // Set projection to flat map (Mercator) instead of 3D Globe
            try {
              await mapboxMap.style.setProjection("mercator");
            } catch (e) {
              debugPrint("Error setting map projection: $e");
            }

            // Restrict camera bounds to prevent excessive zoom out while showing flat map
            try {
              await mapboxMap.setBounds(mapbox.CameraBoundsOptions(minZoom: 1.2));
            } catch (e) {
              debugPrint("Error setting map bounds: $e");
            }

            await mapboxMap.logo.updateSettings(
              mapbox.LogoSettings(position: mapbox.OrnamentPosition.BOTTOM_LEFT),
            );
            await mapboxMap.attribution.updateSettings(
              mapbox.AttributionSettings(
                position: mapbox.OrnamentPosition.BOTTOM_LEFT,
              ),
            );
            await mapboxMap.compass.updateSettings(
              mapbox.CompassSettings(enabled: false),
            );
            await mapboxMap.scaleBar.updateSettings(
              mapbox.ScaleBarSettings(enabled: false),
            );

            // Disable 360-degree rotation gesture and tilt (pitch) gesture
            try {
              await mapboxMap.gestures.updateSettings(
                mapbox.GesturesSettings(
                  rotateEnabled: false,
                  simultaneousRotateAndPinchToZoomEnabled: false,
                  pitchEnabled: false,
                ),
              );
            } catch (e) {
              debugPrint("Error disabling map rotation: $e");
            }

            await _initNativeClusteringSourceAndLayers(mapboxMap);
            await _initDynamicLayers(mapboxMap);
            _isBaseLayersVisible = null;
            await _applyBaseLabelVisibility(_currentZoom);
            await _updateMarkers();

            if (widget.onMapCreated != null) {
              widget.onMapCreated!(mapboxMap);
            }
          });
        },
        onCameraChangeListener: (cameraChangedEvent) {
          if (_mapboxMap != null) {
            _mapboxMap!.getCameraState().then((state) {
              _currentZoom = state.zoom;

              _applyBaseLabelVisibility(_currentZoom);

              if (widget.onCameraMove != null) {
                widget.onCameraMove!(_currentZoom);
              }
            });
          }
        },
        onMapIdleListener: (mapIdleEvent) {
          if (widget.onCameraIdle != null) {
            widget.onCameraIdle!();
          }
        },
        onTapListener: (point) async {
          if (_mapboxMap == null) return;

          // Detect if the coordinate is geographical due to the iOS plugin bug
          final bool isIosGeoBug = point.x.abs() <= 90.0 && point.y.abs() <= 180.0;

          mapbox.ScreenCoordinate screenPt;
          model.LatLng geoLatLng;

          if (isIosGeoBug) {
            geoLatLng = model.LatLng(point.x, point.y);
            try {
              screenPt = await _mapboxMap!.pixelForCoordinate(
                mapbox.Point(
                  coordinates: mapbox.Position(point.y, point.x),
                ).toJson(),
              );
            } catch (e) {
              debugPrint("Error converting coordinate to pixel: $e");
              screenPt = point;
            }
          } else {
            screenPt = point;
            try {
              final value = await _mapboxMap!.coordinateForPixel(point);
              final geoPoint = mapbox.Point.fromJson(
                Map<String, dynamic>.from(value),
              );
              geoLatLng = model.LatLng(
                geoPoint.coordinates.lat.toDouble(),
                geoPoint.coordinates.lng.toDouble(),
              );
            } catch (e) {
              debugPrint("Error converting pixel to coordinate: $e");
              geoLatLng = const model.LatLng(0.0, 0.0);
            }
          }

          // Query within a 24x24 pixel bounding box around the tap for precise selection
          const double tolerance = 12.0;
          final screenBox = mapbox.ScreenBox(
            min: mapbox.ScreenCoordinate(x: screenPt.x - tolerance, y: screenPt.y - tolerance),
            max: mapbox.ScreenCoordinate(x: screenPt.x + tolerance, y: screenPt.y + tolerance),
          );

          final renderedQueryGeometry = mapbox.RenderedQueryGeometry(
            value: json.encode(screenBox.encode()),
            type: mapbox.Type.SCREEN_BOX,
          );

          try {
            final features = await _mapboxMap!.queryRenderedFeatures(
              renderedQueryGeometry,
              mapbox.RenderedQueryOptions(
                layerIds: ["places-layer", "clusters-layer"],
                filter: null,
              ),
            );

            debugPrint("ExploreMapWidget Tap: Queried ${features.length} features.");
            if (features.isNotEmpty && features.first != null) {
              final feature = features.first!;
              final properties = feature.feature['properties'] as Map?;
              debugPrint("ExploreMapWidget Tap: Properties = $properties");
              if (properties != null) {
                final String? dominantId = properties['dominant_id']?.toString();
                final String? placeId = properties['id']?.toString();
                final String targetId = dominantId ?? placeId ?? '';

                if (targetId.isNotEmpty) {
                  final place = widget.places.firstWhere(
                    (p) => p['id'].toString() == targetId,
                    orElse: () => {},
                  );
                  if (place.isNotEmpty && widget.onPlaceTap != null) {
                    if (widget.selectedPlace?['id']?.toString() == targetId) {
                      debugPrint("ExploreMapWidget Tap: Already selected place clicked again, deselecting.");
                      if (widget.onTap != null) {
                        widget.onTap!(geoLatLng);
                      }
                    } else {
                      debugPrint("ExploreMapWidget Tap: Place clicked natively, selecting: $targetId");
                      widget.onPlaceTap!(place);
                    }
                    return;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error querying rendered features: $e");
          }

          // If no feature was clicked, deselect!
          debugPrint("ExploreMapWidget Tap: Map clicked, deselecting.");
          if (widget.onTap != null) {
            widget.onTap!(geoLatLng);
          }
        },
        onLongTapListener: (point) async {
          if (widget.onLongPress != null && _mapboxMap != null) {
            final bool isIosGeoBug = point.x.abs() <= 90.0 && point.y.abs() <= 180.0;
            if (isIosGeoBug) {
              widget.onLongPress!(model.LatLng(point.x, point.y));
            } else {
              try {
                final value = await _mapboxMap!.coordinateForPixel(point);
                final geoPoint = mapbox.Point.fromJson(
                  Map<String, dynamic>.from(value),
                );
                widget.onLongPress!(
                  model.LatLng(
                    geoPoint.coordinates.lat.toDouble(),
                    geoPoint.coordinates.lng.toDouble(),
                  ),
                );
              } catch (e) {
                debugPrint("Error converting pixel to coordinate on long press: $e");
              }
            }
          }
        },
      ),
    );
  }
}

// Native clustering helper classes removed
