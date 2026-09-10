import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/delivery_address_model.dart';
import 'models/delivery_banner_model.dart';
import 'models/home_section_model.dart';
import 'providers/delivery_orders_provider.dart';
import 'providers/home_sections_provider.dart';
import 'services/delivery_address_service.dart';
import 'screens/delivery_location_picker_screen.dart';

import 'widgets/categories_grid_widget.dart';
import 'widgets/daily_offers_widget.dart';
import 'widgets/featured_meals_widget.dart';
import 'widgets/picks_section_widget.dart';
import 'widgets/cuisines_section_widget.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback onExploreTapped;

  const OrdersScreen({
    super.key,
    required this.onExploreTapped,
  });

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _showFarLocationNotice = true;

  @override
  void initState() {
    super.initState();
    DeliveryAddressService.instance.init();

    _scrollController.addListener(() {
      final scrolled = _scrollController.hasClients && _scrollController.offset > 80;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    HapticFeedback.lightImpact();
    final current = ref.read(currentAddressProvider);
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
        return Consumer(
          builder: (context, ref, _) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1E2022);
            final savedList = ref.watch(savedAddressesProvider);
            final current = ref.watch(currentAddressProvider);

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
                  if (savedList.isEmpty)
                    Padding(
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
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: savedList.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = savedList[index];
                          final isSelected = current != null &&
                              item.latitude == current.latitude &&
                              item.longitude == current.longitude;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(currentAddressProvider.notifier).setAddress(item);
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
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCovered = ref.watch(isCoveredProvider);
    final currentAddress = ref.watch(currentAddressProvider);
    final bannersAsync = ref.watch(deliveryBannersStreamProvider);
    final banners = bannersAsync.value ?? [];

    final sectionsAsync = ref.watch(homeSectionsStreamProvider);
    final sections = sectionsAsync.value ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: !isCovered
          ? Column(
              children: [
                _buildSimpleHeader(context, currentAddress, isDark),
                Expanded(
                  child: _buildOutOfCoverageView(context, isDark, address: currentAddress),
                ),
              ],
            )
          : Stack(
              children: [
                // 1. Main Scrollable View with all sections
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 100 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Yellow Promotional Header + Carousel
                      _TopPromotionalBannerHeader(
                        banners: banners,
                        address: currentAddress,
                        showNotice: _showFarLocationNotice,
                        onDismissNotice: () {
                          setState(() {
                            _showFarLocationNotice = false;
                          });
                        },
                        onLocationTapped: () => _showAddressBottomSheet(context, currentAddress),
                      ),

                      // Section 1: "وش ودك تطلب اليوم؟"
                      if (_findSection(sections, 'categories') != null)
                        CategoriesGridWidget(
                          section: _findSection(sections, 'categories')!,
                          onItemTapped: (item) {
                            HapticFeedback.lightImpact();
                          },
                        ),

                      // Section 2: "العروض اليومية"
                      if (_findSection(sections, 'daily_offers') != null)
                        DailyOffersWidget(
                          section: _findSection(sections, 'daily_offers')!,
                          onItemTapped: (item) {
                            HapticFeedback.lightImpact();
                          },
                        ),

                      // Section 3: "وجبات ابتداءً من 19 ريال"
                      if (_findSection(sections, 'featured_meals') != null)
                        FeaturedMealsWidget(
                          section: _findSection(sections, 'featured_meals')!,
                          onItemTapped: (meal) {
                            HapticFeedback.lightImpact();
                          },
                          onAddToCart: (meal) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تمت إضافة ${meal.title} إلى السلة بنجاح',
                                  style: GoogleFonts.ibmPlexSansArabic(),
                                  textAlign: TextAlign.right,
                                ),
                                backgroundColor: const Color(0xFF1E2022),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),

                      // Section 4: "مختارات"
                      if (_findSection(sections, 'picks') != null)
                        PicksSectionWidget(
                          section: _findSection(sections, 'picks')!,
                          onItemTapped: (pick) {
                            HapticFeedback.lightImpact();
                          },
                        ),

                      // Section 5: "استكشف المطابخ"
                      if (_findSection(sections, 'cuisines') != null)
                        CuisinesSectionWidget(
                          section: _findSection(sections, 'cuisines')!,
                          onItemTapped: (cuisine) {
                            HapticFeedback.lightImpact();
                          },
                        ),
                    ],
                  ),
                ),

                // 2. Sticky Pinned Header (Active upon scrolling down past 80px)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  top: _isScrolled ? 0 : -(topPadding + 70),
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(16, topPadding + 6, 16, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.06),
                          width: 1,
                        ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Search Icon Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: Color(0xFF1E2022),
                              ),
                            ),
                          ),
                        ),

                        // Right: Location Header (Crisp, High Contrast, No Blur)
                        GestureDetector(
                          onTap: () => _showAddressBottomSheet(context, currentAddress),
                          behavior: HitTestBehavior.opaque,
                          child: _buildCrispLocationText(currentAddress, isDark: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  HomeSectionModel? _findSection(List<HomeSectionModel> sections, String key) {
    try {
      return sections.firstWhere((s) => s.sectionKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Out of coverage simple header
  Widget _buildSimpleHeader(BuildContext context, DeliveryAddressModel? address, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showAddressBottomSheet(context, address),
            child: _buildCrispLocationText(address, isDark: isDark),
          ),
        ],
      ),
    );
  }

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
            const _OutOfCoverageIllustration(),
            const SizedBox(height: 26),
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

            Consumer(
              builder: (context, ref, _) {
                final regionsAsync = ref.watch(activeRegionsStreamProvider);
                final regions = regionsAsync.value ?? [];
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

  static Widget _buildCrispLocationText(DeliveryAddressModel? address, {required bool isDark}) {
    final displayCity = address?.regionName ?? address?.title ?? 'Ar Riyadh';
    final displayStreet = (address != null && address.fullAddress.isNotEmpty)
        ? address.fullAddress
        : 'زين العابدين علي، Al Riyadh, Jeddah 2383...';

    return Column(
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
                color: isDark ? Colors.white : const Color(0xFF1E2022),
              ),
            ),
            const SizedBox(width: 6),
            const _SleekOutlinePin(
              color: Color(0xFF00A651),
              size: 13,
            ),
          ],
        ),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            displayStreet,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// The Top Promotional Banner & Header
/// Yellow top background + Location + Notice Speech Bubble + Search Bar + Sliding Banner
class _TopPromotionalBannerHeader extends ConsumerStatefulWidget {
  final List<DeliveryBannerModel> banners;
  final DeliveryAddressModel? address;
  final bool showNotice;
  final VoidCallback onDismissNotice;
  final VoidCallback onLocationTapped;

  const _TopPromotionalBannerHeader({
    required this.banners,
    required this.address,
    required this.showNotice,
    required this.onDismissNotice,
    required this.onLocationTapped,
  });

  @override
  ConsumerState<_TopPromotionalBannerHeader> createState() => _TopPromotionalBannerHeaderState();
}

class _TopPromotionalBannerHeaderState extends ConsumerState<_TopPromotionalBannerHeader> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;

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
      final current = ref.read(bannerCarouselIndexProvider);
      final next = (current + 1) % total;
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
    final topPadding = MediaQuery.of(context).padding.top;
    final hasRealBanners = widget.banners.isNotEmpty;
    final total = hasRealBanners ? widget.banners.length : _fallbackBanners.length;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFE600), // HungerStation signature yellow
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topPadding + 6),

          // 1. Top Location Header (Right Aligned, Pure Crisp Black Font, No Blur)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onLocationTapped,
                  child: _OrdersScreenState._buildCrispLocationText(widget.address, isDark: false),
                ),
              ],
            ),
          ),

          // 2. Far location blue speech-bubble notification (if visible)
          if (widget.showNotice) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  // Little upward triangle pointer
                  Positioned(
                    top: -6,
                    right: 28,
                    child: CustomPaint(
                      size: const Size(12, 6),
                      painter: _TrianglePainter(color: const Color(0xFF007AFF)),
                    ),
                  ),

                  // Speech bubble
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: widget.onDismissNotice,
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'هل عنوان التوصيل صحيح؟ يبدو الموقع بعيدًا عنك',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 3. Floating White Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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

          const SizedBox(height: 14),

          // 4. Sliding Banner Carousel
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (index) {
                    ref.read(bannerCarouselIndexProvider.notifier).state = index;
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = hasRealBanners
                        ? widget.banners[index].imageUrl
                        : _fallbackBanners[index]['image']!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: const Color(0xFFF3F4F6),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Pure Dot Indicators
                _BannerDotsIndicator(total: total),
              ],
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Upward pointer triangle for speech bubble
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Banner pure dot indicator
class _BannerDotsIndicator extends ConsumerWidget {
  final int total;
  const _BannerDotsIndicator({required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (total <= 1) return const SizedBox.shrink();
    final currentIndex = ref.watch(bannerCarouselIndexProvider);

    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (i) {
              final isCurrent = i == (currentIndex % total);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 5.5,
                height: 5.5,
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFF1E2022) : const Color(0xFFD1D5DB),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Custom sleek outline location pin
class _SleekOutlinePin extends StatelessWidget {
  final Color color;
  final double size;

  const _SleekOutlinePin({
    this.color = const Color(0xFF00A651),
    this.size = 13,
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
    const strokeWidth = 1.35;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final r = w / 2;
    final path = Path();
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

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(Offset(r, r), r * 0.35, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
          Positioned(
            bottom: 15,
            child: Container(
              width: 4,
              height: 145,
              color: const Color(0xFFD1D5DB),
            ),
          ),
          Positioned(
            top: 6,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB0B7C1), width: 3.5),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on_rounded,
                  size: 46,
                  color: Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            child: Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFB0B7C1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Center(
                child: Text(
                  'H',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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
