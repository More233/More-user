import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../timeline/widgets/check_in_composer_screen.dart';
import 'place_details_screen.dart';
import 'services/explore_data_service.dart';
import 'helpers/marker_generator.dart';
import 'widgets/explore_place_card.dart';
import 'widgets/explore_search_bar.dart';
import 'widgets/explore_filter_sheet.dart';
import 'widgets/explore_list_view.dart';
import 'widgets/explore_map_tabs.dart';
import 'widgets/explore_view_toggle_pill.dart';
import 'explore_search_screen.dart';



class ExploreScreen extends StatefulWidget {
  final VoidCallback onBackToTimeline;
  final String? userAvatarUrl;
  const ExploreScreen({
    super.key,
    required this.onBackToTimeline,
    this.userAvatarUrl,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
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
  int _selectedMapTab = 0; // 0: Globe, 1: Ticket, 2: Heatmap, 3: Favorite
  String _selectedCategory = ""; // "", "Restaurant", "Coffee", "Bakery", "Bars", "Desserts"
  bool _filterVisited = false;
  bool _filterSaved = false;
  FilterState _filterState = FilterState();
  String _searchQuery = "";
  bool _isListView = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  int _lastRoundedZoom = 13;
  double _currentZoom = 13.0;
  final TextEditingController _searchController = TextEditingController();

  final LatLng _currentCameraPosition = const LatLng(24.7136, 46.6753); // Default Riyadh
  LatLng? _userLocation;

  // Selected place state
  Map<String, dynamic>? _selectedPlace;

  final MarkerGenerator _markerGenerator = MarkerGenerator();

  // Status Badge Overlay State
  bool _showStatusBadge = false;
  String _statusMessage = "";
  Timer? _statusBadgeTimer;

  List<Map<String, dynamic>> _allPlaces = [];
  final List<Map<String, dynamic>> _recentPlaces = [];
  LatLng? _lastFetchedLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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
    _debounceTimer?.cancel();
    super.dispose();
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

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        _fetchNearbyPlaces(24.7136, 46.6753);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_userLocation!, 15.0),
            );
          }
          _fetchNearbyPlaces(position.latitude, position.longitude);
        }
      } else {
        _fetchNearbyPlaces(24.7136, 46.6753);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      _fetchNearbyPlaces(24.7136, 46.6753);
    }
  }

  void _animateToUserLocation() {
    if (_userLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 15.0),
        ),
      );
    }
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ExploreFilterSheet(
          initialState: _filterState,
          onApply: (newState) {
            setState(() {
              _filterState = newState;
              _filterVisited = newState.visited;
              _filterSaved = newState.saved;
              _selectedPlace = null;
            });
          },
        );
      },
    );
  }

  void _openSearchScreen() async {
    final lat = _userLocation?.latitude ?? 24.7136;
    final lng = _userLocation?.longitude ?? 46.6753;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreSearchScreen(
          userLat: lat,
          userLng: lng,
          recentPlaces: _recentPlaces,
          onRecentPlaceAdded: (place) {
            setState(() {
              if (!_recentPlaces.any((p) => p['id'] == place['id'])) {
                _recentPlaces.insert(0, place);
              }
            });
          },
          filterState: {
            'visited': _filterState.visited,
            'saved': _filterState.saved,
            'priceLevel': _filterState.priceRange ?? 'Any',
            'ratingMin': _filterState.minRating ?? 0.0,
            'openNow': _filterState.openNow,
          },
          onFilterStateChanged: (updatedFilters) {
            setState(() {
              _filterState = _filterState.copyWith(
                visited: updatedFilters['visited'] as bool?,
                saved: updatedFilters['saved'] as bool?,
                openNow: updatedFilters['openNow'] as bool?,
                minRating: () => updatedFilters['ratingMin'] as double?,
                priceRange: () => updatedFilters['priceLevel'] == 'Any' ? null : updatedFilters['priceLevel'] as String?,
              );
              _filterVisited = _filterState.visited;
              _filterSaved = _filterState.saved;
            });
          },
        ),
      ),
    );

    if (result != null && mounted) {
      if (result['type'] == 'place') {
        final place = result['place'] as Map<String, dynamic>;
        setState(() {
          if (!_allPlaces.any((p) => p['id'] == place['id'])) {
            _allPlaces.add(place);
          }
          _searchQuery = "";
          _searchController.text = place['name']?.toString() ?? '';
        });
        _selectPlaceAndLoadDetails(place);
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
        if (_userLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_userLocation!.latitude, _userLocation!.longitude),
              15.0,
            ),
          );
        }
      } else if (result['type'] == 'category') {
        final category = result['category'] as String;
        final bool isSelected = _selectedCategory == category;
        setState(() {
          _selectedCategory = isSelected ? "" : category;
          _selectedPlace = null;
          _isListView = false;
        });
        _fetchNearbyPlaces(lat, lng, category: _selectedCategory);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredPlaces() {
    return _allPlaces.where((place) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatches = (place['name'] as String? ?? '').toLowerCase().contains(query);
        final arMatches = (place['arabicName'] as String? ?? '').toLowerCase().contains(query);
        if (!nameMatches && !arMatches) return false;
      }

      // 2. Favorite Mode Filter
      if (_selectedMapTab == 3) {
        if (_filterVisited && !(place['isVisited'] as bool? ?? false)) return false;
        if (_filterSaved && !(place['isSaved'] as bool? ?? false)) return false;
        if (!_filterVisited && !_filterSaved) {
          return (place['isVisited'] as bool? ?? false) || (place['isSaved'] as bool? ?? false);
        }
        return true;
      }

      // 3. Category Filter
      if (_selectedCategory.isNotEmpty) {
        final type = place['type'] as String? ?? 'Other';
        if (_selectedCategory == "Restaurant" && type != "Restaurant") return false;
        if (_selectedCategory == "Coffee" && type != "Coffee") return false;
        if (_selectedCategory == "Bakery" && type != "Bakery") return false;
        if (_selectedCategory == "Bars" && type != "Bars") return false;
      }

      // 4. Ticket Mode Filter
      if (_selectedMapTab == 1) {
        return place['type'] == 'Ticket';
      }

      // 5. Heatmap Mode Filter: only show places with check-ins
      if (_selectedMapTab == 2) {
        final peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
        if (peopleCount <= 0) return false;
      }

      // --- New Filter Sheet Filters ---
      
      // A. Distance Filter
      if (_filterState.maxDistance != null) {
        final double? dist = _parseDistance(place['distance'] as String?);
        if (dist == null || dist > _filterState.maxDistance!) {
          return false;
        }
      }

      // B. Open Now Filter
      if (_filterState.openNow) {
        final openNow = place['openNow'] as bool? ?? true;
        if (!openNow) return false;
      }

      // C. Rating Filter
      if (_filterState.minRating != null) {
        final rating = (place['rating'] as num? ?? 0.0).toDouble();
        if (rating < _filterState.minRating!) return false;
      }

      // D. Price Filter
      if (_filterState.priceRange != null) {
        final price = place['price'] as String? ?? r'$$';
        if (price != _filterState.priceRange) return false;
      }

      // E. Places Filters
      if (_filterState.visited && !(place['isVisited'] as bool? ?? false)) return false;
      if (_filterState.saved && !(place['isSaved'] as bool? ?? false)) return false;
      if (_filterState.newToMe && (place['isVisited'] as bool? ?? false)) return false;
      if (_filterState.onList && !(place['isSaved'] as bool? ?? false)) return false;

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

  Set<Marker> _buildMarkers() {
    final filtered = _getFilteredPlaces();
    final Set<Marker> markers = {};

    final List<Map<String, dynamic>> placesToDraw = List.from(filtered);

    if (_selectedPlace != null) {
      final selectedId = _selectedPlace!['id'];
      if (!placesToDraw.any((p) => p['id'] == selectedId)) {
        placesToDraw.add(_selectedPlace!);
      }
    }

    final bool useHeatmapStyle = _selectedMapTab == 2;
    final normalCustomCache = useHeatmapStyle ? _markerGenerator.customPlaceMarkersNormalHeatmap : _markerGenerator.customPlaceMarkersNormal;
    final selectedCustomCache = useHeatmapStyle ? _markerGenerator.customPlaceMarkersSelectedHeatmap : _markerGenerator.customPlaceMarkersSelected;

    for (final place in placesToDraw) {
      final isSelected = _selectedPlace != null && _selectedPlace!['id'] == place['id'];
      final type = place['type'] as String? ?? 'Other';
      final iconUrl = place['iconUrl'] as String?;
      final isCheckIn = place['isCheckIn'] as bool? ?? false;
      final authorAvatar = place['authorAvatar'] as String?;
      
      BitmapDescriptor icon;
      final bool isManualTapped = place['id'].toString().startsWith('tapped_');
      double anchorX = 0.5;
      double anchorY = 1.0;

      final bool isProminent = _isProminentPlace(place);
      final bool showAsPin = isSelected || isProminent || _currentZoom >= 15.0;

      if (isManualTapped) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      } else if (isCheckIn && authorAvatar != null && _markerGenerator.avatarMarkerCache.containsKey(authorAvatar)) {
        icon = _markerGenerator.avatarMarkerCache[authorAvatar]!;
      } else if (showAsPin) {
        final bool showCustomLabel = (isSelected || _currentZoom >= 15.0) && normalCustomCache.containsKey(place['id'].toString());
        
        if (showCustomLabel) {
          if (isSelected && selectedCustomCache.containsKey(place['id'].toString())) {
            icon = selectedCustomCache[place['id'].toString()]!;
          } else {
            icon = normalCustomCache[place['id'].toString()]!;
          }
          
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
        } else {
          if (_selectedMapTab == 2) {
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
        if (_selectedMapTab == 2) {
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
            _selectPlaceAndLoadDetails(place);
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

  Set<Circle> _buildHeatmapCircles() {
    if (_selectedMapTab != 2) return {};

    final Set<Circle> circles = {};
    final List<Map<String, dynamic>> filtered = _getFilteredPlaces();

    for (final place in filtered) {
      final double lat = (place['latitude'] as num? ?? 0.0).toDouble();
      final double lng = (place['longitude'] as num? ?? 0.0).toDouble();
      final int peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
      if (peopleCount <= 0) continue;

      final String placeId = place['id']?.toString() ?? UniqueKey().toString();
      
      // Calculate dynamic radius scaling based on crowd count
      final double baseRadius = 80.0 + (peopleCount * 40.0).clamp(0.0, 400.0);

      // Draw 3 concentric glowing purple circles to create a beautiful heatmap gradient effect
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
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final double navBarHeight = 70 + (bottomPadding > 0 ? bottomPadding + 6 : 16);
    final double controlsBottom = navBarHeight + 24;
    final double overlaysBottom = controlsBottom + 56 + 12;

    final bool showCategoryResultsMode = _selectedCategory.isNotEmpty || _searchQuery.isNotEmpty || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_isListView) ...[
            Positioned.fill(
              child: ExploreListView(
                topPadding: topPadding,
                navBarHeight: navBarHeight,
                filteredPlaces: _getFilteredPlaces(),
                userAvatarUrl: widget.userAvatarUrl,
                searchController: _searchController,
                isSearching: _isSearching,
                searchQuery: _searchQuery,
                onBackToTimeline: widget.onBackToTimeline,
                onFilterPressed: _openFilterBottomSheet,
                onSearchChanged: (_) {},
                onSearchSubmitted: (value) async {
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _isSearching = true;
                    });
                    final lat = _userLocation?.latitude ?? 24.7136;
                    final lng = _userLocation?.longitude ?? 46.6753;
                    final results = await ExploreDataService.searchFoursquarePlaces(value, lat, lng);
                    setState(() {
                      if (results.isNotEmpty) {
                        _allPlaces = results;
                        _selectedPlace = results.first;
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng((results.first['latitude'] as num? ?? 0.0).toDouble(), (results.first['longitude'] as num? ?? 0.0).toDouble()),
                            15.0,
                          ),
                        );
                      }
                      _isSearching = false;
                    });
                    if (results.isNotEmpty) {
                      _markerGenerator.preloadNetworkIconsForPlaces(results, () {
                        if (mounted) setState(() {});
                      });
                      _markerGenerator.preloadPlaceMarkers(results, () {
                        if (mounted) setState(() {});
                      });
                    }
                  }
                },
                onPlaceActionTriggered: _handlePlaceAction,
                onCategoryTapped: (category) {
                  final bool isSelected = _selectedCategory == category;
                  setState(() {
                    _selectedCategory = isSelected ? "" : category;
                    _selectedPlace = null;
                    _isListView = false;
                  });

                  final lat = _userLocation?.latitude ?? 24.7136;
                  final lng = _userLocation?.longitude ?? 46.6753;
                  _fetchNearbyPlaces(lat, lng, category: _selectedCategory);
                },
                selectedCategory: _selectedCategory,
                onClearSearch: () {
                  setState(() {
                    _searchQuery = "";
                    _searchController.clear();
                    _selectedPlace = null;
                    _isListView = false;
                  });
                },
                onSearchTap: _openSearchScreen,
              ),
            ),
          ] else ...[
            Positioned.fill(
              child: GoogleMap(
                style: _mapStyleJson,
                initialCameraPosition: CameraPosition(
                  target: _currentCameraPosition,
                  zoom: 13.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_userLocation != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_userLocation!, 13.0),
                    );
                  }
                },
                onCameraMove: (position) {
                  final double oldZoom = _currentZoom;
                  _currentZoom = position.zoom;

                  final bool crossedThreshold = (oldZoom < 15.0 && _currentZoom >= 15.0) ||
                                                (oldZoom >= 15.0 && _currentZoom < 15.0);

                  final int roundedZoom = position.zoom.round();
                  if (roundedZoom != _lastRoundedZoom || crossedThreshold) {
                    _lastRoundedZoom = roundedZoom;
                    _markerGenerator.initMarkerIcons(
                      zoom: position.zoom,
                      onUpdate: () {
                        if (mounted) setState(() {});
                      },
                    );
                    if (crossedThreshold) {
                      setState(() {});
                    }
                  }
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationEnabled: _userLocation != null,
                myLocationButtonEnabled: false,
                markers: _buildMarkers(),
                circles: _buildHeatmapCircles(),
                onTap: (latLng) {
                  setState(() {
                    _selectedPlace = null;
                  });
                },
                onLongPress: (latLng) {
                  _onMapTapped(latLng);
                },
                onCameraIdle: () {
                  if (_mapController != null) {
                    _mapController!.getVisibleRegion().then((bounds) {
                      final center = LatLng(
                        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                      );
                      if (_lastFetchedLocation == null) {
                        _lastFetchedLocation = center;
                        _fetchNearbyPlaces(center.latitude, center.longitude);
                      } else {
                        final distance = Geolocator.distanceBetween(
                          _lastFetchedLocation!.latitude,
                          _lastFetchedLocation!.longitude,
                          center.latitude,
                          center.longitude,
                        );
                        if (distance > 1500) {
                          _lastFetchedLocation = center;
                          _fetchNearbyPlaces(center.latitude, center.longitude);
                        }
                      }
                    });
                  }
                },
              ),
            ),

            if (_selectedPlace != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: overlaysBottom,
                child: ExplorePlaceCard(
                  place: _selectedPlace!,
                  onSavedChanged: (val) {
                    setState(() {
                      _selectedPlace!['isSaved'] = val;
                      final idx = _allPlaces.indexWhere((p) => p['id'] == _selectedPlace!['id']);
                      if (idx != -1) {
                        _allPlaces[idx]['isSaved'] = val;
                      }
                    });
                  },
                  onActionTriggered: () => _handlePlaceAction(_selectedPlace!),
                  onViewPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailsScreen(
                          place: _selectedPlace!,
                          onActionTriggered: () => _handlePlaceAction(_selectedPlace!),
                        ),
                      ),
                    );
                  },
                  onInteractionPressed: () {
                    final authorName = _selectedPlace!['authorName'] as String? ?? 'Anonymous';
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
                bottom: overlaysBottom + (_selectedPlace != null ? 140 : 0),
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

            if (_selectedMapTab != 2)
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
                  onSearchChanged: (_) {},
                  onSearchSubmitted: (_) {},
                  onClearSearch: () {},
                  onBackToTimeline: widget.onBackToTimeline,
                  onSuggestionTapped: (_) {},
                  iconDataGetter: (type) => _markerGenerator.getIconDataForType(type),
                  topPadding: topPadding,
                  onTap: _openSearchScreen,
                ),
              ),

            if (_selectedMapTab != 2)
              Positioned(
                top: topPadding + 80,
                left: 0,
                right: 0,
                child: ExploreCategoryFilters(
                  selectedMapTab: _selectedMapTab,
                  selectedCategory: _selectedCategory,
                  filterVisited: _filterVisited,
                  filterSaved: _filterSaved,
                  onCategoryTapped: (category) {
                    final bool isSelected = _selectedCategory == category;
                    setState(() {
                      _selectedCategory = isSelected ? "" : category;
                      _selectedPlace = null;
                      _isListView = false;
                    });
                    final lat = _userLocation?.latitude ?? 24.7136;
                    final lng = _userLocation?.longitude ?? 46.6753;
                    _fetchNearbyPlaces(lat, lng, category: _selectedCategory);
                  },
                  onFilterVisitedTapped: () {
                    setState(() {
                      _filterVisited = !_filterVisited;
                      _filterState = _filterState.copyWith(visited: _filterVisited);
                    });
                  },
                  onFilterSavedTapped: () {
                    setState(() {
                      _filterSaved = !_filterSaved;
                      _filterState = _filterState.copyWith(saved: _filterSaved);
                    });
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
                      onTap: _animateToUserLocation,
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
                      selectedMapTab: _selectedMapTab,
                      onTabChanged: (index) {
                        setState(() {
                          _selectedMapTab = index;
                          _selectedPlace = null;
                        });
                        
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

          if (_selectedPlace == null && (_isListView || showCategoryResultsMode))
            Positioned(
              left: 0,
              right: 0,
              bottom: controlsBottom,
              child: Center(
                child: ExploreViewTogglePill(
                  isListView: _isListView,
                  onViewChanged: (isList) {
                    setState(() {
                      _isListView = isList;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }





  void _selectPlaceAndLoadDetails(Map<String, dynamic> place) {
    setState(() {
      _selectedPlace = place;
    });

    final String placeId = place['id'].toString();
    final String name = place['name'] as String? ?? '';
    final double plat = (place['latitude'] as num?)?.toDouble() ?? 0.0;
    final double plng = (place['longitude'] as num?)?.toDouble() ?? 0.0;

    final bool isFoursquare = !placeId.startsWith('tapped_') &&
                              !placeId.startsWith('swarm_') &&
                              place['isCheckIn'] != true &&
                              place['isCustomVenue'] != true;

    final double userLat = _userLocation?.latitude ?? plat;
    final double userLng = _userLocation?.longitude ?? plng;

    if (isFoursquare) {
      ExploreDataService.fetchPlaceDetails(
        placeId,
        name,
        plat,
        plng,
        userLat,
        userLng,
      ).then((fullPlace) {
        if (fullPlace != null && mounted && _selectedPlace?['id'] == placeId) {
          setState(() {
            _selectedPlace = fullPlace;
            final idx = _allPlaces.indexWhere((p) => p['id'] == placeId);
            if (idx != -1) {
              _allPlaces[idx] = fullPlace;
            }
          });
          _markerGenerator.preloadNetworkIconsForPlaces([fullPlace], () {
            if (mounted) setState(() {});
          });
          _markerGenerator.preloadPlaceMarkers([fullPlace], () {
            if (mounted) setState(() {});
          });
        }
      });
    } else {
      ExploreDataService.fetchVisitorsForNonFoursquare(place).then((updatedPlace) {
        if (updatedPlace != null && mounted && _selectedPlace?['id'] == placeId) {
          setState(() {
            _selectedPlace = updatedPlace;
            final idx = _allPlaces.indexWhere((p) => p['id'] == placeId);
            if (idx != -1) {
              _allPlaces[idx] = updatedPlace;
            }
          });
        }
      });
    }
  }

  Future<void> _onMapTapped(LatLng latLng) async {
    FocusScope.of(context).unfocus();
    
    setState(() {
      _selectedPlace = null;
    });

    final double userLat = _userLocation?.latitude ?? latLng.latitude;
    final double userLng = _userLocation?.longitude ?? latLng.longitude;

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
        setState(() {
          _selectedPlace = place;
        });
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
      setState(() {
        _selectedPlace = fallbackPlace;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }



  Future<void> _fetchNearbyPlaces(double lat, double lng, {String? category}) async {
    try {
      _lastFetchedLocation = LatLng(lat, lng);
      final results = await Future.wait([
        ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng),
        ExploreDataService.fetchSupabaseCheckinsAndVenues(lat, lng),
      ]);

      final foursquarePlaces = results[0] as List<Map<String, dynamic>>;
      final supabaseResults = results[1] as Map<String, dynamic>;
      final checkins = supabaseResults['checkins'] as List<Map<String, dynamic>>;
      final customVenues = supabaseResults['customVenues'] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          final existingIds = _allPlaces.map((p) => p['id']).toSet();
          for (final p in foursquarePlaces) {
            if (!existingIds.contains(p['id'])) {
              _allPlaces.add(p);
            }
          }
          for (final c in checkins) {
            if (!existingIds.contains(c['id'])) {
              _allPlaces.add(c);
            }
          }
          for (final v in customVenues) {
            if (!existingIds.contains(v['id'])) {
              _allPlaces.add(v);
            }
          }
        });

        _markerGenerator.preloadNetworkIconsForPlaces(foursquarePlaces, () {
          if (mounted) setState(() {});
        });
        final List<Map<String, dynamic>> allPlacesToPreload = [...foursquarePlaces, ...customVenues];
        _markerGenerator.preloadPlaceMarkers(allPlacesToPreload, () {
          if (mounted) setState(() {});
        });
        await _markerGenerator.preloadCheckInAvatars(checkins, () {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      debugPrint("Error fetching nearby places: $e");
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
