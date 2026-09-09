import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/delivery_address_model.dart';
import 'models/delivery_banner_model.dart';
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

  void _showAddressBottomSheet(BuildContext context, DeliveryAddressModel? currentAddress) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? Colors.white70 : const Color(0xFF757575),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Text(
                    'اختر موقع التوصيل',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Saved Addresses List
              ValueListenableBuilder<List<DeliveryAddressModel>>(
                valueListenable: DeliveryAddressService.instance.savedAddresses,
                builder: (context, savedList, _) {
                  if (savedList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 40,
                            color: isDark ? Colors.white30 : const Color(0xFFBDBDBD),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد عناوين محفوظة بعد',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: savedList.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = savedList[index];
                        final isSelected = currentAddress != null &&
                            item.latitude == currentAddress.latitude &&
                            item.longitude == currentAddress.longitude;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            DeliveryAddressService.instance.saveAddress(item);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                  : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9FAFB)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white12 : const Color(0xFFEEEEEE)),
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 22,
                                  )
                                else
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    onPressed: () {
                                      DeliveryAddressService.instance.removeSavedAddress(index);
                                    },
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.fullAddress,
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 12,
                                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: _SleekOutlinePin(
                                      color: Color(0xFF00A651),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Pick New Location on Map Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openLocationPicker(context);
                  },
                  icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                  label: Text(
                    'تحديد موقع جديد على الخريطة',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: ValueListenableBuilder<DeliveryAddressModel?>(
        valueListenable: DeliveryAddressService.instance.currentAddress,
        builder: (context, address, _) {
          final isCovered = address != null && address.isCovered;

          if (!isCovered) {
            // Out of Coverage View with Header
            return Column(
              children: [
                _buildSimpleHeader(context, address, isDark),
                Expanded(
                  child: _buildOutOfCoverageView(context, isDark, address: address),
                ),
              ],
            );
          }

          // Covered View: The ENTIRE top container IS the promotional banner image!
          // Filter button removed. Categories & daily offers removed as requested.
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ValueListenableBuilder<List<DeliveryBannerModel>>(
                  valueListenable: DeliveryAddressService.instance.currentBanners,
                  builder: (context, banners, _) {
                    return _FullBannerHeaderContainer(
                      banners: banners,
                      address: address,
                      onLocationTapped: () => _showAddressBottomSheet(context, address),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Simple header used in Out-of-Coverage state
  Widget _buildSimpleHeader(BuildContext context, DeliveryAddressModel? address, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);
    final displayCity = address?.regionName ?? address?.title ?? 'اختر موقعك';
    final displayStreet = (address != null && address.fullAddress.isNotEmpty)
        ? address.fullAddress
        : 'اضغط لتحديد موقع التوصيل';
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFEF8DC),
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showAddressBottomSheet(context, address),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 19,
                      color: Color(0xFF1E2022),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayCity,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _SleekOutlinePin(
                      color: Color(0xFF00A651),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  displayStreet,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// HungerStation-Style Out of Coverage View
  Widget _buildOutOfCoverageView(
    BuildContext context,
    bool isDark, {
    DeliveryAddressModel? address,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // HungerStation Vector Signpost & Cactus Illustration
            const _OutOfCoverageIllustration(),

            const SizedBox(height: 26),

            // Main Out of Coverage Text
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

            if (address != null && address.fullAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'الموقع المحدد: ${address.fullAddress}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Dynamically show covered active regions from Dashboard
            ValueListenableBuilder(
              valueListenable: DeliveryAddressService.instance.activeRegions,
              builder: (context, regions, _) {
                if (regions.isEmpty) return const SizedBox.shrink();
                final names = regions.map((r) => r.name).join('، ');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'المناطق المغطاة حالياً: $names',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C57FC),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Primary CTA: "اختر موقعًا جديدًا"
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
}

/// Custom sleek outline location pin (clean, delicate, 1.6px stroke, green)
class _SleekOutlinePin extends StatelessWidget {
  final Color color;
  final double size;

  const _SleekOutlinePin({
    this.color = const Color(0xFF00A651),
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.25),
      painter: _OutlinePinPainter(color: color),
    );
  }
}

class _OutlinePinPainter extends CustomPainter {
  final Color color;
  _OutlinePinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const strokeWidth = 1.6;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = w / 2;
    final path = Path();
    // Teardrop outline
    path.moveTo(r, h);
    path.cubicTo(w * 0.15, h * 0.65, 0, h * 0.45, 0, r);
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.cubicTo(w, h * 0.45, w * 0.85, h * 0.65, r, h);
    path.close();
    canvas.drawPath(path, paint);

    // Inner hollow dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(Offset(r, r), r * 0.35, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full Banner Container where the ENTIRE container IS the promotional image,
/// with bottom-left and bottom-right 16px corner radius, floating location header,
/// floating search bar, and dynamic indicator dots at the bottom.
class _FullBannerHeaderContainer extends StatefulWidget {
  final List<DeliveryBannerModel> banners;
  final DeliveryAddressModel? address;
  final VoidCallback onLocationTapped;

  const _FullBannerHeaderContainer({
    required this.banners,
    required this.address,
    required this.onLocationTapped,
  });

  @override
  State<_FullBannerHeaderContainer> createState() => _FullBannerHeaderContainerState();
}

class _FullBannerHeaderContainerState extends State<_FullBannerHeaderContainer> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  static const List<Map<String, String>> _fallbackBanners = [
    {
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80',
    },
    {
      'image': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=1200&q=80',
    },
    {
      'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&q=80',
    },
    {
      'image': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=1200&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final total = widget.banners.isNotEmpty ? widget.banners.length : _fallbackBanners.length;
      if (total <= 1 || !_pageController.hasClients) return;
      final next = (_currentIndex + 1) % total;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRealBanners = widget.banners.isNotEmpty;
    final total = hasRealBanners ? widget.banners.length : _fallbackBanners.length;

    final displayCity = widget.address?.regionName ?? widget.address?.title ?? 'الرياض';
    final displayStreet = (widget.address != null && widget.address!.fullAddress.isNotEmpty)
        ? widget.address!.fullAddress
        : 'البطحاء 6343، الرياض، السعودية';

    final topPadding = MediaQuery.of(context).padding.top;
    final totalContainerHeight = topPadding + 280.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Container(
        height: totalContainerHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF8DC),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Sliding Banners Background (The entire frame IS the image, covering status bar)
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final imageUrl = hasRealBanners
                    ? widget.banners[index].imageUrl
                    : _fallbackBanners[index]['image']!;

                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: const Color(0xFFFEF8DC),
                  ),
                );
              },
            ),

            // 2. Soft translucent overlay to ensure the header and search bar are perfectly legible
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPadding + 110,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFEF8DC).withValues(alpha: 0.95),
                      const Color(0xFFFEF8DC).withValues(alpha: 0.85),
                      const Color(0xFFFEF8DC).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Header & Floating Search Bar Layer (Positioned right below status bar)
            Positioned(
              top: topPadding + 6,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location Header (Filter button removed! Right aligned)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onLocationTapped,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 19,
                                    color: Color(0xFF1E2022),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayCity,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E2022),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const _SleekOutlinePin(
                                    color: Color(0xFF00A651),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1.5),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width - 40,
                                ),
                                child: Text(
                                  displayStreet,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Floating White Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
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
                          Expanded(
                            child: Text(
                              'ابحث عن المطاعم والمتاجر',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: Color(0xFF4B5563),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Floating Indicator Dots Overlay at Bottom Center ("الدوائر الصغيرة اللي بتعرف في كام اعلان")
            if (total > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(total, (i) {
                        final isCurrent = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: isCurrent ? 14 : 5.5,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF1E2022) : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                  child: const Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 46,
                      color: Color(0xFFD1D5DB),
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
