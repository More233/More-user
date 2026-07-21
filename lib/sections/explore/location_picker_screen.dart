import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:moor/shared/models/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
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
  String? _avatarUrl;
  bool? _lastIsDark;

  void _fetchUserAvatar() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final profile = await client.from('profiles').select('avatar_url').eq('id', user.id).maybeSingle();
        if (profile != null && mounted) {
          setState(() {
            _avatarUrl = profile['avatar_url'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user avatar: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
    _fetchUserAvatar();
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

  Future<String> _reverseGeocode(double lat, double lng) async {
    final token = const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken);
    final url = Uri.parse("https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$token&limit=1");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final placeName = features[0]['place_name'] as String?;
          if (placeName != null && placeName.isNotEmpty) {
            return placeName;
          }
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
    return "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}";
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_lastIsDark != null && _lastIsDark != isDark) {
      _lastIsDark = isDark;
      if (_mapController != null) {
        final newStyle = isDark
            ? "mapbox://styles/mapbox/navigation-guidance-night-v4"
            : "mapbox://styles/mapbox/streets-v12";
        _mapController!.style.setStyleURI(newStyle);
      }
    } else {
      _lastIsDark = isDark;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Mapbox Map
          Positioned.fill(
            child: mapbox.MapWidget(
              key: const ValueKey('location_picker_map_key'),
              resourceOptions: mapbox.ResourceOptions(accessToken: const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken)),
              styleUri: isDark
                  ? "mapbox://styles/mapbox/navigation-guidance-night-v4"
                  : "mapbox://styles/mapbox/streets-v12",
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(coordinates: mapbox.Position(_currentCenter.longitude, _currentCenter.latitude)).toJson(),
                zoom: 15.0,
              ),
              onMapCreated: (controller) async {
                _mapController = controller;
                await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
                await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
              },
              onStyleLoadedListener: (styleLoaded) async {
                if (_mapController != null) {
                  try {
                    final layers = await _mapController!.style.getStyleLayers();
                    const List<String> hideKeywords = [
                      'poi', 'transit', 'rail', 'bus', 'station', 'ferry', 'shield', 'motorway',
                      'number', 'crossing', 'traffic', 'landmark', 'symbol', 'monument', 'worship',
                      'cemetery', 'lodging', 'hotel', 'restaurant', 'cafe', 'shop', 'food',
                      'beverage', 'intersection', 'entrance', 'parking'
                    ];
                    for (final layerInfo in layers) {
                      if (layerInfo != null) {
                        final idLower = layerInfo.id.toLowerCase();
                        if (idLower.contains('pointannotation') || idLower.contains('annotation')) {
                          continue;
                        }
                        bool shouldHide = false;
                        for (final keyword in hideKeywords) {
                          if (idLower.contains(keyword)) {
                            shouldHide = true;
                            break;
                          }
                        }
                        if (shouldHide) {
                          await _mapController!.style.setStyleLayerProperty(
                            layerInfo.id,
                            'visibility',
                            'none',
                          );
                        }
                      }
                    }
                  } catch (_) {}
                }
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7C57FC), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? (_avatarUrl!.startsWith('http')
                                ? CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.person, color: Color(0xFF82858C)))
                                : Image.asset(_avatarUrl!, fit: BoxFit.cover))
                            : Image.asset(
                                'assets/home/images/avatar_placeholder.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Color(0xFF82858C)),
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
                      child: CupertinoActivityIndicator(
                        color: Color(0xFF7C57FC),
                        radius: 8,
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
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CupertinoActivityIndicator(color: Color(0xFF7C57FC))),
                  );
                  String address;
                  if (_searchController.text.isNotEmpty) {
                    address = _searchController.text;
                  } else {
                    address = await _reverseGeocode(_currentCenter.latitude, _currentCenter.longitude);
                  }
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading dialog
                    Navigator.pop(context, {
                      'latitude': _currentCenter.latitude,
                      'longitude': _currentCenter.longitude,
                      'address': address,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
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
      ..color = const Color(0xFF7C57FC)
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
