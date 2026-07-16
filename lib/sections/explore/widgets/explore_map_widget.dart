import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moor/shared/models/lat_lng.dart' as model;
import '../../../../config/secrets.dart';
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

  final String selectedCategory;

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
    this.selectedCategory = '',
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
  void dispose() {
    _registeredImageIds.clear();
    _dynamicLayerIds.clear();
    _mapboxMap = null;
    super.dispose();
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

    if (placesChanged || selectedChanged) {
      _updateMarkers();
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
          clusterMaxZoom: 13,
          clusterRadius: 50,
        );
        await mapboxMap.style.addSource(source);
      } catch (e) {
        debugPrint("places-source already exists or error: $e");
      }

      try {
        final heatmapSource = mapbox.GeoJsonSource(
          id: "places-heatmap-source",
          data: '{"type": "FeatureCollection", "features": []}',
          cluster: false,
        );
        await mapboxMap.style.addSource(heatmapSource);
      } catch (e) {
        debugPrint("places-heatmap-source already exists or error: $e");
      }

      try {
        final heatmapLayer = mapbox.HeatmapLayer(
          id: "places-heatmap-layer",
          sourceId: "places-heatmap-source",
        );
        await mapboxMap.style.addLayer(heatmapLayer);
        
        await mapboxMap.style.setStyleLayerProperty("places-heatmap-layer", "heatmap-color", jsonEncode([
          "interpolate",
          ["linear"],
          ["heatmap-density"],
          0.0, "rgba(124, 87, 252, 0.0)",
          0.15, "rgba(124, 87, 252, 0.35)",
          0.35, "rgba(124, 87, 252, 0.7)",
          0.55, "rgba(0, 130, 255, 0.8)",
          0.75, "rgba(0, 210, 255, 0.85)",
          0.9, "rgba(0, 240, 255, 0.9)",
          0.97, "rgba(46, 204, 113, 0.9)",
          1.0, "rgba(46, 204, 113, 0.95)"
        ]));
        
        await mapboxMap.style.setStyleLayerProperty("places-heatmap-layer", "heatmap-weight", jsonEncode([
          "interpolate",
          ["linear"],
          ["get", "people_count"],
          0, 0.1,
          10, 0.3,
          100, 1.0,
          500, 2.2
        ]));

        await mapboxMap.style.setStyleLayerProperty("places-heatmap-layer", "heatmap-intensity", jsonEncode([
          "interpolate",
          ["linear"],
          ["zoom"],
          0, 1.1,
          4, 1.4,
          9, 1.6,
          13, 1.8
        ]));

        await mapboxMap.style.setStyleLayerProperty("places-heatmap-layer", "heatmap-radius", jsonEncode([
          "interpolate",
          ["linear"],
          ["zoom"],
          0, 26.0,
          4, 36.0,
          9, 45.0,
          13, 35.0,
          16, 25.0
        ]));

        await mapboxMap.style.setStyleLayerProperty("places-heatmap-layer", "heatmap-opacity", jsonEncode([
          "interpolate",
          ["linear"],
          ["zoom"],
          12, 0.95,
          15, 0.3,
          17, 0.0
        ]));

        final String initialHeatmapVisibility = widget.selectedMapTab == 2 ? "visible" : "none";
        await mapboxMap.style.setStyleLayerProperty("places-heatmap-layer", "visibility", initialHeatmapVisibility);
      } catch (e) {
        debugPrint("places-heatmap-layer already exists or error: $e");
      }

      try {
        final placesLayer = mapbox.SymbolLayer(
          id: "places-layer",
          sourceId: "places-source",
          iconAllowOverlap: false,
          iconIgnorePlacement: false,
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

      final double maxZoomDots = 6.0;
      final double minZoomMedium = 6.0;
      final double maxZoomMedium = 9.0;
      final double minZoomPins = 9.0;

      final String initialDotsFilter = '["has", "point_count"]';

      try {
        final clustersDotsLayer = mapbox.SymbolLayer(
          id: "clusters-dots-layer",
          sourceId: "places-source",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          maxZoom: maxZoomDots,
        );
        await mapboxMap.style.addLayer(clustersDotsLayer);
        await mapboxMap.style.setStyleLayerProperty("clusters-dots-layer", "filter", initialDotsFilter);
        await mapboxMap.style.setStyleLayerProperty("clusters-dots-layer", "visibility", "visible");
      } catch (e) {
        debugPrint("clusters-dots-layer already exists or error: $e");
      }

      try {
        final clustersMediumLayer = mapbox.SymbolLayer(
          id: "clusters-medium-layer",
          sourceId: "places-source",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textAllowOverlap: false,
          textIgnorePlacement: false,
          textVariableAnchor: ["right", "left"],
          textFont: ["DIN Pro Bold", "Arial Unicode MS Bold"],
          textHaloColor: 0xFFFFFFFF.toSigned(32),
          textHaloWidth: 1.5,
          minZoom: minZoomMedium,
          maxZoom: maxZoomMedium,
        );
        await mapboxMap.style.addLayer(clustersMediumLayer);
        await mapboxMap.style.setStyleLayerProperty("clusters-medium-layer", "filter", '["has", "point_count"]');
        await mapboxMap.style.setStyleLayerProperty("clusters-medium-layer", "visibility", "visible");
      } catch (e) {
        debugPrint("clusters-medium-layer already exists or error: $e");
      }

      try {
        final clustersPinsLayer = mapbox.SymbolLayer(
          id: "clusters-pins-layer",
          sourceId: "places-source",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textAllowOverlap: false,
          textIgnorePlacement: false,
          textVariableAnchor: ["right", "left"],
          textFont: ["DIN Pro Bold", "Arial Unicode MS Bold"],
          textHaloColor: 0xFFFFFFFF.toSigned(32),
          textHaloWidth: 1.5,
          minZoom: minZoomPins,
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
          if (idLower.contains('shield') || idLower.contains('road') || idLower.contains('highway')) {
            try {
              await mapboxMap.style.setStyleLayerProperty(
                layerInfo.id,
                'icon-image',
                jsonEncode(''),
              );
            } catch (e) {
              // Ignore if layer doesn't support icon-image
            }
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


  String _resolvePlaceType(Map<String, dynamic> p) {
    return MarkerGenerator.resolveType(
      p['type']?.toString() ?? '',
      p['name']?.toString() ?? '',
      p['arabicName']?.toString() ?? '',
    );
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
        'mosque',
        'school',
        'library',
        'museum',
        'exhibition'
      ];
      final uniqueTypes = widget.places
          .map((p) => _resolvePlaceType(p))
          .toSet();
      uniqueTypes.addAll(allPredefinedTypes);
      if (widget.selectedPlace != null) {
        uniqueTypes.add(_resolvePlaceType(widget.selectedPlace!));
      }

      final String selectedId = widget.selectedPlace?['id']?.toString() ?? 'none';

      final double dpr = ui.PlatformDispatcher.instance.views.isNotEmpty
          ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio
          : 3.0;

      final bool isFilterActive = widget.selectedCategory.isNotEmpty;

      // 2. Gather unique image combinations to register
      final Set<String> imagesToRegister = {};
      for (final type in uniqueTypes) {
        imagesToRegister.add("dot-$type");
        imagesToRegister.add("live-$type");
        imagesToRegister.add("selected_live-$type");
        // Fallbacks
        imagesToRegister.add("normal-$type-none");
        imagesToRegister.add("selected-$type-none");
      }

      for (final p in widget.places) {
        final String resolvedType = _resolvePlaceType(p);
        final double ratingVal = double.tryParse(p['rating']?.toString() ?? '') ?? 0.0;
        final String ratingStr = (widget.selectedMapTab != 2 && isFilterActive && ratingVal > 0.0) ? ratingVal.toStringAsFixed(1) : 'none';
        
        final String pid = p['id']?.toString() ?? '';
        final bool isSel = pid == selectedId;
        final bool isCheckIn = p['isCheckIn'] == true;
        
        if (isCheckIn) {
          if (isSel) {
            imagesToRegister.add("selected_checkin-$pid");
          } else {
            imagesToRegister.add("checkin-$pid");
          }
        } else {
          if (widget.selectedMapTab == 2) {
            if (isSel) {
              imagesToRegister.add("selected_live-$resolvedType");
            } else {
              imagesToRegister.add("live-$resolvedType");
            }
          } else {
            if (isSel) {
              imagesToRegister.add("selected-$resolvedType-$ratingStr");
            } else {
              imagesToRegister.add("normal-$resolvedType-$ratingStr");
            }
          }
        }
      }

      if (widget.selectedPlace != null) {
        final String resolvedType = _resolvePlaceType(widget.selectedPlace!);
        final String pid = widget.selectedPlace!['id']?.toString() ?? '';
        final bool isCheckIn = widget.selectedPlace!['isCheckIn'] == true;
        
        if (isCheckIn) {
          imagesToRegister.add("selected_checkin-$pid");
        } else {
          if (widget.selectedMapTab == 2) {
            imagesToRegister.add("selected_live-$resolvedType");
          } else {
            final double ratingVal = double.tryParse(widget.selectedPlace!['rating']?.toString() ?? '') ?? 0.0;
            final String ratingStr = (widget.selectedMapTab != 2 && isFilterActive && ratingVal > 0.0) ? ratingVal.toStringAsFixed(1) : 'none';
            imagesToRegister.add("selected-$resolvedType-$ratingStr");
          }
        }
      }

      // 3. Register style images on demand
      for (final imageId in imagesToRegister) {
        if (!_registeredImageIds.contains(imageId)) {
          try {
            final parts = imageId.split('-');
            final String state = parts[0]; // normal / selected / dot / live / selected_live
            final String type = parts[1]; // restaurant / hotel / ...
            
            Uint8List pngBytes;
            if (state == 'checkin' || state == 'selected_checkin') {
              final String checkinId = state == 'checkin'
                  ? imageId.substring('checkin-'.length)
                  : imageId.substring('selected_checkin-'.length);
              final place = widget.places.firstWhere(
                (pl) => pl['id']?.toString() == checkinId,
                orElse: () => widget.selectedPlace != null && widget.selectedPlace!['id']?.toString() == checkinId
                    ? widget.selectedPlace!
                    : {},
              );
              final String? avatarUrl = place['authorAvatar'] as String? ?? place['author_avatar'] as String?;
              debugPrint("ExploreMapWidget: checkinId=$checkinId, resolved place keys=${place.keys}, resolved avatarUrl=$avatarUrl");
              final bool isSelected = state == 'selected_checkin';
              pngBytes = await MarkerGenerator.getCheckInAvatarPin(avatarUrl, isSelected: isSelected);
            } else if (state == 'dot') {
              pngBytes = await MarkerGenerator.getDotPin(type);
            } else if (state == 'live' || state == 'selected_live') {
              final bool isSelected = state == 'selected_live';
              pngBytes = await MarkerGenerator.getLivePin(type, isSelected: isSelected);
            } else {
              final String ratingStr = parts.length > 2 ? parts[2] : 'none';
              final bool isSelected = state == 'selected';
              
              if (ratingStr == 'none') {
                if (isSelected) {
                  pngBytes = await MarkerGenerator.getSelectedPin(type);
                } else {
                  pngBytes = await MarkerGenerator.getNormalPin(type);
                }
              } else {
                pngBytes = await MarkerGenerator.getCapsulePin(type, ratingStr, isSelected: isSelected);
              }
            }

            final mbxImage = await _convertPngToMbxImage(pngBytes);
            await _mapboxMap!.style.addStyleImage(
              imageId,
              dpr,
              mbxImage,
              false,
              <mapbox.ImageStretches?>[],
              <mapbox.ImageStretches?>[],
              mapbox.ImageContent(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
            );
            _registeredImageIds.add(imageId);
          } catch (e) {
            debugPrint("Error registering dynamic image $imageId: $e");
          }
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

        final bool isCheckIn = p['isCheckIn'] == true;
        String englishTitle = '';
        String arabicTitle = '';

        if (isCheckIn) {
          final String authorName = p['authorName'] as String? ?? '';
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final postUserId = p['user_id'] as String? ?? p['userId'] as String? ?? '';
          if (postUserId == currentUserId || authorName.toLowerCase() == 'you') {
            englishTitle = 'You';
            arabicTitle = 'أنت';
          } else {
            englishTitle = authorName;
            arabicTitle = authorName;
          }
        } else {
          bool containsArabicChar(String text) {
            return RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
          }

          // 1. Check if name contains both separated by / or - or |
          final separators = ['/', '-', '|'];
          bool separated = false;
          for (final sep in separators) {
            if (name.contains(sep)) {
              final parts = name.split(sep);
              if (parts.length == 2) {
                final part1 = parts[0].trim();
                final part2 = parts[1].trim();
                final hasAr1 = containsArabicChar(part1);
                final hasAr2 = containsArabicChar(part2);
                if (hasAr1 && !hasAr2) {
                  englishTitle = part2;
                  arabicTitle = part1;
                  separated = true;
                  break;
                } else if (!hasAr1 && hasAr2) {
                  englishTitle = part1;
                  arabicTitle = part2;
                  separated = true;
                  break;
                }
              }
            }
          }

          if (!separated) {
            final nameHasAr = containsArabicChar(name);
            final arNameHasAr = containsArabicChar(arName);

            if (nameHasAr && arNameHasAr) {
              // Both are Arabic
              englishTitle = '';
              arabicTitle = name;
            } else if (!nameHasAr && arNameHasAr) {
              // name is English, arName is Arabic
              englishTitle = name;
              arabicTitle = arName;
            } else if (!nameHasAr && !arNameHasAr) {
              // Both are English
              englishTitle = name;
              arabicTitle = '';
            } else {
              // name is Arabic, arName is English
              englishTitle = arName;
              arabicTitle = name;
            }
          }

          // Clean city name in parentheses from titles
          englishTitle = englishTitle.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
          arabicTitle = arabicTitle.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();

          // Fallback: If English title ends up empty but we have Arabic title, use Arabic as primary
          if (englishTitle.isEmpty && arabicTitle.isNotEmpty) {
            englishTitle = arabicTitle;
            arabicTitle = '';
          }
        }

        final String resolvedType = _resolvePlaceType(p);
        if (resolvedType == 'airport' && widget.selectedMapTab != 2) {
          continue;
        }

        final double rating = double.tryParse(p['rating']?.toString() ?? '') ?? 0.0;
        final String ratingAndType = "${rating.toStringAsFixed(2)}_$resolvedType";

        int placeTypeCode = 1; // other / default / mosque / school / library / museum / exhibition
        if (resolvedType == 'restaurant') {
          placeTypeCode = 2;
        } else if (resolvedType == 'supermarket') {
          placeTypeCode = 3;
        } else if (resolvedType == 'pharmacy') {
          placeTypeCode = 4;
        } else if (resolvedType == 'bakery') {
          placeTypeCode = 5;
        } else if (resolvedType == 'juices' || resolvedType == 'bars') {
          placeTypeCode = 6;
        } else if (resolvedType == 'coffee') {
          placeTypeCode = 7;
        } else if (resolvedType == 'hotels' || resolvedType == 'hotel') {
          placeTypeCode = 8;
        } else if (resolvedType == 'parks' || resolvedType == 'park') {
          placeTypeCode = 9;
        } else if (resolvedType == 'airport') {
          placeTypeCode = 10;
        }

        int priority = 3;
        final double ratingVal = double.tryParse(p['rating']?.toString() ?? '') ?? 0.0;
        final String ratingStr = (widget.selectedMapTab != 2 && isFilterActive && ratingVal > 0.0) ? ratingVal.toStringAsFixed(1) : 'none';

        if (p['priority'] != null) {
          priority = (p['priority'] as num).toInt();
        } else {
          final String typeLower = resolvedType.toLowerCase();
          final bool isSaved = p['isSaved'] == true;
          final bool isCheckIn = p['isCheckIn'] == true;
          final bool isCustomVenue = p['isCustomVenue'] == true;
          final bool isRegistered = p['isRegistered'] == true;
          final String pid = p['id']?.toString() ?? '';

          if (pid == selectedId ||
              isCheckIn ||
              isCustomVenue ||
              isRegistered ||
              isSaved ||
              pid.startsWith('tapped_') ||
              pid.startsWith('swarm_') ||
              typeLower.contains('airport')) {
            priority = 1;
          } else {
            final int reviewsCount = int.tryParse(p['reviewsCount']?.toString() ?? '') ?? 0;
            if (ratingVal >= 4.2 && reviewsCount >= 10) {
              priority = 2;
            }
          }
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
            "place_type": resolvedType,
            "title": englishTitle,
            "english_title": englishTitle,
            "arabic_title": arabicTitle,
            "rating_and_type": ratingAndType,
            "place_type_code": placeTypeCode,
            "is_prominent": priority <= 2,
            "priority": priority,
            "rating_str": ratingStr,
            "people_count": (p['peopleCount'] as num? ?? 0).toInt(),
            "rating_val": ratingVal,
            "is_check_in": isCheckIn,
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
      await _mapboxMap!.style.setStyleSourceProperty("places-heatmap-source", "data", geojsonStr);

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
      // 5. Set layer styling expressions

      // --- Places Layer Styles ---
      final String iconImageExpression;
      if (widget.selectedMapTab == 2) {
        iconImageExpression = jsonEncode([
          "step",
          ["zoom"],
          // Zoom < 4.0
          [
            "case",
            ["coalesce", ["get", "is_check_in"], false],
            [
              "case",
              ["==", ["get", "id"], selectedId],
              ["concat", "selected_checkin-", ["get", "id"]],
              ["concat", "checkin-", ["get", "id"]]
            ],
            ["==", ["get", "id"], selectedId],
            ["concat", "selected_live-", ["get", "place_type"]],
            ["==", ["get", "priority"], 1],
            ["concat", "live-", ["get", "place_type"]],
            ""
          ],
          4.0,
          // 4.0 <= Zoom < 6.0
          [
            "case",
            ["coalesce", ["get", "is_check_in"], false],
            [
              "case",
              ["==", ["get", "id"], selectedId],
              ["concat", "selected_checkin-", ["get", "id"]],
              ["concat", "checkin-", ["get", "id"]]
            ],
            ["==", ["get", "id"], selectedId],
            ["concat", "selected_live-", ["get", "place_type"]],
            ["<=", ["get", "priority"], 2],
            ["concat", "live-", ["get", "place_type"]],
            ""
          ],
          6.0,
          // Zoom >= 6.0
          [
            "case",
            ["coalesce", ["get", "is_check_in"], false],
            [
              "case",
              ["==", ["get", "id"], selectedId],
              ["concat", "selected_checkin-", ["get", "id"]],
              ["concat", "checkin-", ["get", "id"]]
            ],
            ["==", ["get", "id"], selectedId],
            ["concat", "selected_live-", ["get", "place_type"]],
            ["concat", "live-", ["get", "place_type"]]
          ]
        ]);
      } else {
        iconImageExpression = jsonEncode([
          "step",
          ["zoom"],
          // Zoom < 4.0: All are dots
          [
            "case",
            ["coalesce", ["get", "is_check_in"], false],
            [
              "case",
              ["==", ["get", "id"], selectedId],
              ["concat", "selected_checkin-", ["get", "id"]],
              ["concat", "checkin-", ["get", "id"]]
            ],
            ["==", ["get", "id"], selectedId],
            ["concat", "selected-", ["get", "place_type"], "-", ["get", "rating_str"]],
            ["concat", "dot-", ["get", "place_type"]]
          ],
          2.0,
          // 2.0 <= Zoom < 11.5: Priority 1 & 2 are pins, others are dots
          [
            "case",
            ["coalesce", ["get", "is_check_in"], false],
            [
              "case",
              ["==", ["get", "id"], selectedId],
              ["concat", "selected_checkin-", ["get", "id"]],
              ["concat", "checkin-", ["get", "id"]]
            ],
            ["==", ["get", "id"], selectedId],
            ["concat", "selected-", ["get", "place_type"], "-", ["get", "rating_str"]],
            ["<=", ["get", "priority"], 2],
            ["concat", "normal-", ["get", "place_type"], "-", ["get", "rating_str"]],
            ["concat", "dot-", ["get", "place_type"]]
          ],
          11.5,
          // Zoom >= 11.5: All are pins
          [
            "case",
            ["coalesce", ["get", "is_check_in"], false],
            [
              "case",
              ["==", ["get", "id"], selectedId],
              ["concat", "selected_checkin-", ["get", "id"]],
              ["concat", "checkin-", ["get", "id"]]
            ],
            ["==", ["get", "id"], selectedId],
            ["concat", "selected-", ["get", "place_type"], "-", ["get", "rating_str"]],
            ["concat", "normal-", ["get", "place_type"], "-", ["get", "rating_str"]]
          ]
        ]);
      }
      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "icon-image", iconImageExpression);
      } catch (e) {
        debugPrint("Error setting places-layer icon-image: $e");
      }

      final String textFieldExpression;
      if (widget.selectedMapTab == 2) {
        textFieldExpression = jsonEncode([
          "step",
          ["zoom"],
          // Zoom < 4.0: Only show label if selected or priority == 1
          [
            "case",
            ["any", ["==", ["get", "id"], selectedId], ["==", ["get", "priority"], 1]],
            [
              "format",
              ["get", "english_title"],
              {"font-scale": 1.0},
              "\n",
              {},
              [
                "case",
                ["==", ["get", "people_count"], 1],
                "1 person here",
                ["concat", ["to-string", ["get", "people_count"]], " people here"]
              ],
              {"font-scale": 0.8}
            ],
            ""
          ],
          4.0,
          // 4.0 <= Zoom < 6.0: Show if selected or priority <= 2
          [
            "case",
            ["any", ["==", ["get", "id"], selectedId], ["<=", ["get", "priority"], 2]],
            [
              "format",
              ["get", "english_title"],
              {"font-scale": 1.0},
              "\n",
              {},
              [
                "case",
                ["==", ["get", "people_count"], 1],
                "1 person here",
                ["concat", ["to-string", ["get", "people_count"]], " people here"]
              ],
              {"font-scale": 0.8}
            ],
            ""
          ],
          6.0,
          // Zoom >= 6.0: Show all
          [
            "format",
            ["get", "english_title"],
            {"font-scale": 1.0},
            "\n",
            {},
            [
              "case",
              ["==", ["get", "people_count"], 1],
              "1 person here",
              ["concat", ["to-string", ["get", "people_count"]], " people here"]
            ],
            {"font-scale": 0.8}
          ]
        ]);
      } else {
        textFieldExpression = jsonEncode([
          "step",
          ["zoom"],
          // Zoom < 4.0: No labels (except selected)
          [
            "case",
            ["==", ["get", "id"], selectedId],
            [
              "case",
              ["==", ["get", "arabic_title"], ""],
              ["get", "english_title"],
              [
                "format",
                ["get", "english_title"],
                {"font-scale": 1.0},
                "\n",
                {},
                ["get", "arabic_title"],
                {
                  "font-scale": 0.75,
                  "text-font": ["literal", ["Cairo Light", "Cairo Regular", "Arial Unicode MS Bold"]]
                }
              ]
            ],
            ""
          ],
          2.0,
          // 2.0 <= Zoom < 11.5: Priority 1 & 2 show labels, others don't
          [
            "case",
            ["==", ["get", "id"], selectedId],
            [
              "case",
              ["==", ["get", "arabic_title"], ""],
              ["get", "english_title"],
              [
                "format",
                ["get", "english_title"],
                {"font-scale": 1.0},
                "\n",
                {},
                ["get", "arabic_title"],
                {
                  "font-scale": 0.75,
                  "text-font": ["literal", ["Cairo Light", "Cairo Regular", "Arial Unicode MS Bold"]]
                }
              ]
            ],
            ["<=", ["get", "priority"], 2],
            [
              "case",
              ["==", ["get", "arabic_title"], ""],
              ["get", "english_title"],
              [
                "format",
                ["get", "english_title"],
                {"font-scale": 1.0},
                "\n",
                {},
                ["get", "arabic_title"],
                {
                  "font-scale": 0.75,
                  "text-font": ["literal", ["Cairo Light", "Cairo Regular", "Arial Unicode MS Bold"]]
                }
              ]
            ],
            ""
          ],
          11.5,
          // Zoom >= 11.5: All show labels
          [
            "case",
            ["==", ["get", "arabic_title"], ""],
            ["get", "english_title"],
            [
              "format",
              ["get", "english_title"],
              {"font-scale": 1.0},
              "\n",
              {},
              ["get", "arabic_title"],
              {
                "font-scale": 0.75,
                "text-font": ["literal", ["Cairo Light", "Cairo Regular", "Arial Unicode MS Bold"]]
              }
            ]
          ]
        ]);
      }

      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-field", textFieldExpression);
      } catch (e) {
        debugPrint("Error setting places-layer text-field: $e");
      }

      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-justify", "left");
      } catch (e) {
        debugPrint("Error setting places-layer text-justify: $e");
      }

      try {
        final String textColorExpression = widget.selectedMapTab == 2 ? jsonEncode(["rgb", 124, 87, 252]) : jsonEncode(colorMatchExpr);
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-color", textColorExpression);
      } catch (e) {
        debugPrint("Error setting places-layer text-color: $e");
      }

      try {
        final String heatmapVisibility = widget.selectedMapTab == 2 ? "visible" : "none";
        await _mapboxMap!.style.setStyleLayerProperty("places-heatmap-layer", "visibility", heatmapVisibility);
      } catch (e) {
        debugPrint("Error setting places-heatmap-layer visibility: $e");
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
        ["!=", ["get", "rating_str"], "none"],
        [
          "case",
          ["==", ["get", "id"], selectedId],
          4.1,
          3.4
        ],
        [
          "case",
          ["==", ["get", "id"], selectedId],
          1.8,
          1.4
        ]
      ]);
      try {
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "text-radial-offset", textRadialOffsetExpr);
      } catch (e) {
        debugPrint("Error setting places-layer text-radial-offset: $e");
      }

      try {
        final String sortKeyExpr = jsonEncode([
          "case",
          ["==", ["get", "id"], selectedId],
          0,
          ["get", "priority"]
        ]);
        await _mapboxMap!.style.setStyleLayerProperty("places-layer", "symbol-sort-key", sortKeyExpr);
      } catch (e) {
        debugPrint("Error setting places-layer symbol-sort-key: $e");
      }

      // --- Clusters Layer Styles ---
      final String clusterDotsIconImageExpression = jsonEncode([
        "case",
        ["==", ["get", "dominant_type_code"], 2],
        "dot-restaurant",
        ["==", ["get", "dominant_type_code"], 3],
        "dot-supermarket",
        ["==", ["get", "dominant_type_code"], 4],
        "dot-pharmacy",
        ["==", ["get", "dominant_type_code"], 5],
        "dot-bakery",
        ["==", ["get", "dominant_type_code"], 6],
        "dot-bars",
        ["==", ["get", "dominant_type_code"], 7],
        "dot-coffee",
        ["==", ["get", "dominant_type_code"], 8],
        "dot-hotel",
        ["==", ["get", "dominant_type_code"], 9],
        "dot-park",
        ["==", ["get", "dominant_type_code"], 10],
        "dot-airport",
        "dot-other"
      ]);

      final String clusterPinsIconImageExpression = jsonEncode([
        "case",
        ["==", ["%", ["get", "cluster_id"], 5], 0],
        [
          "case",
          ["==", ["get", "dominant_type_code"], 2],
          "normal-restaurant",
          ["==", ["get", "dominant_type_code"], 3],
          "normal-supermarket",
          ["==", ["get", "dominant_type_code"], 4],
          "normal-pharmacy",
          ["==", ["get", "dominant_type_code"], 5],
          "normal-bakery",
          ["==", ["get", "dominant_type_code"], 6],
          "normal-bars",
          ["==", ["get", "dominant_type_code"], 7],
          "normal-coffee",
          ["==", ["get", "dominant_type_code"], 8],
          "normal-hotel",
          ["==", ["get", "dominant_type_code"], 9],
          "normal-park",
          ["==", ["get", "dominant_type_code"], 10],
          "normal-airport",
          "normal-other"
        ],
        [
          "case",
          ["==", ["get", "dominant_type_code"], 2],
          "dot-restaurant",
          ["==", ["get", "dominant_type_code"], 3],
          "dot-supermarket",
          ["==", ["get", "dominant_type_code"], 4],
          "dot-pharmacy",
          ["==", ["get", "dominant_type_code"], 5],
          "dot-bakery",
          ["==", ["get", "dominant_type_code"], 6],
          "dot-bars",
          ["==", ["get", "dominant_type_code"], 7],
          "dot-coffee",
          ["==", ["get", "dominant_type_code"], 8],
          "dot-hotel",
          ["==", ["get", "dominant_type_code"], 9],
          "dot-park",
          ["==", ["get", "dominant_type_code"], 10],
          "dot-airport",
          "dot-other"
        ]
      ]);

      final String clusterIconSizeExpression = jsonEncode([
        "interpolate",
        ["linear"],
        ["zoom"],
        1.5,
        [
          "step",
          ["get", "point_count"],
          0.38,
          10,
          0.48,
          100,
          0.58
        ],
        5.0,
        [
          "step",
          ["get", "point_count"],
          0.65,
          10,
          0.8,
          100,
          0.95
        ]
      ]);

      final String clusterTextColorExpression = jsonEncode([
        "case",
        ["==", ["get", "dominant_type_code"], 2],
        "#FF5A19",
        ["==", ["get", "dominant_type_code"], 3],
        "#5A5D67",
        ["==", ["get", "dominant_type_code"], 4],
        "#5A5D67",
        ["==", ["get", "dominant_type_code"], 5],
        "#FF5A19",
        ["==", ["get", "dominant_type_code"], 6],
        "#FF5A19",
        ["==", ["get", "dominant_type_code"], 7],
        "#FF5A19",
        ["==", ["get", "dominant_type_code"], 8],
        "#0066FF",
        ["==", ["get", "dominant_type_code"], 9],
        "#1B8A5A",
        ["==", ["get", "dominant_type_code"], 10],
        "#0066FF",
        "#5A5D67"
      ]);

      // Style clusters-dots-layer (dots under zoom 13.0, no text)
      try {
        await _mapboxMap!.style.setStyleLayerProperty("clusters-dots-layer", "icon-image", clusterDotsIconImageExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-dots-layer", "icon-size", clusterIconSizeExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-dots-layer", "text-field", "");
        await _mapboxMap!.style.setStyleLayerProperty("clusters-dots-layer", "text-size", 0.0);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-dots-layer", "text-opacity", 0.0);
        try {
          await _mapboxMap!.style.setStyleLayerProperty("clusters-dots-layer", "maxzoom", 6.0);
        } catch (_) {}
      } catch (e) {
        debugPrint("Error styling clusters-dots-layer: $e");
      }

      final String cluster100PinsIconImageExpression = jsonEncode([
        "case",
        ["==", ["get", "dominant_type_code"], 2],
        "normal-restaurant",
        ["==", ["get", "dominant_type_code"], 3],
        "normal-supermarket",
        ["==", ["get", "dominant_type_code"], 4],
        "normal-pharmacy",
        ["==", ["get", "dominant_type_code"], 5],
        "normal-bakery",
        ["==", ["get", "dominant_type_code"], 6],
        "normal-bars",
        ["==", ["get", "dominant_type_code"], 7],
        "normal-coffee",
        ["==", ["get", "dominant_type_code"], 8],
        "normal-hotel",
        ["==", ["get", "dominant_type_code"], 9],
        "normal-park",
        ["==", ["get", "dominant_type_code"], 10],
        "normal-airport",
        "normal-other"
      ]);

      // Style clusters-medium-layer (pins and dots mix starting from zoom 13.0 to 15.0)
      try {
        final String clusterMediumTextFieldExpression = jsonEncode([
          "case",
          ["==", ["%", ["get", "cluster_id"], 5], 0],
          ["get", "title"],
          ""
        ]);

        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "icon-image", clusterPinsIconImageExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "icon-size", clusterIconSizeExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "text-field", clusterMediumTextFieldExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "text-size", textSizeExpr);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "text-opacity", 1.0);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "text-color", clusterTextColorExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "text-radial-offset", textRadialOffsetExpr);
        try {
          await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "minzoom", 6.0);
          await _mapboxMap!.style.setStyleLayerProperty("clusters-medium-layer", "maxzoom", 9.0);
        } catch (_) {}
      } catch (e) {
        debugPrint("Error styling clusters-medium-layer: $e");
      }

      // Style clusters-pins-layer (100% pins starting from zoom 15.0)
      try {
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "icon-image", cluster100PinsIconImageExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "icon-size", clusterIconSizeExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "text-field", textFieldExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "text-size", textSizeExpr);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "text-opacity", 1.0);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "text-color", clusterTextColorExpression);
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "text-justify", "left");
        await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "text-radial-offset", textRadialOffsetExpr);
        try {
          await _mapboxMap!.style.setStyleLayerProperty("clusters-pins-layer", "minzoom", 9.0);
        } catch (_) {}
      } catch (e) {
        debugPrint("Error styling clusters-pins-layer: $e");
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
      defaultValue: Secrets.mapboxAccessToken,
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
                layerIds: [
                  "places-layer",
                  "clusters-dots-layer",
                  "clusters-medium-layer",
                  "clusters-pins-layer"
                ],
                filter: null,
              ),
            );

            debugPrint("ExploreMapWidget Tap: Queried ${features.length} features.");
            if (features.isNotEmpty && features.first != null) {
              final feature = features.first!;
              final properties = feature.feature['properties'] as Map?;
              debugPrint("ExploreMapWidget Tap: Properties = $properties");
              if (properties != null) {
                final bool isCluster = properties.containsKey('point_count') || properties.containsKey('cluster_id');
                if (isCluster) {
                  final geometry = feature.feature['geometry'] as Map?;
                  final coordinates = geometry?['coordinates'] as List?;
                  if (coordinates != null && coordinates.length >= 2) {
                    final double lng = (coordinates[0] as num).toDouble();
                    final double lat = (coordinates[1] as num).toDouble();
                    final double targetZoom = _currentZoom + 1.5;
                    debugPrint("ExploreMapWidget Tap: Cluster clicked, zooming into: ($lat, $lng) at zoom $targetZoom");
                    _mapboxMap?.easeTo(
                      mapbox.CameraOptions(
                        center: mapbox.Point(coordinates: mapbox.Position(lng, lat)).toJson(),
                        zoom: targetZoom,
                      ),
                      mapbox.MapAnimationOptions(duration: 500),
                    );
                    return;
                  }
                }

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
