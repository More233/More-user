import 'dart:async';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import '../services/delivery_address_service.dart';
import 'address_search_screen.dart';
import 'delivery_address_details_screen.dart';

class DeliveryLocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const DeliveryLocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<DeliveryLocationPickerScreen> createState() => _DeliveryLocationPickerScreenState();
}

class _DeliveryLocationPickerScreenState extends State<DeliveryLocationPickerScreen> {
  mapbox.MapboxMap? _mapController;
  late double _currentLat;
  late double _currentLng;

  String _placeTitle = 'جاري تحديد الموقع...';
  String _fullAddress = '';
  bool _isCovered = true;
  bool _isLoadingAddress = true;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Default to provided coords or Riyadh (Saudi Arabia)
    _currentLat = widget.initialLat ?? 24.7136;
    _currentLng = widget.initialLng ?? 46.6753;
    _fetchAddress(_currentLat, _currentLng);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    setState(() => _isLoadingAddress = true);
    try {
      final res = await DeliveryAddressService.instance.reverseGeocode(lat, lng);
      if (mounted) {
        setState(() {
          _placeTitle = res.title;
          _fullAddress = res.fullAddress;
          _isCovered = res.isCovered;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (_mapController == null) return;
      final state = await _mapController!.getCameraState();
      final lat = state.center.coordinates.lat.toDouble();
      final lng = state.center.coordinates.lng.toDouble();
      _currentLat = lat;
      _currentLng = lng;
      _fetchAddress(lat, lng);
    });
  }

  Future<void> _moveToLocation(double lat, double lng, {double zoom = 15.5}) async {
    _currentLat = lat;
    _currentLng = lng;
    await _mapController?.easeTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
        zoom: zoom,
      ),
      mapbox.MapAnimationOptions(duration: 900),
    );
    _fetchAddress(lat, lng);
  }

  Future<void> _goToCurrentLocation() async {
    HapticFeedback.lightImpact();
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        _moveToLocation(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('Error fetching current position: $e');
    }
  }

  Future<void> _openSearchScreen() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      CupertinoPageRoute(
        builder: (_) => AddressSearchScreen(
          userLat: _currentLat,
          userLng: _currentLng,
        ),
      ),
    );

    if (result != null && mounted) {
      final lat = result['latitude'] as double;
      final lng = result['longitude'] as double;
      _moveToLocation(lat, lng);
    }
  }

  Future<void> _confirmLocation() async {
    HapticFeedback.mediumImpact();
    final saved = await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (_) => DeliveryAddressDetailsScreen(
          title: _placeTitle,
          fullAddress: _fullAddress,
          latitude: _currentLat,
          longitude: _currentLng,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Map View
          Positioned.fill(
            child: mapbox.MapWidget(
              styleUri: isDark ? mapbox.MapboxStyles.DARK : "mapbox://styles/mapbox/streets-v12",
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(coordinates: mapbox.Position(_currentLng, _currentLat)),
                zoom: 15.0,
              ),
              onMapCreated: (controller) async {
                _mapController = controller;
                await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
                await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
              },
              onCameraChangeListener: (_) => _onCameraIdle(),
            ),
          ),

          // 2. Fixed Center Pin (Matches Reference: Hollow black circle + vertical stem, no fill)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 44.0),
                  child: CustomPaint(
                    size: const Size(28, 44),
                    painter: const _HollowDeliveryPinPainter(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Header Bar (Navbar: Title + Liquid Glass Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Balance circular back button
                      Text(
                        'اختر موقع التوصيل',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      // Liquid Glass Back Button
                      CNButton.icon(
                        icon: const CNSymbol('arrow.forward', size: 18),
                        style: CNButtonStyle.glass,
                        size: 42,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ],

                  ),
                ),
              ),
            ),
          ),

          // 4. Floating Search Bar Over The Map (Increased spacing to breathe over map)
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            left: 16,
            right: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openSearchScreen,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ابحث عن عنوان',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14.5,
                          color: const Color(0xFF9E9E9E),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1E2022),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Floating GPS / My Location Button (Bottom Left)
          Positioned(
            bottom: 230,
            left: 16,
            child: GestureDetector(
              onTap: _goToCurrentLocation,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF424242),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // 5. Bottom Sheet Card (Matches Screenshot 2 & Screenshot 4)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'موقع التوصيل',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),

                    if (_isLoadingAddress)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CupertinoActivityIndicator(),
                      )
                    else ...[
                      Text(
                        _placeTitle,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      if (_fullAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _fullAddress,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            color: const Color(0xFF616161),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],

                    const SizedBox(height: 16),

                    // Action Button (Purple if covered, Grey if not covered)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isCovered && !_isLoadingAddress) ? _confirmLocation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCovered
                              ? const Color(0xFF7C57FC)
                              : const Color(0xFFE5E7EB),
                          foregroundColor: _isCovered ? Colors.white : const Color(0xFF9CA3AF),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          disabledForegroundColor: const Color(0xFF9CA3AF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isCovered ? 'تأكيد الموقع' : 'المنطقة غير مغطاة',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _isCovered
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HollowDeliveryPinPainter extends CustomPainter {
  final Color color;

  const _HollowDeliveryPinPainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.5;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, radius + strokeWidth / 2);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the hollow / open circle (see-through center)
    canvas.drawCircle(center, radius, strokePaint);

    // Draw the vertical stem pointing straight down to map center
    canvas.drawLine(
      Offset(size.width / 2, center.dy + radius),
      Offset(size.width / 2, size.height - 1.5),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HollowDeliveryPinPainter oldDelegate) =>
      color != oldDelegate.color;
}
