import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:moor/shared/models/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/secrets.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _currentCenter;
  mapbox.MapboxMap? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    
    // Simulate geocoding search after 1s
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    setState(() => _isSearching = false);
    
    // If they searched Riyadh, center Riyadh
    if (query.toLowerCase().contains("riyadh")) {
      final target = const LatLng(24.7136, 46.6753);
      _mapController?.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(target.longitude, target.latitude)).toJson(),
          zoom: 14.0,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      setState(() => _currentCenter = target);
    } else if (query.toLowerCase().contains("cairo")) {
      final target = const LatLng(30.0444, 31.2357);
      _mapController?.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(target.longitude, target.latitude)).toJson(),
          zoom: 14.0,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      setState(() => _currentCenter = target);
    } else {
      // Simulate slight offset from current map center
      final target = LatLng(_currentCenter.latitude + 0.01, _currentCenter.longitude + 0.01);
      _mapController?.easeTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(target.longitude, target.latitude)).toJson(),
          zoom: 14.0,
        ),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      setState(() => _currentCenter = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Google Map
          Positioned.fill(
            child: mapbox.MapWidget(
              resourceOptions: mapbox.ResourceOptions(accessToken: const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken)),
              styleUri: "mapbox://styles/basiii/cmri3vcu7007401qr2y7l5bue",
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(coordinates: mapbox.Position(_currentCenter.longitude, _currentCenter.latitude)).toJson(),
                zoom: 15.0,
              ),
              onMapCreated: (controller) async {
                _mapController = controller;
                await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
                await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
              },
              onCameraChangeListener: (event) {
                if (_mapController != null) {
                  _mapController!.getCameraState().then((state) {
                    final centerPoint = mapbox.Point.fromJson(Map<String, dynamic>.from(state.center));
                    setState(() {
                      _currentCenter = LatLng(centerPoint.coordinates.lat.toDouble(), centerPoint.coordinates.lng.toDouble());
                    });
                  });
                }
              },
            ),
          ),

          // Custom stationary selection marker pin in the absolute center of screen
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36.0), // Offset for pin point anchoring
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Black map pin container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F242E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ),
                    // Small pin tail triangle/indicator
                    CustomPaint(
                      size: const Size(12, 8),
                      painter: _PinTailPainter(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top floating search bar container
          Positioned(
            top: topPadding + 16,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _searchAddress,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: "Search for a location...",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF82858C)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC))),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF82858C)),
                      onPressed: () => _searchAddress(_searchController.text),
                    ),
                ],
              ),
            ),
          ),

          // Bottom floating Save button
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Get simulated address name based on coordinates
                  String mockAddress = "Cairo, Cairo 11568, Egypt";
                  if (_searchController.text.isNotEmpty) {
                    mockAddress = _searchController.text;
                  } else {
                    mockAddress = "Lat: ${_currentCenter.latitude.toStringAsFixed(4)}, Lng: ${_currentCenter.longitude.toStringAsFixed(4)}";
                  }
                  Navigator.pop(context, {
                    'latitude': _currentCenter.latitude,
                    'longitude': _currentCenter.longitude,
                    'address': mockAddress,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F242E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  "Save Location",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Floating current location locator button
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition();
                  final target = LatLng(pos.latitude, pos.longitude);
                  _mapController?.easeTo(
                    mapbox.CameraOptions(
                      center: mapbox.Point(coordinates: mapbox.Position(target.longitude, target.latitude)).toJson(),
                      zoom: 15.0,
                    ),
                    mapbox.MapAnimationOptions(duration: 1000),
                  );
                  setState(() => _currentCenter = target);
                } catch (e) {
                  debugPrint("Error locating user: $e");
                }
              },
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location, color: Color(0xFF7C57FC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F242E)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
