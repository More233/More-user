import 'dart:async';
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
import 'widgets/search/explore_list_view.dart';
import 'widgets/search/explore_view_toggle_pill.dart';
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
              child: ExploreMapWidget(
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
                onTap: (latLng) {
                  ref.read(exploreViewModelProvider.notifier).updateSelectedPlaceManual(null);
                },
                onLongPress: (latLng) {
                  _onMapTapped(latLng, state);
                },
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

            if (!showCategoryResultsMode)
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
                    if (index == 2) msg = "Swarming now";
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
