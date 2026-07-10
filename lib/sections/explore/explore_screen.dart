import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'helpers/explore_screen_helpers.dart';
import 'helpers/explore_marker_builder.dart';
import 'widgets/explore_map_widget.dart';
import 'widgets/explore_floating_controls.dart';
import 'widgets/explore_status_badge.dart';

import '../home/widgets/feed/check_in_composer_screen.dart';
import 'place_details_screen.dart';
import 'services/explore_data_service.dart';
import 'helpers/marker_generator.dart';
import 'helpers/bookmark_tracker.dart';
import 'widgets/cards/explore_place_card.dart';
import 'widgets/search/explore_search_bar.dart';
import 'widgets/search/explore_category_filters.dart';
import 'widgets/sheets/explore_filter_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/search/explore_list_view.dart';
import 'add_place_screen.dart';
import 'explore_search_screen.dart';
import '../home/view_models/timeline_view_model.dart';
import '../home/widgets/bottom_sheets/follow_friends_bottom_sheet.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final MarkerGenerator _markerGenerator = MarkerGenerator();

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
    if (widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty) {
      _markerGenerator.initUserSavedVisitedMarkers(widget.userAvatarUrl!).then((_) {
        if (mounted) setState(() {});
      });
    }
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
    if (widget.userAvatarUrl != oldWidget.userAvatarUrl && widget.userAvatarUrl != null && widget.userAvatarUrl!.isNotEmpty) {
      _markerGenerator.initUserSavedVisitedMarkers(widget.userAvatarUrl!).then((_) {
        if (mounted) setState(() {});
      });
    }
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
    _onMapTapped(latLng, ref.read(exploreViewModelProvider));
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

  Widget _buildFilterPill({
    required String label,
    required bool isActive,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1F242E) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && icon != Icons.keyboard_arrow_down) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : const Color(0xFF1A1A2E),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            if (icon == Icons.keyboard_arrow_down) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ],
          ],
        ),
      ),
    );
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

  void _openPriceMiniBottomSheet(ExploreState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? tempPrice = state.filterState.priceRange;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildPriceBtn(String label) {
              final isSelected = tempPrice == label;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setModalState(() {
                      tempPrice = isSelected ? null : label;
                    });
                  },
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4C4C4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 36),
                      Text(
                        "Price",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F3F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      buildPriceBtn("\$"),
                      buildPriceBtn("\$\$"),
                      buildPriceBtn("\$\$\$"),
                      buildPriceBtn("\$\$\$\$"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = state.filterState.copyWith(priceRange: () => tempPrice);
                        ref.read(exploreViewModelProvider.notifier).updateFilterState(updated);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C57FC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Apply",
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        tempPrice = null;
                      });
                    },
                    child: Text(
                      "Reset",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openRatingMiniBottomSheet(ExploreState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final List<double> values = [7.0, 8.0, 9.0, 9.5, 10.0];
        // Convert google-scale minRating back to 7.0 - 10.0 scale if present, or fallback
        double tempRating = state.filterState.minRating != null ? (state.filterState.minRating! * 2.0) : 7.0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4C4C4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 36),
                      Text(
                        "Rating",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F3F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Over ${tempRating.toStringAsFixed(tempRating == 9.5 ? 1 : 0)}",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF7C57FC),
                      inactiveTrackColor: const Color(0xFFF1F3F5),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF7C57FC).withValues(alpha: 0.1),
                      valueIndicatorColor: const Color(0xFF7C57FC),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: tempRating,
                      min: 7.0,
                      max: 10.0,
                      divisions: 6,
                      onChanged: (val) {
                        setModalState(() {
                          if (val >= 9.25 && val <= 9.75) {
                            tempRating = 9.5;
                          } else {
                            tempRating = val.roundToDouble();
                          }
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: values.map((val) => Text(
                        val.toStringAsFixed(val == 9.5 ? 1 : 0),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: tempRating == val ? FontWeight.bold : FontWeight.normal,
                          color: tempRating == val ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final googleScaleRating = tempRating / 2.0;
                        final updated = state.filterState.copyWith(minRating: () => googleScaleRating);
                        ref.read(exploreViewModelProvider.notifier).updateFilterState(updated);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C57FC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Apply",
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        tempRating = 7.0;
                      });
                    },
                    child: Text(
                      "Reset",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
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
      } else if (result['type'] == 'search_query') {
        final query = result['query'] as String;
        _searchController.text = query;
        ref.read(exploreViewModelProvider.notifier).updateSearchQuery(query);
        ref.read(exploreViewModelProvider.notifier).searchPlaces(query);
      } else if (result['type'] == 'add_new_place') {
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => AddPlaceScreen(
              currentLat: lat,
              currentLng: lng,
            ),
          ),
        );
        if (added == true) {
          ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng);
        }
      }
    }
  }

  void _openFollowFriendsBottomSheet() {
    final timelineState = ref.read(timelineViewModelProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FollowFriendsBottomSheet(
          followedUsernames: timelineState.followedUsernames,
          onFollowChanged: (username, isFollowed) {
            ref.read(timelineViewModelProvider.notifier).toggleFollow(username, isFollowed);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreViewModelProvider);
    debugPrint("ExploreScreen: build() called, isListView=${state.isListView}, selectedMapTab=${state.selectedMapTab}, allPlaces=${state.allPlaces.length}");
    
    ref.listen<LatLng?>(
      exploreViewModelProvider.select((s) => s.userLocation),
      (previous, next) {
        if (previous == null && next != null) {
          _animateToUserLocation(next);
        }
      },
    );

    ref.listen<List<Map<String, dynamic>>>(
      exploreViewModelProvider.select((s) => s.allPlaces),
      (previous, next) {
        if (next.isNotEmpty) {
          final activePlaces = next.where((p) => (p['peopleCount'] as num? ?? 0) > 0).toList();
          if (activePlaces.isNotEmpty) {
            _markerGenerator.preloadPlaceMarkers(activePlaces, () {
              if (mounted) setState(() {});
            });
          }
        }
      },
    );

    final filteredPlaces = ExploreScreenHelpers.getFilteredPlaces(state, _currentZoom);
    final heatmapPlaces = ExploreScreenHelpers.getFilteredPlaces(state, _currentZoom, forHeatmap: true);

    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final double navBarHeight = 70 + (bottomPadding > 0 ? bottomPadding + 6 : 16);
    final double controlsBottom = 70 + bottomPadding;
    final double overlaysBottom = state.selectedPlace != null ? controlsBottom : (controlsBottom + 56 + 12);

    final bool showCategoryResultsMode = state.selectedCategory.isNotEmpty ||
        state.searchQuery.isNotEmpty ||
        _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Offstage(
              offstage: state.isListView,
              child: ExploreMapWidget(
                key: const ValueKey('explore_map_widget_wrapper_key'),
                mapStyleJson: _mapStyleJson,
                initialCameraPosition: CameraPosition(
                  target: (widget.initialLatitude != null && widget.initialLongitude != null)
                      ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
                      : (state.userLocation ?? const LatLng(24.7136, 46.6753)),
                  zoom: (widget.initialLatitude != null && widget.initialLongitude != null) ? 15.0 : 13.0,
                ),
                markers: ExploreMarkerBuilder.buildMarkers(
                  state: state,
                  filtered: filteredPlaces,
                  currentZoom: _currentZoom,
                  markerGenerator: _markerGenerator,
                  onMarkerTap: (place, position) {
                    ref.read(exploreViewModelProvider.notifier).selectPlaceAndLoadDetails(place);
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(position),
                    );
                  },
                ),
                heatmaps: ExploreMarkerBuilder.buildHeatmaps(
                  state: state,
                  filtered: heatmapPlaces,
                  currentZoom: _currentZoom,
                ),
                myLocationEnabled: state.userLocation != null,
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
                  final double oldZoom = _currentZoom;
                  _currentZoom = position.zoom;
                  if (state.selectedMapTab == 2 || (oldZoom < 11.0 && _currentZoom >= 11.0) || (oldZoom >= 11.0 && _currentZoom < 11.0)) {
                    if (mounted) setState(() {});
                  }
                },
                onCameraIdle: () {
                  final int roundedZoom = _currentZoom.round();
                  if (roundedZoom != _lastRoundedZoom) {
                    _lastRoundedZoom = roundedZoom;
                    _markerGenerator.initMarkerIcons(
                      zoom: _currentZoom,
                      onUpdate: () { if (mounted) setState(() {}); },
                    );
                  }
                  if (_mapController != null) {
                    _mapController!.getVisibleRegion().then((bounds) {
                      final center = LatLng(
                        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                      );
                      if (state.lastFetchedLocation == null) {
                        ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(center.latitude, center.longitude, zoom: _currentZoom);
                      } else {
                        final distance = Geolocator.distanceBetween(
                          state.lastFetchedLocation!.latitude,
                          state.lastFetchedLocation!.longitude,
                          center.latitude,
                          center.longitude,
                        );
                        // Scale the fetch threshold based on zoom level
                        final double threshold = _currentZoom < 7.0
                            ? 1000000.0 // 1000 km
                            : (_currentZoom < 10.0 ? 50000.0 : (_currentZoom < 13.0 ? 15000.0 : 1500.0));
                        if (distance > threshold) {
                          ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(center.latitude, center.longitude, zoom: _currentZoom);
                        }
                      }
                    });
                  }
                  if (mounted) setState(() {});
                },
                onTap: (latLng) {
                  ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);
                },
                onLongPress: (latLng) {
                  _onMapTapped(latLng, state);
                },
              ),
            ),
          ),
          if (state.isListView)
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
                  final lat = state.userLocation?.latitude ?? 24.7136;
                  final lng = state.userLocation?.longitude ?? 46.6753;
                  ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng);
                },
                onSearchTap: () => _openSearchScreen(state),
              ),
            ),

          if (!state.isListView) ...[
            if (state.selectedMapTab != 2 && state.selectedCategory.isEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ExploreSearchBar(
                  searchController: _searchController,
                  isSearching: state.isSearching,
                  searchQuery: state.searchQuery,
                  suggestions: const [],
                  userAvatarUrl: widget.userAvatarUrl,
                  onAvatarTapped: widget.onAvatarTapped,
                  onSearchChanged: (_) {},
                  onSearchSubmitted: (_) {},
                  onClearSearch: () {
                    ref.read(exploreViewModelProvider.notifier).updateSearchQuery("");
                    _searchController.clear();
                    ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);
                    ref.read(exploreViewModelProvider.notifier).updateListView(false);
                    final lat = state.userLocation?.latitude ?? 24.7136;
                    final lng = state.userLocation?.longitude ?? 46.6753;
                    ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng);
                  },
                  onBackToTimeline: widget.onBackToTimeline,
                  onSuggestionTapped: (_) {},
                  iconDataGetter: (type) => _markerGenerator.getIconDataForType(type),
                  topPadding: topPadding,
                  onTap: () => _openSearchScreen(state),
                  onAddFriendTapped: _openFollowFriendsBottomSheet,
                  hintText: state.selectedMapTab == 1
                      ? "Find an event"
                      : (state.selectedMapTab == 3 ? "Find your places" : "Find a place"),
                ),
              ),

            if (state.selectedMapTab != 2)
              Positioned(
                top: topPadding + 64,
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

            if (state.selectedMapTab != 2 && state.selectedCategory.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: topPadding + 10,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back Button & Category Name
                      GestureDetector(
                        onTap: () {
                          ref.read(exploreViewModelProvider.notifier).updateCategory("");
                          _searchController.clear();
                          ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);
                          final lat = state.userLocation?.latitude ?? 24.7136;
                          final lng = state.userLocation?.longitude ?? 46.6753;
                          ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng, category: "", zoom: _currentZoom);
                        },
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_new,
                                size: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.selectedCategory == "Restaurant" ? "Restaurants" : state.selectedCategory,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter row
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Filter icon button
                            GestureDetector(
                              onTap: () => _openFilterBottomSheet(state),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F3F5),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.tune,
                                      color: Color(0xFF1A1A2E),
                                      size: 16,
                                    ),
                                  ),
                                  if (state.filterState.isModified)
                                    Positioned(
                                      top: -1,
                                      right: -1,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Price
                            _buildFilterPill(
                              label: state.filterState.priceRange ?? "Price",
                              isActive: state.filterState.priceRange != null,
                              icon: Icons.keyboard_arrow_down,
                              onTap: () => _openPriceMiniBottomSheet(state),
                            ),
                            const SizedBox(width: 8),
                            // Open now
                            _buildFilterPill(
                              label: "Open now",
                              isActive: state.filterState.openNow,
                              onTap: () {
                                final updated = state.filterState.copyWith(openNow: !state.filterState.openNow);
                                ref.read(exploreViewModelProvider.notifier).updateFilterState(updated);
                              },
                            ),
                            const SizedBox(width: 8),
                            // Saved
                            _buildFilterPill(
                              label: "Saved",
                              isActive: state.filterState.saved,
                              icon: Icons.bookmark,
                              onTap: () {
                                final updated = state.filterState.copyWith(saved: !state.filterState.saved);
                                ref.read(exploreViewModelProvider.notifier).updateFilterState(updated);
                              },
                            ),
                            const SizedBox(width: 8),
                            // Rating
                            _buildFilterPill(
                              label: state.filterState.minRating != null && state.filterState.minRating! > 0
                                  ? "Rating: ${(state.filterState.minRating! * 2.0).toStringAsFixed((state.filterState.minRating! * 2.0) == 9.5 ? 1 : 0)}"
                                  : "Rating",
                              isActive: state.filterState.minRating != null && state.filterState.minRating! > 0,
                              icon: Icons.keyboard_arrow_down,
                              onTap: () => _openRatingMiniBottomSheet(state),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!showCategoryResultsMode && state.selectedPlace == null)
              Positioned(
                left: 16,
                right: 16,
                bottom: controlsBottom,
                child: ExploreFloatingControls(
                  bottom: controlsBottom,
                  selectedMapTab: state.selectedMapTab,
                  onLocationTap: () => _animateToUserLocation(state.userLocation),
                  onTabChanged: (index) {
                    ref.read(exploreViewModelProvider.notifier).updateMapTab(index);
                    String msg = "";
                    if (index == 0) msg = "Discover";
                    if (index == 1) msg = "Events";
                    if (index == 2) msg = "Live Now";
                    if (index == 3) msg = "You";
                    _triggerStatusBadge(msg);
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

            Positioned(
              left: 0,
              right: 0,
              bottom: controlsBottom + 64,
              child: ExploreStatusBadge(
                show: _showStatusBadge,
                message: _statusMessage,
                bottom: controlsBottom + 64,
              ),
            ),

            if (showCategoryResultsMode && state.selectedPlace == null) ...[
              if (!state.isListView)
                Positioned(
                  left: 16,
                  bottom: controlsBottom,
                  child: GestureDetector(
                    onTap: () => _animateToUserLocation(state.userLocation),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/explore/sent.svg',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF7C57FC),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                bottom: state.isListView ? controlsBottom : (controlsBottom + 64),
                child: GestureDetector(
                  onTap: () {
                    ref.read(exploreViewModelProvider.notifier).updateListView(!state.isListView);
                  },
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          state.isListView ? Icons.map_outlined : Icons.format_list_bulleted,
                          color: const Color(0xFF7C57FC),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
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
      final exploreState = ref.read(exploreViewModelProvider);
      final lat = exploreState.userLocation?.latitude ?? 24.7136;
      final lng = exploreState.userLocation?.longitude ?? 46.6753;
      ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng);
      widget.onBackToTimeline();
    }
  }
}
