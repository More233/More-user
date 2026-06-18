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
  String _searchQuery = "";
  bool _isListView = false;
  List<Map<String, dynamic>> _suggestionsResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  int _lastRoundedZoom = 13;
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

      return true;
    }).toList();
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

    for (final place in placesToDraw) {
      final isSelected = _selectedPlace != null && _selectedPlace!['id'] == place['id'];
      final type = place['type'] as String? ?? 'Other';
      final iconUrl = place['iconUrl'] as String?;
      final isCheckIn = place['isCheckIn'] as bool? ?? false;
      final authorAvatar = place['authorAvatar'] as String?;
      
      BitmapDescriptor icon;
      final bool isManualTapped = place['id'].toString().startsWith('tapped_');

      if (isManualTapped) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      } else if (isCheckIn && authorAvatar != null && _markerGenerator.avatarMarkerCache.containsKey(authorAvatar)) {
        icon = _markerGenerator.avatarMarkerCache[authorAvatar]!;
      } else if (iconUrl != null &&
          (isSelected ? _markerGenerator.networkIconsSelectedCache : _markerGenerator.networkIconsNormalCache).containsKey(iconUrl)) {
        icon = (isSelected ? _markerGenerator.networkIconsSelectedCache : _markerGenerator.networkIconsNormalCache)[iconUrl]!;
      } else if (_markerGenerator.iconsLoaded) {
        if (_selectedMapTab == 2) {
          icon = _markerGenerator.heatmapMarkerIcons[type] ?? _markerGenerator.heatmapMarkerIcons['default']!;
        } else if (isSelected) {
          icon = _markerGenerator.selectedMarkerIcons[type] ?? _markerGenerator.selectedMarkerIcons['default']!;
        } else {
          icon = _markerGenerator.normalMarkerIcons[type] ?? _markerGenerator.normalMarkerIcons['default']!;
        }
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
          anchor: const Offset(0.5, 1.0),
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
    
    final List<LatLng> centers = [
      const LatLng(24.7136, 46.6753),
      const LatLng(24.7212, 46.6823),
      const LatLng(24.7812, 46.6890),
      const LatLng(24.7512, 46.6990),
      const LatLng(24.8112, 46.7223),
      const LatLng(24.8412, 46.5912),
    ];

    for (int i = 0; i < centers.length; i++) {
      final center = centers[i];
      final prefix = 'heat_$i';
      
      circles.add(Circle(
        circleId: CircleId('${prefix}_outer'),
        center: center,
        radius: 1800,
        fillColor: const Color(0xFF7C57FC).withValues(alpha: 0.04),
        strokeWidth: 0,
      ));
      
      circles.add(Circle(
        circleId: CircleId('${prefix}_teal'),
        center: center,
        radius: 1300,
        fillColor: const Color(0xFF00E5FF).withValues(alpha: 0.08),
        strokeWidth: 0,
      ));

      circles.add(Circle(
        circleId: CircleId('${prefix}_green'),
        center: center,
        radius: 900,
        fillColor: const Color(0xFF00C853).withValues(alpha: 0.12),
        strokeWidth: 0,
      ));

      circles.add(Circle(
        circleId: CircleId('${prefix}_yellow'),
        center: center,
        radius: 550,
        fillColor: const Color(0xFFFFA000).withValues(alpha: 0.18),
        strokeWidth: 0,
      ));

      circles.add(Circle(
        circleId: CircleId('${prefix}_core'),
        center: center,
        radius: 280,
        fillColor: const Color(0xFFFF3D00).withValues(alpha: 0.25),
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
              child: _buildListView(topPadding, navBarHeight),
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
                  final int roundedZoom = position.zoom.round();
                  if (roundedZoom != _lastRoundedZoom) {
                    _lastRoundedZoom = roundedZoom;
                    _markerGenerator.initMarkerIcons(
                      zoom: position.zoom,
                      onUpdate: () {
                        if (mounted) setState(() {});
                      },
                    );
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C57FC).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _statusMessage,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                  isSearching: _isSearching,
                  searchQuery: _searchQuery,
                  suggestions: _suggestionsResults,
                  userAvatarUrl: widget.userAvatarUrl,
                  onSearchChanged: _onSearchChanged,
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
                        }
                        _suggestionsResults = [];
                        _isSearching = false;
                      });
                      if (results.isNotEmpty) {
                        _selectPlaceAndLoadDetails(results.first);
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng((results.first['latitude'] as num? ?? 0.0).toDouble(), (results.first['longitude'] as num? ?? 0.0).toDouble()),
                            15.0,
                          ),
                        );
                      }
                    }
                  },
                  onClearSearch: () {
                    setState(() {
                      _searchQuery = "";
                      _searchController.clear();
                      _suggestionsResults = [];
                      _selectedPlace = null;
                      _isListView = false;
                    });
                  },
                  onBackToTimeline: widget.onBackToTimeline,
                  onSuggestionTapped: (suggestion) {
                    setState(() {
                      if (!_allPlaces.any((p) => p['id'] == suggestion['id'])) {
                        _allPlaces.add(suggestion);
                      }
                      _searchQuery = "";
                      _searchController.text = suggestion['name']?.toString() ?? '';
                      _suggestionsResults = [];
                    });
                    _selectPlaceAndLoadDetails(suggestion);
                    _markerGenerator.preloadNetworkIconsForPlaces([suggestion], () {
                      if (mounted) setState(() {});
                    });
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng((suggestion['latitude'] as num? ?? 0.0).toDouble(), (suggestion['longitude'] as num? ?? 0.0).toDouble()),
                        15.0,
                      ),
                    );
                    FocusScope.of(context).unfocus();
                  },
                  iconDataGetter: (type) => _markerGenerator.getIconDataForType(type),
                  topPadding: topPadding,
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
                    });
                  },
                  onFilterSavedTapped: () {
                    setState(() {
                      _filterSaved = !_filterSaved;
                    });
                  },
                  topPadding: topPadding,
                ),
              ),

            if (_searchQuery.isNotEmpty && _suggestionsResults.isNotEmpty)
              Positioned(
                top: topPadding + 76,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestionsResults.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestionsResults[index];
                          return ListTile(
                            leading: Icon(
                              _markerGenerator.getIconDataForType(suggestion['type'] as String? ?? 'Other'),
                              color: const Color(0xFF7C57FC),
                            ),
                            title: Text(
                              suggestion['name'] as String? ?? '',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              suggestion['address'] as String? ?? '',
                              style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                if (!_allPlaces.any((p) => p['id'] == suggestion['id'])) {
                                  _allPlaces.add(suggestion);
                                }
                                _searchQuery = "";
                                _searchController.text = suggestion['name']?.toString() ?? '';
                                _suggestionsResults = [];
                              });
                              _selectPlaceAndLoadDetails(suggestion);
                              _markerGenerator.preloadNetworkIconsForPlaces([suggestion], () {
                                if (mounted) setState(() {});
                              });
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng((suggestion['latitude'] as num? ?? 0.0).toDouble(), (suggestion['longitude'] as num? ?? 0.0).toDouble()),
                                  15.0,
                                ),
                              );
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ),
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

                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPillTabItem(
                            index: 0,
                            iconPath: 'assets/explore/earth.svg',
                          ),
                          const SizedBox(width: 8),
                          _buildPillTabItem(
                            index: 1,
                            iconPath: '',
                            iconData: Icons.explore_outlined,
                          ),
                          const SizedBox(width: 8),
                          _buildPillTabItem(
                            index: 2,
                            iconPath: '',
                            iconData: Icons.sensors,
                          ),
                          const SizedBox(width: 8),
                          _buildPillTabItem(
                            index: 3,
                            iconPath: 'assets/explore/favourite.svg',
                          ),
                        ],
                      ),
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
                child: _buildViewTogglePill(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView(double topPadding, double navBarHeight) {
    final filteredPlaces = _getFilteredPlaces();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(
            top: topPadding + 12,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF0F0F0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  widget.onBackToTimeline();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: widget.userAvatarUrl != null
                          ? NetworkImage(widget.userAvatarUrl!)
                          : const AssetImage('assets/Timeline/images/element.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF82858C),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onSubmitted: (value) async {
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
                                _suggestionsResults = [];
                                _isSearching = false;
                              });
                              if (results.isNotEmpty) {
                                _markerGenerator.preloadNetworkIconsForPlaces(results, () {
                                  if (mounted) setState(() {});
                                });
                              }
                            }
                          },
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            color: const Color(0xFF333333),
                          ),
                          decoration: InputDecoration(
                            hintText: "Find a place",
                            hintStyle: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              color: const Color(0xBF3B3C4F),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                            ),
                          ),
                        )
                      else if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchQuery = "";
                              _searchController.clear();
                              _suggestionsResults = [];
                              _selectedPlace = null;
                              _isListView = false;
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF82858C),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE8E8E8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF333333),
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryPill("Restaurant", Icons.restaurant),
              const SizedBox(width: 8),
              _buildCategoryPill("Coffee", Icons.local_cafe),
              const SizedBox(width: 8),
              _buildCategoryPill("Bakery", Icons.breakfast_dining),
              const SizedBox(width: 8),
              _buildCategoryPill("Bars", Icons.local_bar),
              const SizedBox(width: 8),
              _buildCategoryPill("Desserts", Icons.icecream),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  "${filteredPlaces.length} results are found",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: navBarHeight + 80),
                    itemCount: filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaceDetailsScreen(
                                place: place,
                                onActionTriggered: () => _handlePlaceAction(place),
                              ),
                            ),
                          );
                        },
                        child: ExploreListPlaceCard(place: place),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewTogglePill() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isListView = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: !_isListView ? const Color(0xFFEDE6FC) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: !_isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Map",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: !_isListView ? FontWeight.w600 : FontWeight.normal,
                      color: !_isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isListView = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _isListView ? const Color(0xFFEDE6FC) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 18,
                    color: _isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "List",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: _isListView ? FontWeight.w600 : FontWeight.normal,
                      color: _isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String category, IconData icon) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? "" : category;
          _selectedPlace = null;
          _isListView = false;
        });

        final lat = _userLocation?.latitude ?? 24.7136;
        final lng = _userLocation?.longitude ?? 46.6753;
        _fetchNearbyPlaces(lat, lng, category: _selectedCategory);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C57FC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF333333),
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTabItem({
    required int index,
    required String iconPath,
    IconData? iconData,
  }) {
    final bool isActive = _selectedMapTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMapTab = index;
          _selectedPlace = null;
        });
        
        String msg = "";
        if (index == 0) msg = "Globe";
        if (index == 1) msg = "Events";
        if (index == 2) msg = "Live Now";
        if (index == 3) msg = "My Places";
        _triggerStatusBadge(msg);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE6FC) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: iconData != null
            ? Icon(
                iconData,
                size: 22,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
              )
            : SvgPicture.asset(
                iconPath,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  BlendMode.srcIn,
                ),
              ),
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

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestionsResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final lat = _userLocation?.latitude ?? 24.7136;
    final lng = _userLocation?.longitude ?? 46.6753;
    final results = await ExploreDataService.searchFoursquarePlaces(query, lat, lng);

    setState(() {
      _suggestionsResults = results;
      _isSearching = false;
    });
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
