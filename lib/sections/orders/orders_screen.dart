import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/delivery_address_model.dart';
import 'services/delivery_address_service.dart';
import 'screens/delivery_location_picker_screen.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onExploreTapped;

  const OrdersScreen({
    super.key,
    required this.onExploreTapped,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    DeliveryAddressService.instance.init();
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    HapticFeedback.lightImpact();
    final current = DeliveryAddressService.instance.currentAddress.value;
    await Navigator.push<bool>(
      context,
      CupertinoPageRoute(
        builder: (_) => DeliveryLocationPickerScreen(
          initialLat: current?.latitude,
          initialLng: current?.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ValueListenableBuilder<DeliveryAddressModel?>(
          valueListenable: DeliveryAddressService.instance.currentAddress,
          builder: (context, address, _) {
            return Column(
              children: [
                // Top Header (Matches Screenshot 1)
                _buildTopHeader(context, address, isDark),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Body content:
                // If no address saved -> Out of coverage empty prompt (Screenshot 1)
                // If address saved -> Orders Home with red container as requested
                Expanded(
                  child: address == null
                      ? _buildOutOfCoverageView(context, isDark)
                      : _buildOrdersHomeWithSavedAddress(context, address, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, DeliveryAddressModel? address, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Search Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(
                Icons.search_rounded,
                color: textColor,
                size: 26,
              ),
            ),
          ),

          // Right: Delivery Address Selector (Matches Screenshot 1)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openLocationPicker(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Color(0xFF1E2022),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'التوصيل لـ',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      address != null ? address.title : 'اختر موقعك',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfCoverageView(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Hungerstation-style Vector Signpost & Cactus Illustration
            const _OutOfCoverageIllustration(),

            const SizedBox(height: 28),

            // Main Text (Exact wording from Screenshot 1)
            Text(
              'نعتذر منك، موقعك الحالي خارج نطاق التوصيل لدينا',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E2022),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Primary Purple Button: "اختر موقعًا جديدًا"
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _openLocationPicker(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'اختر موقعًا جديدًا',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersHomeWithSavedAddress(
    BuildContext context,
    DeliveryAddressModel address,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red Container explicitly requested by the user:
          // ("حطلي بس فيها كونتينر لونه أحمر، ماشي؟ إن أنا كده سيفت العنوان، وبعدين هقولك هنغير التصميم إزاي دلوقتي")
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935), // Pure vibrant red container
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'العنوان محفوظ ✓',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'موقع التوصيل الحالي',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  address.title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
                if (address.fullAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
                if (address.details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'التفاصيل: ${address.details}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Change Location Action Button
          OutlinedButton.icon(
            onPressed: () => _openLocationPicker(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit_location_alt_rounded, size: 19, color: Color(0xFF10B981)),
            label: Text(
              'تغيير موقع التوصيل',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Pixel-Perfect Hungerstation-style Out of Coverage Illustration
class _OutOfCoverageIllustration extends StatelessWidget {
  const _OutOfCoverageIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Baseline ground bar
          Positioned(
            bottom: 12,
            left: 15,
            right: 15,
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFFC7CBD1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Left Cactus
          Positioned(
            bottom: 15,
            left: 36,
            child: CustomPaint(
              size: const Size(40, 85),
              painter: _CactusPainter(isLeft: true),
            ),
          ),

          // Right Cactus
          Positioned(
            bottom: 15,
            right: 32,
            child: CustomPaint(
              size: const Size(42, 110),
              painter: _CactusPainter(isLeft: false),
            ),
          ),

          // Center Post / Sign Pole
          Positioned(
            bottom: 15,
            child: Container(
              width: 4,
              height: 145,
              color: const Color(0xFFD1D5DB),
            ),
          ),

          // Signpost Disc
          Positioned(
            top: 6,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB0B7C1), width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 46,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
                ),

                // Red Exclamation Badge (!)
                Positioned(
                  top: 0,
                  right: -4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Front Paper Delivery Bag with "H"
          Positioned(
            bottom: 15,
            child: Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFB0B7C1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'H',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CactusPainter extends CustomPainter {
  final bool isLeft;
  _CactusPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (isLeft) {
      // Main stem
      path.moveTo(size.width * 0.7, size.height);
      path.lineTo(size.width * 0.7, 6);
      // Left branch
      path.moveTo(size.width * 0.7, size.height * 0.65);
      path.lineTo(size.width * 0.15, size.height * 0.65);
      path.lineTo(size.width * 0.15, size.height * 0.3);
    } else {
      // Main stem
      path.moveTo(size.width * 0.25, size.height);
      path.lineTo(size.width * 0.25, 6);
      // Right branch
      path.moveTo(size.width * 0.25, size.height * 0.55);
      path.lineTo(size.width * 0.85, size.height * 0.55);
      path.lineTo(size.width * 0.85, size.height * 0.25);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
