import 'dart:typed_data';
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
  });

  @override
  State<ExploreMapWidget> createState() => _ExploreMapWidgetState();
}

class _ExploreMapWidgetState extends State<ExploreMapWidget> {
  mapbox.MapboxMap? _mapboxMap;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  final Map<String, mapbox.PointAnnotation> _placeIdToAnnotationMap = {};
  final Map<String, Map<String, dynamic>> _annotationToPlaceMap = {};
  double _currentZoom = 13.0;
  bool _justClickedAnnotation = false;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialCameraPosition.zoom;
  }

  @override
  void didUpdateWidget(ExploreMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool placesChanged = !_arePlacesEqual(widget.places, oldWidget.places);
    final bool selectedChanged = widget.selectedPlace?['id']?.toString() != oldWidget.selectedPlace?['id']?.toString();
    
    if (placesChanged || selectedChanged) {
      _updateMarkers();
    }
  }

  bool _arePlacesEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['id']?.toString() != b[i]['id']?.toString()) return false;
      if (a[i]['type']?.toString() != b[i]['type']?.toString()) return false;
    }
    return true;
  }

  Future<void> _initAnnotationManager() async {
    if (_mapboxMap == null) return;
    try {
      final manager = await _mapboxMap!.annotations.createPointAnnotationManager();
      _pointAnnotationManager = manager;
      
      await manager.setIconAllowOverlap(true);
      await manager.setTextAllowOverlap(false);
      await manager.setIconIgnorePlacement(true);
      await manager.setTextIgnorePlacement(false);
      
      // Register click listener
      manager.addOnPointAnnotationClickListener(_MarkerClickListener((annotation) {
        _justClickedAnnotation = true;
        Future.delayed(const Duration(milliseconds: 1500), () {
          _justClickedAnnotation = false;
        });
        final place = _annotationToPlaceMap[annotation.id];
        if (place != null && widget.onPlaceTap != null) {
          widget.onPlaceTap!(place);
        }
      }));
      
      debugPrint("ExploreMapWidget: Successfully initialized PointAnnotationManager.");
    } catch (e) {
      debugPrint("ExploreMapWidget: Error initializing PointAnnotationManager: $e");
    }
  }

  Future<void> _hideDefaultLayers(mapbox.MapboxMap mapboxMap) async {
    try {
      final layers = await mapboxMap.style.getStyleLayers();
      final List<String> keywordsToHide = [
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
        'place',
        'symbol',
        'monument',
        'worship',
        'cemetery',
        'park',
        'lodging',
        'hotel',
        'restaurant',
        'cafe',
        'shop',
        'food',
        'beverage'
      ];
      for (final layerInfo in layers) {
        if (layerInfo != null) {
          final String idLower = layerInfo.id.toLowerCase();
          // Skip our own annotation layers
          if (idLower.contains('mapbox-android-pointannotation') || 
              idLower.contains('pointannotation') || 
              idLower.contains('custom') && idLower.contains('annotation')) {
            continue;
          }
          
          bool shouldHide = false;
          for (final keyword in keywordsToHide) {
            if (idLower.contains(keyword)) {
              shouldHide = true;
              break;
            }
          }
          
          if (shouldHide) {
            try {
              await mapboxMap.style.setStyleLayerProperty(layerInfo.id, 'visibility', 'none');
              debugPrint("ExploreMapWidget: Dynamically hid layer: ${layerInfo.id}");
            } catch (e) {
              // Ignore layers that do not support visibility property
            }
          }
        }
      }
    } catch (e) {
      debugPrint("ExploreMapWidget: Error dynamically hiding style layers: $e");
    }
  }

  bool _shouldShowAsPin(Map<String, dynamic> place, bool isSelected, double currentZoom, int selectedMapTab) {
    if (isSelected) return true;
    
    // Check if place is saved or visited
    final bool isSaved = place['isSaved'] as bool? ?? false;
    final bool isVisited = place['isVisited'] as bool? ?? false;
    if ((isSaved || isVisited) && selectedMapTab != 2) {
      return true;
    }

    if (selectedMapTab == 0) {
      bool isProminentInDiscover = false;
      if (place['isCustomVenue'] == true || place['isRegistered'] == true) {
        isProminentInDiscover = true;
      } else {
        final double rating = (place['rating'] as num? ?? 0.0).toDouble();
        final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
        if (currentZoom >= 15.0) {
          isProminentInDiscover = rating >= 3.8 && reviewsCount >= 10;
        } else if (currentZoom >= 14.0) {
          isProminentInDiscover = rating >= 4.0 && reviewsCount >= 30;
        } else if (currentZoom >= 13.0) {
          isProminentInDiscover = rating >= 4.2 && reviewsCount >= 60;
        } else {
          isProminentInDiscover = rating >= 4.5 && reviewsCount >= 100;
        }
      }
      return isProminentInDiscover || currentZoom >= 15.5;
    }

    if (selectedMapTab == 1) {
      bool isProminentInEvents = false;
      if (place['isCustomVenue'] == true || place['isRegistered'] == true) {
        isProminentInEvents = true;
      } else {
        final double rating = (place['rating'] as num? ?? 0.0).toDouble();
        final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
        if (currentZoom >= 15.0) {
          isProminentInEvents = rating >= 3.8 && reviewsCount >= 10;
        } else if (currentZoom >= 14.0) {
          isProminentInEvents = rating >= 4.0 && reviewsCount >= 30;
        } else if (currentZoom >= 13.0) {
          isProminentInEvents = rating >= 4.2 && reviewsCount >= 60;
        } else {
          isProminentInEvents = rating >= 4.5 && reviewsCount >= 100;
        }
      }
      return isProminentInEvents || currentZoom >= 13.5;
    }

    if (selectedMapTab == 2) {
      double threshold = 15.5;
      final int peopleCount = (place['peopleCount'] as num? ?? 0).toInt();
      if (peopleCount > 0) {
        threshold -= 2.0;
      } else {
        final double rating = (place['rating'] as num? ?? 0.0).toDouble();
        final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
        if (rating >= 4.5 && reviewsCount >= 100) {
          threshold -= 1.5;
        } else if (rating >= 4.0 && reviewsCount >= 30) {
          threshold -= 0.75;
        }
      }
      final int hash = place['id'].toString().hashCode.abs();
      final double jitter = ((hash % 100) / 100.0 - 0.5) * 0.6;
      threshold += jitter;

      return currentZoom >= threshold;
    }

    return currentZoom >= 14.5;
  }

  Future<void> _updateMarkers() async {
    if (_pointAnnotationManager == null) return;

    try {
      debugPrint("ExploreMapWidget: _updateMarkers() called with ${widget.places.length} places");
      await _pointAnnotationManager!.deleteAll();
      _annotationToPlaceMap.clear();
      _placeIdToAnnotationMap.clear();

      final List<mapbox.PointAnnotationOptions> optionsList = [];
      final Map<int, Map<String, dynamic>> tempIndexToPlace = {};

      int index = 0;
      for (final place in widget.places) {
        final String id = place['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        final double? lat = double.tryParse(place['latitude']?.toString() ?? '');
        final double? lng = double.tryParse(place['longitude']?.toString() ?? '');
        if (lat == null || lng == null) continue;

        final String type = place['type']?.toString() ?? 'default';
        final bool isSelected = widget.selectedPlace != null && widget.selectedPlace!['id'].toString() == id;
        final color = MarkerGenerator.getMarkerColor(type);

        final bool showAsPin = _shouldShowAsPin(place, isSelected, _currentZoom, widget.selectedMapTab);

        Uint8List imageBytes;
        if (showAsPin) {
          if (isSelected) {
            imageBytes = await MarkerGenerator.getSelectedPin(type);
          } else {
            imageBytes = await MarkerGenerator.getNormalPin(type);
          }
        } else {
          imageBytes = await MarkerGenerator.getDotPin(type);
        }

        String? textField;
        mapbox.TextAnchor? textAnchor;
        mapbox.TextJustify? textJustify;
        List<double>? textOffset;
        double? textSize;
        int? textColor;
        int? textHaloColor;
        double? textHaloWidth;

        if (showAsPin) {
          final String name = place['name']?.toString() ?? '';
          final String arName = place['arabicName']?.toString() ?? '';
          final String mainName = arName.isNotEmpty ? arName : name;
          
          textField = mainName;
          textAnchor = mapbox.TextAnchor.LEFT;
          textOffset = isSelected ? [1.3, -3.0] : [1.3, -2.1]; // Centered vertically with the teardrop head
          textSize = isSelected ? 13.5 : 12.0;
          textColor = color.toARGB32();
          textHaloColor = 0xFFFFFFFF;
          textHaloWidth = 1.5;
          textJustify = mapbox.TextJustify.LEFT;
        }

        final double sortKey = isSelected ? 1000.0 : (double.tryParse(place['rating']?.toString() ?? '0') ?? 0.0);

        final option = mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)).toJson(),
          image: imageBytes,
          iconAnchor: showAsPin ? mapbox.IconAnchor.BOTTOM : mapbox.IconAnchor.CENTER,
          textField: textField,
          textAnchor: textAnchor,
          textOffset: textOffset,
          textSize: textSize,
          textColor: textColor,
          textHaloColor: textHaloColor,
          textHaloWidth: textHaloWidth,
          textJustify: textJustify,
          symbolSortKey: sortKey,
        );

        optionsList.add(option);
        tempIndexToPlace[index] = place;
        index++;
      }

      if (optionsList.isNotEmpty) {
        final annotations = await _pointAnnotationManager!.createMulti(optionsList);
        for (int i = 0; i < annotations.length; i++) {
          final annotation = annotations[i];
          final place = tempIndexToPlace[i];
          if (annotation != null && place != null) {
            _annotationToPlaceMap[annotation.id] = place;
            _placeIdToAnnotationMap[place['id'].toString()] = annotation;
          }
        }
      }
      debugPrint("ExploreMapWidget: Successfully added ${optionsList.length} annotations");
    } catch (e, stackTrace) {
      debugPrint("ExploreMapWidget: Error in _updateMarkers(): $e");
      debugPrint(stackTrace.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    const String mapboxAccessToken = String.fromEnvironment(
      "MAPBOX_ACCESS_TOKEN",
      defaultValue: "pk.eyJ1IjoiYmFzaWlpIiwiYSI6ImNtcmhjZ2tocDFia2YzMHF6b3NvZzE0dzEifQ.u_cHUq4ZPa-busa7KzLyew",
    );

    return mapbox.MapWidget(
      key: const ValueKey('explore_mapbox_widget_key'),
      resourceOptions: mapbox.ResourceOptions(accessToken: mapboxAccessToken),
      styleUri: "mapbox://styles/basiii/cmri3vcu7007401qr2y7l5bue",
      onStyleLoadedListener: (styleLoaded) async {
        debugPrint("ExploreMapWidget: Style fully loaded. Reinitializing annotations...");
        if (_mapboxMap != null) {
          await _hideDefaultLayers(_mapboxMap!);
          await _initAnnotationManager();
          await _updateMarkers();
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
      onMapCreated: (mapboxMap) async {
        _mapboxMap = mapboxMap;

        await _hideDefaultLayers(mapboxMap);

        // Set projection to flat map (Mercator) instead of 3D Globe
        try {
          await mapboxMap.style.setProjection("mercator");
        } catch (e) {
          debugPrint("Error setting map projection: $e");
        }

        // Restrict camera bounds to prevent excessive zoom out while showing flat map
        try {
          await mapboxMap.setBounds(mapbox.CameraBoundsOptions(minZoom: 1.5));
        } catch (e) {
          debugPrint("Error setting map bounds: $e");
        }

        await mapboxMap.logo.updateSettings(mapbox.LogoSettings(position: mapbox.OrnamentPosition.BOTTOM_LEFT));
        await mapboxMap.attribution.updateSettings(mapbox.AttributionSettings(position: mapbox.OrnamentPosition.BOTTOM_LEFT));
        await mapboxMap.compass.updateSettings(mapbox.CompassSettings(enabled: false));
        await mapboxMap.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));

        await _initAnnotationManager();
        await _updateMarkers();

        if (widget.onMapCreated != null) {
          widget.onMapCreated!(mapboxMap);
        }
      },
      onCameraChangeListener: (cameraChangedEvent) {
        if (_mapboxMap != null) {
          _mapboxMap!.getCameraState().then((state) {
            final double oldZoom = _currentZoom;
            _currentZoom = state.zoom;
            
            // Rebuild markers if crossing key zoom transition thresholds (every 0.5 step)
            final int oldStep = (oldZoom * 2).round();
            final int newStep = (_currentZoom * 2).round();
            if (oldStep != newStep) {
              _updateMarkers();
            }
            
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
      onTapListener: (point) {
        if (_mapboxMap == null) return;
        
        _mapboxMap!.coordinateForPixel(point).then((value) {
          if (_justClickedAnnotation) {
            _justClickedAnnotation = false; // Consume the flag immediately
            debugPrint("ExploreMapWidget Tap: Ignored because annotation was clicked.");
            return;
          }
          
          final geoPoint = mapbox.Point.fromJson(Map<String, dynamic>.from(value));
          final double tapLat = geoPoint.coordinates.lat.toDouble();
          final double tapLng = geoPoint.coordinates.lng.toDouble();
          
          debugPrint("ExploreMapWidget Tap: Map clicked, deselecting.");
          if (widget.onTap != null) {
            widget.onTap!(model.LatLng(tapLat, tapLng));
          }
        });
      },
      onLongTapListener: (point) {
        if (widget.onLongPress != null && _mapboxMap != null) {
          _mapboxMap!.coordinateForPixel(point).then((value) {
            final geoPoint = mapbox.Point.fromJson(Map<String, dynamic>.from(value));
            widget.onLongPress!(model.LatLng(geoPoint.coordinates.lat.toDouble(), geoPoint.coordinates.lng.toDouble()));
          });
        }
      },
    );
  }
}

class _MarkerClickListener implements mapbox.OnPointAnnotationClickListener {
  final void Function(mapbox.PointAnnotation annotation) onClick;

  _MarkerClickListener(this.onClick);

  @override
  void onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    onClick(annotation);
  }
}
