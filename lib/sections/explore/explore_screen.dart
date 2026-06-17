import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../timeline/widgets/check_in_composer_screen.dart';
import 'place_details_screen.dart';

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

  // Dynamic Marker Icons
  final Map<String, BitmapDescriptor> _normalMarkerIcons = {};
  final Map<String, BitmapDescriptor> _selectedMarkerIcons = {};
  final Map<String, BitmapDescriptor> _heatmapMarkerIcons = {};
  bool _iconsLoaded = false;

  // Status Badge Overlay State
  bool _showStatusBadge = false;
  String _statusMessage = "";
  Timer? _statusBadgeTimer;

  // List of mock places in Riyadh
  List<Map<String, dynamic>> _allPlaces = [
    {
      'id': '1',
      'name': 'Serdab | سرداب',
      'arabicName': 'سرداب',
      'type': 'Coffee',
      'address': 'Riyadh, Saudi Arabia',
      'latitude': 24.7136,
      'longitude': 46.6753,
      'distance': '1.1 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 29,
      'actionType': 'Order',
      'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500',
      'isSaved': true,
      'isVisited': true,
    },
    {
      'id': '2',
      'name': "McDonal's",
      'arabicName': 'ماكدونالدز',
      'type': 'Restaurant',
      'address': 'Al-Muanisiyah, Riyadh',
      'latitude': 24.8112,
      'longitude': 46.7223,
      'distance': '2.0 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 62,
      'actionType': 'Book',
      'imageUrl': 'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=500',
      'isSaved': false,
      'isVisited': true,
    },
    {
      'id': '3',
      'name': 'Riyadh Golf-Courses | ملاعب الرياض للجولف',
      'arabicName': 'ملاعب الرياض للجولف',
      'type': 'Park',
      'address': 'Riyadh Golf-Courses',
      'latitude': 24.8912,
      'longitude': 46.6323,
      'distance': '5.9 km',
      'rating': 4.6,
      'reviewsCount': 121,
      'price': r'$$',
      'peopleCount': 45,
      'actionType': 'check-in',
      'imageUrl': 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?w=500',
      'isSaved': true,
      'isVisited': false,
    },
    {
      'id': '4',
      'name': 'Durrat Al Rriyadh | درة الرياض',
      'arabicName': 'درة الرياض',
      'type': 'Ticket',
      'address': 'Riyadh, Saudi Arabia',
      'latitude': 24.9312,
      'longitude': 46.6123,
      'distance': '12 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 110,
      'actionType': 'Book',
      'imageUrl': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500',
      'isSaved': false,
      'isVisited': true,
    },
    {
      'id': '5',
      'name': 'Half Milion',
      'arabicName': 'هالف مليون',
      'type': 'Coffee',
      'address': 'Riyadh, Saudi Arabia',
      'latitude': 24.7812,
      'longitude': 46.6890,
      'distance': '3.4 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 18,
      'actionType': 'Order',
      'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500',
      'isSaved': true,
      'isVisited': true,
    },
    {
      'id': '6',
      'name': 'King Salman Desert Park | منتزه الملك سلمان البري',
      'arabicName': 'منتزه الملك سلمان البري',
      'type': 'Park',
      'address': 'Riyadh, Saudi Arabia',
      'latitude': 24.8412,
      'longitude': 46.5912,
      'distance': '8.2 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$',
      'peopleCount': 12,
      'actionType': 'check-in',
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500',
      'isSaved': false,
      'isVisited': false,
    },
    {
      'id': '7',
      'name': 'محطة ساسكو',
      'arabicName': 'محطة ساسكو',
      'type': 'Bars', // Used for Gas / default icon
      'address': 'Riyadh, Saudi Arabia',
      'latitude': 24.7512,
      'longitude': 46.6990,
      'distance': '2.1 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 17,
      'actionType': 'Order',
      'imageUrl': 'https://images.unsplash.com/photo-1527018601619-a508a2be00cd?w=500',
      'isSaved': false,
      'isVisited': true,
    },
    {
      'id': '8',
      'name': 'مطار الملك خالد الدولي',
      'arabicName': 'مطار الملك خالد الدولي',
      'type': 'Airport',
      'address': 'Airport, Riyadh',
      'latitude': 24.9586,
      'longitude': 46.6990,
      'distance': '18 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 344,
      'actionType': 'Book',
      'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500',
      'isSaved': false,
      'isVisited': true,
    },
    {
      'id': '9',
      'name': 'كريب الباشا',
      'arabicName': 'كريب الباشا',
      'type': 'Restaurant',
      'address': 'Riyadh, Saudi Arabia',
      'latitude': 24.7212,
      'longitude': 46.6823,
      'distance': '1.5 km',
      'rating': 4.7,
      'reviewsCount': 121,
      'price': r'$$$',
      'peopleCount': 189,
      'actionType': 'Order',
      'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
      'isSaved': true,
      'isVisited': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _initMarkerIcons();
  }

  @override
  void dispose() {
    _statusBadgeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Dynamic Map Pin Painter
  Future<BitmapDescriptor> _createCircleIcon(IconData iconData, Color color, {required bool isSelected, double scale = 1.0}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double baseSize = isSelected ? 36.0 : 26.0;
    final double size = baseSize * scale;
    
    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, (isSelected ? 3.0 : 1.5) * scale);
    canvas.drawCircle(Offset(size / 2, size / 2), (size / 2 - 1.5 * scale), shadowPaint);

    // Draw main colored circle
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), (size / 2 - 2 * scale), paint);

    // Draw white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isSelected ? 2.0 : 1.2) * scale;
    canvas.drawCircle(Offset(size / 2, size / 2), (size / 2 - 2 * scale), borderPaint);

    // Draw thick outer glowing ring if selected
    if (isSelected) {
      final Paint glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
      canvas.drawCircle(Offset(size / 2, size / 2), (size / 2 - 2 * scale), glowPaint);
    }

    // Draw white icon
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: (isSelected ? 18.0 : 12.0) * scale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    final Uint8List uint8list = byteData.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8list);
  }

  IconData _getIconDataForType(String type) {
    if (type == 'Restaurant') return Icons.restaurant;
    if (type == 'Coffee') return Icons.local_cafe;
    if (type == 'Park') return Icons.park;
    if (type == 'Ticket') return Icons.local_activity;
    if (type == 'Airport') return Icons.local_airport;
    if (type == 'Bars') return Icons.local_bar;
    return Icons.location_on;
  }

  Color _getMarkerColor(String type) {
    if (type == 'Restaurant') return const Color(0xFFFF3B30); // Red
    if (type == 'Coffee') return const Color(0xFFFF9500); // Orange
    if (type == 'Park') return const Color(0xFF34C759); // Green
    if (type == 'Ticket') return const Color(0xFFAF52DE); // Purple/Magenta
    if (type == 'Airport') return const Color(0xFF007AFF); // Blue
    if (type == 'Bars') return const Color(0xFF5856D6); // Indigo
    return const Color(0xFF8E8E93); // Grey default
  }

  Future<void> _initMarkerIcons({double zoom = 13.0}) async {
    try {
      final types = ['Coffee', 'Restaurant', 'Park', 'Ticket', 'Airport', 'Bars', 'default'];
      final double scale = (zoom / 13.0).clamp(0.6, 1.8);
      
      for (final type in types) {
        final IconData iconData = _getIconDataForType(type);
        final Color color = _getMarkerColor(type);
        
        // Normal state
        _normalMarkerIcons[type] = await _createCircleIcon(iconData, color, isSelected: false, scale: scale);
        // Selected state (enlarged & glowing)
        _selectedMarkerIcons[type] = await _createCircleIcon(iconData, color, isSelected: true, scale: scale);
        // Heatmap state (always purple)
        _heatmapMarkerIcons[type] = await _createCircleIcon(iconData, const Color(0xFF7C57FC), isSelected: false, scale: scale);
      }

      if (mounted) {
        setState(() {
          _iconsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error creating custom marker icons: $e");
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
        final nameMatches = (place['name'] as String).toLowerCase().contains(query);
        final arMatches = (place['arabicName'] as String).toLowerCase().contains(query);
        if (!nameMatches && !arMatches) return false;
      }

      // 2. Favorite Mode Filter
      if (_selectedMapTab == 3) {
        if (_filterVisited && !place['isVisited']) return false;
        if (_filterSaved && !place['isSaved']) return false;
        if (!_filterVisited && !_filterSaved) {
          // If neither filter is selected, show anything visited or saved
          return place['isVisited'] || place['isSaved'];
        }
        return true;
      }

      // 3. Category Filter
      if (_selectedCategory.isNotEmpty) {
        final type = place['type'] as String;
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

  // Create customized markers
  Set<Marker> _buildMarkers() {
    final filtered = _getFilteredPlaces();
    final Set<Marker> markers = {};

    for (final place in filtered) {
      final isSelected = _selectedPlace != null && _selectedPlace!['id'] == place['id'];
      final type = place['type'] as String;
      
      BitmapDescriptor icon;
      if (_iconsLoaded) {
        if (_selectedMapTab == 2) {
          icon = _heatmapMarkerIcons[type] ?? _heatmapMarkerIcons['default']!;
        } else if (isSelected) {
          icon = _selectedMarkerIcons[type] ?? _selectedMarkerIcons['default']!;
        } else {
          icon = _normalMarkerIcons[type] ?? _normalMarkerIcons['default']!;
        }
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      }

      markers.add(
        Marker(
          markerId: MarkerId(place['id'] as String),
          position: LatLng((place['latitude'] as num? ?? 0.0).toDouble(), (place['longitude'] as num? ?? 0.0).toDouble()),
          icon: icon,
          onTap: () {
            setState(() {
              _selectedPlace = place;
            });
            // Animate map camera to center the tapped place
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

  // Generate heatmap overlay circles
  Set<Circle> _buildHeatmapCircles() {
    if (_selectedMapTab != 2) return {}; // Only for Heatmap mode

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
      
      // Outer glow (faint purple)
      circles.add(Circle(
        circleId: CircleId('${prefix}_outer'),
        center: center,
        radius: 1800,
        fillColor: const Color(0xFF7C57FC).withValues(alpha: 0.04),
        strokeWidth: 0,
      ));
      
      // Mid-outer glow (faint blue/teal)
      circles.add(Circle(
        circleId: CircleId('${prefix}_teal'),
        center: center,
        radius: 1300,
        fillColor: const Color(0xFF00E5FF).withValues(alpha: 0.08),
        strokeWidth: 0,
      ));

      // Mid glow (green)
      circles.add(Circle(
        circleId: CircleId('${prefix}_green'),
        center: center,
        radius: 900,
        fillColor: const Color(0xFF00C853).withValues(alpha: 0.12),
        strokeWidth: 0,
      ));

      // Inner-mid glow (yellow)
      circles.add(Circle(
        circleId: CircleId('${prefix}_yellow'),
        center: center,
        radius: 550,
        fillColor: const Color(0xFFFFA000).withValues(alpha: 0.18),
        strokeWidth: 0,
      ));

      // Core (red)
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


  List<Map<String, dynamic>> _getSuggestions() {
    return _suggestionsResults;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Bottom nav bar height matches BottomNavBar implementation
    final double navBarHeight = 70 + (bottomPadding > 0 ? bottomPadding + 6 : 16);
    
    // Position controls row with a 24px gap above the navigation bar
    final double controlsBottom = navBarHeight + 24;
    
    // Details card and transient status badge position above the controls row
    final double overlaysBottom = controlsBottom + 56 + 12;

    final bool showCategoryResultsMode = _selectedCategory.isNotEmpty || _searchQuery.isNotEmpty || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_isListView) ...[
            // 1. List View of Results
            Positioned.fill(
              child: _buildListView(topPadding, navBarHeight),
            ),
          ] else ...[
            // 2. Google Map Background
            Positioned.fill(
              child: GoogleMap(
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
                    _initMarkerIcons(zoom: position.zoom);
                  }
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationEnabled: _userLocation != null,
                myLocationButtonEnabled: false,
                markers: _buildMarkers(),
                circles: _buildHeatmapCircles(),
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedPlace = null;
                  });
                },
              ),
            ),

            // selected marker details card
            if (_selectedPlace != null)
              IgnorePointer(
                child: Container(
                  color: Colors.transparent,
                ),
              ),

            // Top Header Background Container (Avatar & Search) - Hidden in Heatmap Mode
            if (_selectedMapTab != 2)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: topPadding + 12,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: widget.onBackToTimeline,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: widget.userAvatarUrl != null
                                ? NetworkImage(widget.userAvatarUrl!) as ImageProvider
                                : const AssetImage(
                                    'assets/Timeline/images/element.png',
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Search field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFEAEAEA)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            onSubmitted: (value) async {
                              if (value.trim().isNotEmpty) {
                                setState(() {
                                    _isSearching = true;
                                });
                                final results = await _searchGooglePlaces(value);
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
                              }
                            },
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Find a place",
                              hintStyle: GoogleFonts.ibmPlexSansArabic(
                                color: const Color(0x9A1A1A2E),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                  'assets/explore/search_01.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF82858C),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                                        ),
                                      ),
                                    )
                                  : (_searchQuery.isNotEmpty
                                      ? GestureDetector(
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
                                        )
                                      : null),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Horizontal scrolling categories row below search bar - Hidden in Heatmap Mode
            if (_selectedMapTab != 2)
              Positioned(
                top: topPadding + 80,
                left: 0,
                right: 0,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _selectedMapTab == 3
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildFilterPill(
                                label: "Visited",
                                icon: Icons.history,
                                isActive: _filterVisited,
                                onTap: () {
                                  setState(() {
                                    _filterVisited = !_filterVisited;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildFilterPill(
                                label: "Saved",
                                icon: Icons.bookmark_outline,
                                isActive: _filterSaved,
                                onTap: () {
                                  setState(() {
                                    _filterSaved = !_filterSaved;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView(
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
              ),

            // Search Autocomplete Suggestions Card
            if (_searchQuery.isNotEmpty && _getSuggestions().isNotEmpty)
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
                        itemCount: _getSuggestions().length,
                        itemBuilder: (context, index) {
                          final suggestion = _getSuggestions()[index];
                          return ListTile(
                            leading: Icon(
                              _getIconDataForType(suggestion['type'] as String? ?? 'Other'),
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
                                // Add to places list if not already there, so it has a marker
                                if (!_allPlaces.any((p) => p['id'] == suggestion['id'])) {
                                  _allPlaces.add(suggestion);
                                }
                                _selectedPlace = suggestion;
                                _searchQuery = "";
                                _searchController.text = suggestion['name'] as String;
                                _suggestionsResults = [];
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

            // 3. Selected Marker Details Card
            if (_selectedPlace != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: overlaysBottom,
                child: _buildPlaceCard(_selectedPlace!),
              ),

            // 4. Transient Status Toast Badge
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

            // 5. Map View Controls Row (Current Location, Tab pill, FAB +)
            if (!showCategoryResultsMode)
              Positioned(
                left: 16,
                right: 16,
                bottom: controlsBottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Current Location button
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

                    // Middle: Pill Tab Control
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

                    // Right: FAB (+) Button
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

          // View Toggle Pill (Map / List) - Shown when no place is selected
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
        // 1. Profile Header & Search (Top)
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
              // Profile Picture
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

              // Search Bar
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
                              final results = await _searchGooglePlaces(value);
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

              // Filter Icon
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

        // 2. Category Scroll list
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

        // 3. Results count and List of Places
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
                          // Tapping list item opens place details screen
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
                        child: _buildListPlaceCard(place),
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

  Widget _buildListPlaceCard(Map<String, dynamic> place) {
    final type = place['type'] as String? ?? 'Other';
    final address = place['address'] as String? ?? 'Riyadh, Saudi Arabia';
    final rating = place['rating']?.toString() ?? '4.5';
    final reviewsCount = place['reviewsCount']?.toString() ?? '25';
    final distanceStr = place['distance'] as String? ?? '1.1 km';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8E8E8).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(place['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['name'] as String? ?? '',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type • $address',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xBF3B3C4F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Badges Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Distance
                      _buildCardBadge(
                        icon: Icons.directions_walk,
                        label: distanceStr,
                      ),
                      const SizedBox(width: 6),
                      // Status (Open Now)
                      _buildStatusBadge(isOpen: true),
                      const SizedBox(width: 6),
                      // Rating
                      _buildCardBadge(
                        icon: Icons.star,
                        iconColor: const Color(0xFFFFCC00),
                        label: '$rating ($reviewsCount)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBadge({required IconData icon, required String label, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? const Color(0xFF82858C),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF636268),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required bool isOpen}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF34C759), // Green dot
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "Open Now",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF636268),
            ),
          ),
        ],
      ),
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
          // Map option
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
          // List option
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
          _selectedPlace = null; // Clear place details card
          _isListView = false; // Reset to map view when switching filters
        });

        // Fetch from Google Places centered on current user coordinates
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

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C57FC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? Colors.transparent : const Color(0xFFE8E8E8),
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
              color: isActive ? Colors.white : const Color(0xFF333333),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF333333),
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
          _selectedPlace = null; // Reset selection on tab change
        });
        
        // Trigger status badge
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

  // Bottom card widget details for selected place
  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Image with bookmark
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(place['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          place['isSaved'] = !(place['isSaved'] as bool? ?? false);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (place['isSaved'] as bool? ?? false) ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Right: info columns
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name']?.toString() ?? '',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${place['type']} • ${place['address']}",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: const Color(0xFF82858C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Badges row
                    Row(
                      children: [
                        // Distance Badge
                        _buildCardBadge(
                          icon: Icons.directions_walk,
                          label: place['distance']?.toString() ?? '',
                        ),
                        const SizedBox(width: 6),
                        // Status Badge
                        _buildCardBadge(
                          icon: Icons.circle,
                          iconColor: Colors.green,
                          label: "Open Now",
                        ),
                        const SizedBox(width: 6),
                        // Rating Badge
                        _buildCardBadge(
                          icon: Icons.star,
                          iconColor: Colors.amber,
                          label: "${place['rating']} (${place['reviewsCount']})",
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Visitors list
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 20,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 9,
                                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100'),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 9,
                                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100'),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 24,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDE6FC),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "+${((place['peopleCount'] as num? ?? 12).toInt() - 2)}",
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C57FC),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Maya, Ali and ${((place['peopleCount'] as num? ?? 12).toInt() - 2)} others are here",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: const Color(0xFF82858C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Action Buttons
          Row(
            children: [
              // View Button
              Expanded(
                child: GestureDetector(
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
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFF7C57FC), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility, color: Color(0xFF7C57FC), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "View",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7C57FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Dynamic Action Button (Order, Book, check-in)
              Expanded(
                child: GestureDetector(
                  onTap: () => _handlePlaceAction(place),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C57FC),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getActionIcon(place['actionType'] as String),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          place['actionType'] as String,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    if (actionType == 'Order') return Icons.shopping_bag;
    if (actionType == 'Book') return Icons.calendar_month;
    return Icons.person_add;
  }

  void _handlePlaceAction(Map<String, dynamic> place) {
    final String actionType = place['actionType'] as String;
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
    // Navigate to composer screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(
          isFirstCheckIn: false,
          editPost: null, // Open as new post
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
      // Automatically return to Timeline tab
      widget.onBackToTimeline();
    }
  }

  String _getApiKey() {
    return "AIzaSyBjxRXgMKAxdj8WeeI2VYGEhBA8lxTR5Ug";
  }

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {};
    if (Platform.isAndroid) {
      headers['X-Android-Package'] = 'com.example.moor';
      headers['X-Android-Cert'] = '385558994848088be8e80907b01f5fade2913383';
    } else if (Platform.isIOS) {
      headers['X-Ios-Bundle-Identifier'] = 'com.app.more.premium';
    }
    return headers;
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

    final results = await _searchGooglePlaces(query);

    setState(() {
      _suggestionsResults = results;
      _isSearching = false;
    });
  }

  Future<List<Map<String, dynamic>>> _searchGooglePlaces(String query) async {
    try {
      final lat = _userLocation?.latitude ?? 24.7136;
      final lng = _userLocation?.longitude ?? 46.6753;

      // Try Places API (New) searchText first
      final String apiKey = _getApiKey();
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.types',
        ..._getHeaders(),
      };

      final Map<String, dynamic> body = {
        "textQuery": query,
        "locationBias": {
          "circle": {
            "center": {
              "latitude": lat,
              "longitude": lng
            },
            "radius": 50000.0
          }
        }
      };

      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchText'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['places'] != null) {
          final List<dynamic> results = data['places'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final id = res['id'] as String? ?? UniqueKey().toString();
            final displayNameObj = res['displayName'] as Map<String, dynamic>?;
            final name = displayNameObj?['text'] as String? ?? '';
            final address = res['formattedAddress'] as String? ?? '';
            final locationObj = res['location'] as Map<String, dynamic>?;
            final plat = (locationObj?['latitude'] as num?)?.toDouble() ?? 0.0;
            final plng = (locationObj?['longitude'] as num?)?.toDouble() ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            String type = 'Other';
            if (types.contains('restaurant') || types.contains('food')) {
              type = 'Restaurant';
            } else if (types.contains('cafe')) {
              type = 'Coffee';
            } else if (types.contains('bakery')) {
              type = 'Bakery';
            } else if (types.contains('bar')) {
              type = 'Bars';
            } else if (types.contains('park') || types.contains('tourist_attraction')) {
              type = 'Park';
            } else if (types.contains('airport')) {
              type = 'Airport';
            }

            places.add({
              'id': id,
              'name': name,
              'arabicName': name,
              'address': address,
              'latitude': plat,
              'longitude': plng,
              'distance': distanceStr,
              'rating': 4.5,
              'reviewsCount': 25,
              'price': r'$$',
              'peopleCount': 12,
              'type': type,
              'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500',
              'isSaved': false,
              'isVisited': false,
            });
          }
          return places;
        }
      } else {
        debugPrint("Google Search Places API (New) failed with status ${response.statusCode}: ${response.body}");
      }
      
      // Fallback to Legacy Text Search
      final String legacyUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&location=$lat,$lng'
          '&radius=50000'
          '&key=$apiKey';

      final legacyResponse = await http.get(Uri.parse(legacyUrl), headers: _getHeaders());
      if (legacyResponse.statusCode == 200) {
        final data = json.decode(legacyResponse.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          final List<dynamic> results = data['results'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final id = res['place_id'] as String? ?? UniqueKey().toString();
            final name = res['name'] as String? ?? '';
            final address = res['formatted_address'] as String? ?? '';
            final geometry = res['geometry'] as Map<String, dynamic>?;
            final locObj = geometry?['location'] as Map<String, dynamic>?;
            final plat = (locObj?['lat'] as num?)?.toDouble() ?? 0.0;
            final plng = (locObj?['lng'] as num?)?.toDouble() ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            String type = 'Other';
            if (types.contains('restaurant') || types.contains('food')) {
              type = 'Restaurant';
            } else if (types.contains('cafe')) {
              type = 'Coffee';
            } else if (types.contains('bakery')) {
              type = 'Bakery';
            } else if (types.contains('bar')) {
              type = 'Bars';
            } else if (types.contains('park') || types.contains('tourist_attraction')) {
              type = 'Park';
            } else if (types.contains('airport')) {
              type = 'Airport';
            }

            places.add({
              'id': id,
              'name': name,
              'arabicName': name,
              'address': address,
              'latitude': plat,
              'longitude': plng,
              'distance': distanceStr,
              'rating': 4.5,
              'reviewsCount': 25,
              'price': r'$$',
              'peopleCount': 12,
              'type': type,
              'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500',
              'isSaved': false,
              'isVisited': false,
            });
          }
          return places;
        }
      } else {
        debugPrint("Google Search Places API (Legacy) failed with status ${legacyResponse.statusCode}: ${legacyResponse.body}");
      }
    } catch (e) {
      debugPrint("Error searching Google Places: $e");
    }
    return [];
  }

  Future<void> _fetchNearbyPlaces(double lat, double lng, {String? category}) async {
    try {
      final String apiKey = _getApiKey();
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.types',
        ..._getHeaders(),
      };

      List<String> typesToInclude = [
        "restaurant", "cafe", "bakery", "bar", "park", "tourist_attraction"
      ];
      if (category != null && category.isNotEmpty) {
        if (category == "Restaurant") {
          typesToInclude = ["restaurant"];
        } else if (category == "Coffee") {
          typesToInclude = ["cafe"];
        } else if (category == "Bakery") {
          typesToInclude = ["bakery"];
        } else if (category == "Bars") {
          typesToInclude = ["bar"];
        } else if (category == "Desserts") {
          typesToInclude = ["bakery", "cafe"];
        }
      }

      final Map<String, dynamic> body = {
        "includedTypes": typesToInclude,
        "maxResultCount": 20,
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": lat,
              "longitude": lng
            },
            "radius": 5000.0
          }
        }
      };

      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['places'] != null) {
          final List<dynamic> results = data['places'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final id = res['id'] as String? ?? UniqueKey().toString();
            final displayNameObj = res['displayName'] as Map<String, dynamic>?;
            final name = displayNameObj?['text'] as String? ?? '';
            final address = res['formattedAddress'] as String? ?? '';
            final locationObj = res['location'] as Map<String, dynamic>?;
            final plat = (locationObj?['latitude'] as num?)?.toDouble() ?? 0.0;
            final plng = (locationObj?['longitude'] as num?)?.toDouble() ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            String type = 'Other';
            if (types.contains('restaurant') || types.contains('food')) {
              type = 'Restaurant';
            } else if (types.contains('cafe')) {
              type = 'Coffee';
            } else if (types.contains('bakery')) {
              type = 'Bakery';
            } else if (types.contains('bar')) {
              type = 'Bars';
            } else if (types.contains('park') || types.contains('tourist_attraction')) {
              type = 'Park';
            } else if (types.contains('airport')) {
              type = 'Airport';
            }

            places.add({
              'id': id,
              'name': name,
              'arabicName': name,
              'address': address,
              'latitude': plat,
              'longitude': plng,
              'distance': distanceStr,
              'rating': 4.5,
              'reviewsCount': 25,
              'price': r'$$',
              'peopleCount': 12,
              'type': type,
              'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500',
              'isSaved': false,
              'isVisited': false,
            });
          }
          if (places.isNotEmpty) {
            setState(() {
              _allPlaces.clear();
              _allPlaces.addAll(places);
            });
            _initMarkerIcons(zoom: _lastRoundedZoom.toDouble());
          }
        }
      } else {
        debugPrint("Google Nearby Places API failed with status ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching nearby places on startup: $e");
    }
  }
}
