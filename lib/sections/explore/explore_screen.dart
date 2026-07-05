import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../home/widgets/check_in_composer_screen.dart';
import 'place_details_screen.dart';
import 'services/explore_data_service.dart';
import 'helpers/marker_generator.dart';
import 'helpers/bookmark_tracker.dart';
import 'widgets/explore_place_card.dart';
import 'widgets/explore_search_bar.dart';
import 'widgets/explore_category_filters.dart';
import 'widgets/explore_filter_sheet.dart';
import 'widgets/explore_list_view.dart';
import 'widgets/explore_map_tabs.dart';
import 'widgets/explore_view_toggle_pill.dart';
import 'explore_search_screen.dart';
import 'models/explore_state.dart';
import 'view_models/explore_view_model.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  final VoidCallback onBackToTimeline;
  final VoidCallback? onAvatarTapped;
  final String? userAvatarUrl;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const ExploreScreen({
    super.key,
    required this.onBackToTimeline,
    this.onAvatarTapped,
    this.userAvatarUrl,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  static const String _mapStyleJson = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  }
]
''';

  GoogleMapController? _mapController;
  int _lastRoundedZoom = 13;
  double _currentZoom = 13.0;
  double _lastIdleZoom = 13.0;
  final TextEditingController _searchController = TextEditingController();
  final MarkerGenerator _markerGenerator = MarkerGenerator();

  // Status Badge Overlay State
  bool _showStatusBadge = false;
  String _statusMessage = "";
  Timer? _statusBadgeTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exploreViewModelProvider.notifier).init();
    });
    _markerGenerator.initMarkerIcons(
      zoom: 13.0,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _statusBadgeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLatitude != oldWidget.initialLatitude ||
        widget.initialLongitude != oldWidget.initialLongitude) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        _moveToInitialLocation(
          widget.initialLatitude!,
          widget.initialLongitude!,
          widget.initialAddress,
        );
      }
    }
  }

  void _moveToInitialLocation(double lat, double lng, String? address) {
    final latLng = LatLng(lat, lng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
    _onMapTappedWithFallbackAddress(latLng, ref.read(exploreViewModelProvider), address);
  }

  Future<void> _onMapTappedWithFallbackAddress(LatLng latLng, ExploreState state, String? address) async {
    FocusScope.of(context).unfocus();
    ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);

    final double userLat = state.userLocation?.latitude ?? latLng.latitude;
    final double userLng = state.userLocation?.longitude ?? latLng.longitude;

    try {
      final place = await ExploreDataService.fetchPlaceDetails(
        '',
        '',
        latLng.latitude,
        latLng.longitude,
        userLat,
        userLng,
      );
      if (place != null && place['id'].toString().isNotEmpty && !place['id'].toString().startsWith('tapped_') && mounted) {
        ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(place);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
        _markerGenerator.preloadNetworkIconsForPlaces([place], () {
          if (mounted) setState(() {});
        });
        _markerGenerator.preloadPlaceMarkers([place], () {
          if (mounted) setState(() {});
        });
        return;
      }
    } catch (e) {
      debugPrint("Error detecting POI on Foursquare search: $e");
    }

    final double meters = Geolocator.distanceBetween(userLat, userLng, latLng.latitude, latLng.longitude);
    final double km = meters / 1000;
    final String distanceStr = km < 1 
        ? '${meters.toStringAsFixed(0)} m' 
        : '${km.toStringAsFixed(1)} km';

    final String fallbackId = 'tapped_${latLng.latitude}_${latLng.longitude}';
    final fallbackPlace = {
      'id': fallbackId,
      'name': address ?? 'Dropped Pin',
      'arabicName': address ?? 'دبوس مثبت',
      'address': address ?? '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}',
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'distance': distanceStr,
      'rating': 4.5,
      'reviewsCount': 0,
      'price': r'$$',
      'peopleCount': 0,
      'type': 'Other',
      'imageUrl': ExploreDataService.getPlaceholderUrl('Other', fallbackId),
      'isSaved': false,
      'isVisited': false,
      'actionType': 'check-in',
      'isRegistered': false,
    };

    if (mounted) {
      ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(fallbackPlace);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }

  void _triggerStatusBadge(String message) {
    _statusBadgeTimer?.cancel();
    setState(() {
      _statusMessage = message;
      _showStatusBadge = true;
    });
    _statusBadgeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showStatusBadge = false;
        });
      }
    });
  }

  void _animateToUserLocation(LatLng? location) {
    if (location != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15.0),
        ),
      );
    }
  }

  void _openFilterBottomSheet(ExploreState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ExploreFilterSheet(
          initialState: state.filterState,
          onApply: (newState) {
            ref.read(exploreViewModelProvider.notifier).updateFilterState(newState);
          },
        );
      },
    );
  }

  void _openSearchScreen(ExploreState state) async {
    final lat = state.userLocation?.latitude ?? 24.7136;
    final lng = state.userLocation?.longitude ?? 46.6753;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSearchScreen(
          userLat: lat,
          userLng: lng,
          recentPlaces: state.recentPlaces,
          onRecentPlaceAdded: (place) {
            ref.read(exploreViewModelProvider.notifier).addRecentPlace(place);
          },
          filterState: {
            'visited': state.filterState.visited,
            'saved': state.filterState.saved,
            'priceLevel': state.filterState.priceRange ?? 'Any',
            'ratingMin': state.filterState.minRating ?? 0.0,
            'openNow': state.filterState.openNow,
          },
          onFilterStateChanged: (updatedFilters) {
            final updatedState = state.filterState.copyWith(
              visited: updatedFilters['visited'] as bool?,
              saved: updatedFilters['saved'] as bool?,
              openNow: updatedFilters['openNow'] as bool?,
              minRating: () => updatedFilters['ratingMin'] as double?,
              priceRange: () => updatedFilters['priceLevel'] == 'Any' ? null : updatedFilters['priceLevel'] as String?,
            );
            ref.read(exploreViewModelProvider.notifier).updateFilterState(updatedState);
          },
        ),
      ),
    );

    if (result != null && mounted) {
      if (result['type'] == 'place') {
        final place = result['place'] as Map<String, dynamic>;
        final updatedPlace = Map<String, dynamic>.from(place);
        updatedPlace['isSaved'] = BookmarkTracker().isBookmarked(place['id'].toString());
        
        final list = List<Map<String, dynamic>>.from(state.allPlaces);
        final idx = list.indexWhere((p) => p['id'].toString() == updatedPlace['id'].toString());
        if (idx == -1) {
          list.add(updatedPlace);
        } else {
          list[idx] = updatedPlace;
        }
        ref.read(exploreViewModelProvider.notifier).updateAllPlacesManual(list);
        ref.read(exploreViewModelProvider.notifier).updateSearchQuery("");
        _searchController.text = updatedPlace['name']?.toString() ?? '';
        
        ref.read(exploreViewModelProvider.notifier).selectPlaceAndLoadDetails(updatedPlace);
        _markerGenerator.preloadNetworkIconsForPlaces([place], () {
          if (mounted) setState(() {});
        });
        _markerGenerator.preloadPlaceMarkers([place], () {
          if (mounted) setState(() {});
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng((place['latitude'] as num? ?? 0.0).toDouble(), (place['longitude'] as num? ?? 0.0).toDouble()),
            15.0,
          ),
        );
      } else if (result['type'] == 'current_location') {
        if (state.userLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(state.userLocation!.latitude, state.userLocation!.longitude),
              15.0,
            ),
          );
        }
      } else if (result['type'] == 'category') {
        final category = result['category'] as String;
        final bool isSelected = state.selectedCategory == category;
        ref.read(exploreViewModelProvider.notifier).updateCategory(isSelected ? "" : category);
        ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng, category: isSelected ? "" : category);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredPlaces(ExploreState state) {
    return state.allPlaces.where((place) {
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final nameMatches = (place['name'] as String? ?? '').toLowerCase().contains(query);
        final arMatches = (place['arabicName'] as String? ?? '').toLowerCase().contains(query);
        if (!nameMatches && !arMatches) return false;
      }

      if (state.selectedMapTab == 3) {
        final filterVisited = state.filterState.visited;
        final filterSaved = state.filterState.saved;
        if (filterVisited && !(place['isVisited'] as bool? ?? false)) return false;
        if (filterSaved && !(place['isSaved'] as bool? ?? false)) return false;
        if (!filterVisited && !filterSaved) {
          return (place['isVisited'] as bool? ?? false) || (place['isSaved'] as bool? ?? false);
        }
        return true;
      }

      if (state.selectedMapTab == 0 && state.selectedCategory.isNotEmpty) {
        final type = place['type'] as String? ?? 'Other';
        if (state.selectedCategory == "Restaurant" && type != "Restaurant") return false;
        if (state.selectedCategory == "Coffee" && type != "Coffee") return false;
        if (state.selectedCategory == "Bakery" && type != "Bakery") return false;
        if (state.selectedCategory == "Bars" && type != "Bars") return false;
      }

      if (state.selectedMapTab == 1) {
        return place['actionType'] == 'Book';
      }

      if (state.selectedMapTab == 2) {
        final peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
        if (peopleCount <= 0) return false;
      }
      
      if (state.filterState.maxDistance != null) {
        final double? dist = _parseDistance(place['distance'] as String?);
        if (dist == null || dist > state.filterState.maxDistance!) {
          return false;
        }
      }

      if (state.filterState.openNow) {
        final openNow = place['openNow'] as bool? ?? true;
        if (!openNow) return false;
      }

      if (state.filterState.minRating != null) {
        final rating = (place['rating'] as num? ?? 0.0).toDouble();
        if (rating < state.filterState.minRating!) return false;
      }

      if (state.filterState.priceRange != null) {
        final price = place['price'] as String? ?? r'$$';
        if (price != state.filterState.priceRange) return false;
      }

      if (state.filterState.visited && !(place['isVisited'] as bool? ?? false)) return false;
      if (state.filterState.saved && !(place['isSaved'] as bool? ?? false)) return false;
      if (state.filterState.newToMe && (place['isVisited'] as bool? ?? false)) return false;
      if (state.filterState.onList && !(place['isSaved'] as bool? ?? false)) return false;

      return true;
    }).toList();
  }

  double? _parseDistance(String? distanceStr) {
    if (distanceStr == null) return null;
    final str = distanceStr.toLowerCase().trim();
    if (str.contains('m') && !str.contains('k')) {
      final numVal = double.tryParse(str.replaceAll('m', '').trim());
      if (numVal != null) return numVal / 1000.0;
    } else if (str.contains('km')) {
      return double.tryParse(str.replaceAll('km', '').trim());
    }
    return null;
  }

  bool _isProminentPlace(Map<String, dynamic> place) {
    if (place['isCheckIn'] == true) return true;
    final String id = place['id']?.toString() ?? '';
    if (id.startsWith('tapped_') || id.startsWith('swarm_')) return true;
    if (place['isCustomVenue'] == true || place['isRegistered'] == true) return true;

    final String type = place['type'] as String? ?? '';
    final String typeLower = type.toLowerCase();
    if (typeLower.contains('airport') ||
        typeLower.contains('hotel') ||
        typeLower.contains('park') ||
        typeLower.contains('ticket')) {
      return true;
    }

    final String name = (place['name'] as String? ?? '').toLowerCase();
    final String address = (place['address'] as String? ?? '').toLowerCase();
    if (name.contains('tower') || name.contains('mall') || name.contains('center') || name.contains('plaza') ||
        name.contains('برج') || name.contains('مول') || name.contains('مركز') || name.contains('بلازا') || name.contains('ساحة')) {
      return true;
    }
    if (address.contains('highway') || address.contains('road') || address.contains('main') ||
        address.contains('طريق') || address.contains('رئيسي') || address.contains('سريع')) {
      return true;
    }

    if (address.contains('alley') || address.contains('lane') || address.contains('side') ||
        address.contains('زقاق') || address.contains('حارة') || address.contains('فرعي')) {
      return false;
    }

    final double rating = (place['rating'] as num? ?? 0.0).toDouble();
    final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
    if (rating >= 4.4 && reviewsCount >= 10) {
      return true;
    }

    return false;
  }

  Set<Marker> _buildMarkers(ExploreState state, List<Map<String, dynamic>> filtered) {
    final Set<Marker> markers = {};
    final List<Map<String, dynamic>> placesToDraw = List.from(filtered);

    if (state.selectedPlace != null) {
      final selectedId = state.selectedPlace!['id'];
      if (!placesToDraw.any((p) => p['id'] == selectedId)) {
        placesToDraw.add(state.selectedPlace!);
      }
    }

    final bool useHeatmapStyle = state.selectedMapTab == 2;
    final normalCustomCache = useHeatmapStyle ? _markerGenerator.customPlaceMarkersNormalHeatmap : _markerGenerator.customPlaceMarkersNormal;
    final selectedCustomCache = useHeatmapStyle ? _markerGenerator.customPlaceMarkersSelectedHeatmap : _markerGenerator.customPlaceMarkersSelected;

    for (final place in placesToDraw) {
      final isSelected = state.selectedPlace != null && state.selectedPlace!['id'] == place['id'];
      final type = place['type'] as String? ?? 'Other';
      final iconUrl = place['iconUrl'] as String?;
      final isCheckIn = place['isCheckIn'] as bool? ?? false;
      final authorAvatar = place['authorAvatar'] as String?;
      
      BitmapDescriptor icon;
      final bool isManualTapped = place['id'].toString().startsWith('tapped_');
      double anchorX = 0.5;
      double anchorY = 1.0;

      final bool isProminent = _isProminentPlace(place);
      final bool showAsPin = useHeatmapStyle ? true : (isSelected || isProminent || _currentZoom >= 15.0);

      if (isManualTapped) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      } else if (isCheckIn && authorAvatar != null && _markerGenerator.avatarMarkerCache.containsKey(authorAvatar)) {
        icon = _markerGenerator.avatarMarkerCache[authorAvatar]!;
      } else if (showAsPin) {
        final bool showCustomLabel = (isSelected || _currentZoom >= 15.0 || useHeatmapStyle) && normalCustomCache.containsKey(place['id'].toString());
        
        if (showCustomLabel) {
          if (isSelected && selectedCustomCache.containsKey(place['id'].toString())) {
            icon = selectedCustomCache[place['id'].toString()]!;
          } else {
            icon = normalCustomCache[place['id'].toString()]!;
          }
          
          if (useHeatmapStyle) {
            final double finalScale = isSelected ? 1.1 : 0.9;
            final double radius = 16.0 * finalScale;
            final double glowRadius = radius + 4.0;
            final double cy = glowRadius + 4.0;
            final double textTop = cy + glowRadius + 6.0;
            final double canvasHeight = textTop + 15.0 + 4.0 + 13.0 + 8.0;
            
            anchorX = 0.5;
            anchorY = cy / canvasHeight;
          } else {
            final double finalScale = isSelected ? 1.1 : 0.9;
            final double pinWidth = 27.75 * finalScale;
            final double textWidth = 120.0;
            final double spacing = 8.0;
            final double canvasWidth = textWidth + spacing + pinWidth + 8.0;
            
            final double pinDx = textWidth + spacing + 4.0;
            final double pinDy = 4.0;
            final double pinHeight = 30.833 * finalScale;
            final double canvasHeight = pinHeight + 16.0;

            anchorX = (pinDx + 13.875 * finalScale) / canvasWidth;
            anchorY = (pinDy + 30.833 * finalScale) / canvasHeight;
          }
        } else {
          if (state.selectedMapTab == 2) {
            if (_markerGenerator.heatmapCircleIcons.containsKey(type)) {
              icon = _markerGenerator.heatmapCircleIcons[type]!;
            } else {
              icon = _markerGenerator.heatmapCircleIcons['default'] ??
                  _markerGenerator.heatmapMarkerIcons[type] ??
                  _markerGenerator.heatmapMarkerIcons['default'] ??
                  BitmapDescriptor.defaultMarker;
            }
            anchorX = 0.5;
            anchorY = 0.5;
          } else if (isSelected) {
            icon = _markerGenerator.selectedMarkerIcons[type] ?? _markerGenerator.selectedMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
          } else {
            icon = _markerGenerator.normalMarkerIcons[type] ?? _markerGenerator.normalMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
          }
        }
      } else if (iconUrl != null &&
          (isSelected ? _markerGenerator.networkIconsSelectedCache : _markerGenerator.networkIconsNormalCache).containsKey(iconUrl)) {
        icon = (isSelected ? _markerGenerator.networkIconsSelectedCache : _markerGenerator.networkIconsNormalCache)[iconUrl]!;
      } else if (_markerGenerator.iconsLoaded) {
        if (state.selectedMapTab == 2) {
          icon = _markerGenerator.heatmapDotIcons[type] ?? _markerGenerator.heatmapDotIcons['default'] ?? BitmapDescriptor.defaultMarker;
        } else {
          icon = _markerGenerator.dotMarkerIcons[type] ?? _markerGenerator.dotMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
        }
        anchorX = 0.5;
        anchorY = 0.5;
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      }

      markers.add(
        Marker(
          markerId: MarkerId(place['id']?.toString() ?? UniqueKey().toString()),
          position: LatLng((place['latitude'] as num? ?? 0.0).toDouble(), (place['longitude'] as num? ?? 0.0).toDouble()),
          icon: icon,
          anchor: Offset(anchorX, anchorY),
          onTap: () {
            ref.read(exploreViewModelProvider.notifier).selectPlaceAndLoadDetails(place);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng((place['latitude'] as num? ?? 0.0).toDouble(), (place['longitude'] as num? ?? 0.0).toDouble()),
              ),
            );
          },
        ),
      );
    }
    return markers;
  }

  Set<Circle> _buildHeatmapCircles(ExploreState state, List<Map<String, dynamic>> filtered) {
    if (state.selectedMapTab != 2) return {};

    final Set<Circle> circles = {};

    for (final place in filtered) {
      final double lat = (place['latitude'] as num? ?? 0.0).toDouble();
      final double lng = (place['longitude'] as num? ?? 0.0).toDouble();
      final int peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
      if (peopleCount <= 0) continue;

      final String placeId = place['id']?.toString() ?? UniqueKey().toString();
      final double baseRadius = 80.0 + (peopleCount * 40.0).clamp(0.0, 400.0);

      circles.add(Circle(
        circleId: CircleId('${placeId}_heat_outer'),
        center: LatLng(lat, lng),
        radius: baseRadius * 1.5,
        fillColor: const Color(0xFF7C57FC).withValues(alpha: 0.05),
        strokeWidth: 0,
      ));

      circles.add(Circle(
        circleId: CircleId('${placeId}_heat_mid'),
        center: LatLng(lat, lng),
        radius: baseRadius * 1.0,
        fillColor: const Color(0xFF7C57FC).withValues(alpha: 0.10),
        strokeWidth: 0,
      ));

      circles.add(Circle(
        circleId: CircleId('${placeId}_heat_core'),
        center: LatLng(lat, lng),
        radius: baseRadius * 0.5,
        fillColor: const Color(0xFF7C57FC).withValues(alpha: 0.20),
        strokeWidth: 0,
      ));
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreViewModelProvider);
    
    ref.listen<LatLng?>(
      exploreViewModelProvider.select((s) => s.userLocation),
      (previous, next) {
        if (previous == null && next != null) {
          _animateToUserLocation(next);
        }
      },
    );

    final filteredPlaces = _getFilteredPlaces(state);

    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final double navBarHeight = 70 + (bottomPadding > 0 ? bottomPadding + 6 : 16);
    final double controlsBottom = navBarHeight + 24;
    final double overlaysBottom = controlsBottom + 56 + 12;

    final bool showCategoryResultsMode = state.selectedCategory.isNotEmpty ||
        state.searchQuery.isNotEmpty ||
        _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (state.isListView) ...[
            Positioned.fill(
              child: ExploreListView(
                topPadding: topPadding,
                navBarHeight: navBarHeight,
                filteredPlaces: filteredPlaces,
                userAvatarUrl: widget.userAvatarUrl,
                onAvatarTapped: widget.onAvatarTapped,
                searchController: _searchController,
                isSearching: state.isSearching,
                searchQuery: state.searchQuery,
                onBackToTimeline: widget.onBackToTimeline,
                onFilterPressed: () => _openFilterBottomSheet(state),
                onSearchChanged: (_) {},
                onSearchSubmitted: (value) async {
                  if (value.trim().isNotEmpty) {
                    await ref.read(exploreViewModelProvider.notifier).searchPlaces(value);
                  }
                },
                onPlaceActionTriggered: _handlePlaceAction,
                onCategoryTapped: (category) {
                  final bool isSelected = state.selectedCategory == category;
                  ref.read(exploreViewModelProvider.notifier).updateCategory(isSelected ? "" : category);
                  final lat = state.userLocation?.latitude ?? 24.7136;
                  final lng = state.userLocation?.longitude ?? 46.6753;
                  ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng, category: isSelected ? "" : category);
                },
                selectedCategory: state.selectedCategory,
                onClearSearch: () {
                  ref.read(exploreViewModelProvider.notifier).updateSearchQuery("");
                  _searchController.clear();
                  ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);
                  ref.read(exploreViewModelProvider.notifier).updateListView(false);
                },
                onSearchTap: () => _openSearchScreen(state),
              ),
            ),
          ] else ...[
            Positioned.fill(
              child: GoogleMap(
                style: _mapStyleJson,
                 initialCameraPosition: CameraPosition(
                  target: (widget.initialLatitude != null && widget.initialLongitude != null)
                      ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
                      : (state.userLocation ?? const LatLng(24.7136, 46.6753)),
                  zoom: (widget.initialLatitude != null && widget.initialLongitude != null) ? 15.0 : 13.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (widget.initialLatitude != null && widget.initialLongitude != null) {
                    _moveToInitialLocation(
                      widget.initialLatitude!,
                      widget.initialLongitude!,
                      widget.initialAddress,
                    );
                  }
                },
                onCameraMove: (position) {
                  _currentZoom = position.zoom;
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationEnabled: state.userLocation != null,
                myLocationButtonEnabled: false,
                markers: _buildMarkers(state, filteredPlaces),
                circles: _buildHeatmapCircles(state, filteredPlaces),
                onTap: (latLng) {
                  ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);
                },
                onLongPress: (latLng) {
                  _onMapTapped(latLng, state);
                },
                onCameraIdle: () {
                  final double oldZoom = _lastIdleZoom;
                  _lastIdleZoom = _currentZoom;

                  final bool crossedThreshold = (oldZoom < 15.0 && _currentZoom >= 15.0) ||
                                                (oldZoom >= 15.0 && _currentZoom < 15.0);

                  final int roundedZoom = _currentZoom.round();
                  if (roundedZoom != _lastRoundedZoom || crossedThreshold) {
                    _lastRoundedZoom = roundedZoom;
                    _markerGenerator.initMarkerIcons(
                      zoom: _currentZoom,
                      onUpdate: () {
                        if (mounted) setState(() {});
                      },
                    );
                  }

                  if (_mapController != null) {
                    _mapController!.getVisibleRegion().then((bounds) {
                      final center = LatLng(
                        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                      );
                      if (state.lastFetchedLocation == null) {
                        ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(center.latitude, center.longitude);
                      } else {
                        final distance = Geolocator.distanceBetween(
                          state.lastFetchedLocation!.latitude,
                          state.lastFetchedLocation!.longitude,
                          center.latitude,
                          center.longitude,
                        );
                        if (distance > 1500) {
                          ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(center.latitude, center.longitude);
                        }
                      }
                    });
                  }
                },
              ),
            ),

            if (state.selectedPlace != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: overlaysBottom,
                child: ExplorePlaceCard(
                  place: state.selectedPlace!,
                  onSavedChanged: (val) {
                    ref.read(exploreViewModelProvider.notifier).toggleBookmark(state.selectedPlace!, val);
                  },
                  onActionTriggered: () => _handlePlaceAction(state.selectedPlace!),
                  onViewPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsScreen(
                          place: state.selectedPlace!,
                          onActionTriggered: () => _handlePlaceAction(state.selectedPlace!),
                        ),
                      ),
                    );
                  },
                  onInteractionPressed: () {
                    final authorName = state.selectedPlace!['authorName'] as String? ?? 'Anonymous';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "مرحباً بك في More! تم تسجيل التواجد بواسطة $authorName",
                          style: GoogleFonts.ibmPlexSansArabic(),
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_showStatusBadge)
              Positioned(
                left: 0,
                right: 0,
                bottom: overlaysBottom + (state.selectedPlace != null ? 140 : 0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _statusMessage,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),

            if (state.selectedMapTab != 2)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ExploreSearchBar(
                  searchController: _searchController,
                  isSearching: false,
                  searchQuery: "",
                  suggestions: const [],
                  userAvatarUrl: widget.userAvatarUrl,
                  onAvatarTapped: widget.onAvatarTapped,
                  onSearchChanged: (_) {},
                  onSearchSubmitted: (_) {},
                  onClearSearch: () {},
                  onBackToTimeline: widget.onBackToTimeline,
                  onSuggestionTapped: (_) {},
                  iconDataGetter: (type) => _markerGenerator.getIconDataForType(type),
                  topPadding: topPadding,
                  onTap: () => _openSearchScreen(state),
                ),
              ),

            if (state.selectedMapTab != 2)
              Positioned(
                top: topPadding + 80,
                left: 0,
                right: 0,
                child: ExploreCategoryFilters(
                  selectedMapTab: state.selectedMapTab,
                  selectedCategory: state.selectedCategory,
                  filterVisited: state.filterState.visited,
                  filterSaved: state.filterState.saved,
                  onCategoryTapped: (category) {
                    final bool isSelected = state.selectedCategory == category;
                    ref.read(exploreViewModelProvider.notifier).updateCategory(isSelected ? "" : category);
                    final lat = state.userLocation?.latitude ?? 24.7136;
                    final lng = state.userLocation?.longitude ?? 46.6753;
                    ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng, category: isSelected ? "" : category);
                  },
                  onFilterVisitedTapped: () {
                    final updatedState = state.filterState.copyWith(visited: !state.filterState.visited);
                    ref.read(exploreViewModelProvider.notifier).updateFilterState(updatedState);
                  },
                  onFilterSavedTapped: () {
                    final updatedState = state.filterState.copyWith(saved: !state.filterState.saved);
                    ref.read(exploreViewModelProvider.notifier).updateFilterState(updatedState);
                  },
                  topPadding: topPadding,
                ),
              ),

            if (!showCategoryResultsMode)
              Positioned(
                left: 16,
                right: 16,
                bottom: controlsBottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _animateToUserLocation(state.userLocation),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/explore/sent.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF7C57FC),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    ExploreMapTabs(
                      selectedMapTab: state.selectedMapTab,
                      onTabChanged: (index) {
                        ref.read(exploreViewModelProvider.notifier).updateMapTab(index);
                        String msg = "";
                        if (index == 0) msg = "Discover";
                        if (index == 1) msg = "Plans";
                        if (index == 2) msg = "Live Now";
                        if (index == 3) msg = "My Places";
                        _triggerStatusBadge(msg);
                      },
                    ),

                    GestureDetector(
                      onTap: () => _openCheckInComposer(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/explore/plus_sign.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          if (state.selectedPlace == null && (state.isListView || showCategoryResultsMode))
            Positioned(
              left: 0,
              right: 0,
              bottom: controlsBottom,
              child: Center(
                child: ExploreViewTogglePill(
                  isListView: state.isListView,
                  onViewChanged: (isList) {
                    ref.read(exploreViewModelProvider.notifier).updateListView(isList);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onMapTapped(LatLng latLng, ExploreState state) async {
    FocusScope.of(context).unfocus();
    ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);

    final double userLat = state.userLocation?.latitude ?? latLng.latitude;
    final double userLng = state.userLocation?.longitude ?? latLng.longitude;

    try {
      final place = await ExploreDataService.fetchPlaceDetails(
        '',
        '',
        latLng.latitude,
        latLng.longitude,
        userLat,
        userLng,
      );
      if (place != null && place['id'].toString().isNotEmpty && !place['id'].toString().startsWith('tapped_') && mounted) {
        ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(place);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
        _markerGenerator.preloadNetworkIconsForPlaces([place], () {
          if (mounted) setState(() {});
        });
        _markerGenerator.preloadPlaceMarkers([place], () {
          if (mounted) setState(() {});
        });
        return;
      }
    } catch (e) {
      debugPrint("Error detecting POI on Foursquare search: $e");
    }

    final double meters = Geolocator.distanceBetween(userLat, userLng, latLng.latitude, latLng.longitude);
    final double km = meters / 1000;
    final String distanceStr = km < 1 
        ? '${meters.toStringAsFixed(0)} m' 
        : '${km.toStringAsFixed(1)} km';

    final String fallbackId = 'tapped_${latLng.latitude}_${latLng.longitude}';
    final fallbackPlace = {
      'id': fallbackId,
      'name': 'Dropped Pin',
      'arabicName': 'دبوس مثبت',
      'address': '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}',
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'distance': distanceStr,
      'rating': 4.5,
      'reviewsCount': 0,
      'price': r'$$',
      'peopleCount': 0,
      'type': 'Other',
      'imageUrl': ExploreDataService.getPlaceholderUrl('Other', fallbackId),
      'isSaved': false,
      'isVisited': false,
      'actionType': 'check-in',
      'isRegistered': false,
    };

    debugPrint("No POI found. Dropping manual fallback pin.");

    if (mounted) {
      ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(fallbackPlace);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }

  void _handlePlaceAction(Map<String, dynamic> place) {
    final String actionType = place['actionType'] as String? ?? 'Order';
    if (actionType == 'check-in') {
      _openCheckInComposer(prefilledPlace: place);
    } else if (actionType == 'Book') {
      _showSuccessDialog(
        title: "Booking Successful",
        subtitle: "Your booking for ${place['name']} has been confirmed successfully.",
        icon: Icons.check_circle_outline,
      );
    } else if (actionType == 'Order') {
      _showSuccessDialog(
        title: "Order Placed",
        subtitle: "Your order at ${place['name']} has been submitted successfully.",
        icon: Icons.shopping_bag_outlined,
      );
    }
  }

  void _showSuccessDialog({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF7C57FC),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF82858C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C57FC),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Awesome",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCheckInComposer({Map<String, dynamic>? prefilledPlace}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(
          isFirstCheckIn: false,
          editPost: null,
          prefilledPlace: prefilledPlace,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully checked in!"),
          backgroundColor: Color(0xFF7C57FC),
        ),
      );
      widget.onBackToTimeline();
    }
  }
}
