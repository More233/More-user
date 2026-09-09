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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);
    DeliveryAddressService.instance.init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFF10B981),
                                    size: 20,
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

          return Column(
            children: [
              // Top Header with Location Selector (HungerStation Style)
              _buildTopLocationHeader(context, address, isDark),

              // Main Body:
              // If not covered -> Out of coverage view
              // If covered -> Full HungerStation Experience with Banners, Search, Categories, Offers
              Expanded(
                child: isCovered
                    ? _buildCoveredHomeContent(context, address, isDark)
                    : _buildOutOfCoverageView(context, isDark, address: address),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Top Location Header matching HungerStation Screenshot
  Widget _buildTopLocationHeader(BuildContext context, DeliveryAddressModel? address, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);
    final displayCity = address?.regionName ?? address?.title ?? 'اختر موقعك';
    final displayStreet = (address != null && address.fullAddress.isNotEmpty)
        ? address.fullAddress
        : 'اضغط هنا لتحديد موقع التوصيل الحالي';

    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFEF8DC),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Notification or Cart or subtle brand
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openLocationPicker(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 19,
                color: Color(0xFF4B5563),
              ),
            ),
          ),

          // Right side: Location Selector (Outline Pin, City Name, Chevron, Subtitle)
          Flexible(
            child: GestureDetector(
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
                        size: 20,
                        color: Color(0xFF1E2022),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          displayCity,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Green Outline Pin Icon
                      const Icon(
                        Icons.location_on_outlined,
                        size: 21,
                        color: Color(0xFF00A651), // Vibrant HungerStation emerald green
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
          ),
        ],
      ),
    );
  }

  /// Covered Home View (Search Bar, Banners Carousel with Dots, Categories Grid, Daily Offers)
  Widget _buildCoveredHomeContent(
    BuildContext context,
    DeliveryAddressModel address,
    bool isDark,
  ) {
    return SingleChildScrollView(
      key: const PageStorageKey('orders_home_content_scroll_v1'),
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Warm Section holding the Search Bar & Banners Carousel
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFEF8DC),
            child: Column(
              children: [
                const SizedBox(height: 6),

                // Floating Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Promotional Banners Carousel with Page Dots
                ValueListenableBuilder<List<DeliveryBannerModel>>(
                  valueListenable: DeliveryAddressService.instance.currentBanners,
                  builder: (context, banners, _) {
                    return _BannersCarouselWidget(banners: banners);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // White Main Body (Categories + Offers)
          Container(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // "وش ودك تطلب اليوم؟" Title
                Text(
                  'وش ودك تطلب اليوم؟',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E2022),
                  ),
                ),

                const SizedBox(height: 16),

                // 8 Categories in 2 Rows of 4 Cards
                _buildCategoriesGrid(isDark),

                const SizedBox(height: 28),

                // "العروض اليومية" Header
                Text(
                  'العروض اليومية',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E2022),
                  ),
                ),

                const SizedBox(height: 14),

                // Horizontal Offers Cards
                _buildDailyOffersHorizontalList(isDark),

                // Extra padding for liquid glass bottom nav
                const SizedBox(height: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Categories 2x4 Grid matching HungerStation screenshot
  Widget _buildCategoriesGrid(bool isDark) {
    final categories = [
      // Row 1
      _CategoryItem(
        title: 'مطاعم',
        badgeText: '+50,000',
        badgeColor: const Color(0xFFFFD600),
        badgeTextColor: Colors.black,
        icon: Icons.lunch_dining_rounded,
        iconColor: const Color(0xFFE65100),
      ),
      _CategoryItem(
        title: 'H ماركت',
        badgeText: '20 دقيقة',
        badgeColor: const Color(0xFFFFD600),
        badgeTextColor: Colors.black,
        icon: Icons.storefront_rounded,
        iconColor: const Color(0xFF00C853),
      ),
      _CategoryItem(
        title: 'مقاضي',
        icon: Icons.shopping_basket_rounded,
        iconColor: const Color(0xFF0288D1),
      ),
      _CategoryItem(
        title: 'استلم بنفسك',
        badgeText: 'خصم حتى 30%',
        badgeColor: const Color(0xFFE53935),
        badgeTextColor: Colors.white,
        icon: Icons.shopping_bag_rounded,
        iconColor: const Color(0xFFFFB300),
      ),

      // Row 2
      _CategoryItem(
        title: 'قهوة وحلى',
        icon: Icons.local_cafe_rounded,
        iconColor: const Color(0xFF6D4C41),
      ),
      _CategoryItem(
        title: 'صيدليات',
        icon: Icons.medication_rounded,
        iconColor: const Color(0xFF00ACC1),
      ),
      _CategoryItem(
        title: 'ورود وأكثر',
        icon: Icons.local_florist_rounded,
        iconColor: const Color(0xFFE91E63),
      ),
      _CategoryItem(
        title: 'هدايا',
        badgeText: 'خصم 30%',
        badgeColor: const Color(0xFFE53935),
        badgeTextColor: Colors.white,
        icon: Icons.card_giftcard_rounded,
        iconColor: const Color(0xFF7C4DFF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildCategoryCard(cat, isDark);
      },
    );
  }

  Widget _buildCategoryCard(_CategoryItem cat, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Column(
        children: [
          // Rounded icon container with optional floating badge
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFEDEDED),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      cat.icon,
                      size: 34,
                      color: cat.iconColor,
                    ),
                  ),
                ),

                // Floating Top/Bottom Badge (e.g. +50,000, 20 دقيقة, خصم 30%)
                if (cat.badgeText != null)
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cat.badgeColor ?? const Color(0xFFFFD600),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        cat.badgeText!,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: cat.badgeTextColor ?? Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cat.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E2022),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Daily Offers Horizontal Carousel
  Widget _buildDailyOffersHorizontalList(bool isDark) {
    final offers = [
      {
        'title': 'حلى الصيف',
        'subtitle': 'كيك وآيسكريم',
        'gradient': [const Color(0xFF00BCD4), const Color(0xFF009688)],
        'icon': Icons.icecream_rounded,
      },
      {
        'title': 'أجواء الصيف',
        'subtitle': 'انتعاش بلا حدود',
        'gradient': [const Color(0xFF29B6F6), const Color(0xFF0288D1)],
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'title': 'قهوة الصباح',
        'subtitle': 'ابدأ يومك بنشاط',
        'gradient': [const Color(0xFF8D6E63), const Color(0xFF5D4037)],
        'icon': Icons.coffee_rounded,
      },
      {
        'title': 'عروض مميزة',
        'subtitle': 'خصم حتى 50%',
        'gradient': [const Color(0xFFFF7043), const Color(0xFFD84315)],
        'icon': Icons.local_fire_department_rounded,
      },
    ];

    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL order
        itemCount: offers.length,
        separatorBuilder: (c, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = offers[index];
          final gradientColors = item['gradient'] as List<Color>;

          return Container(
            width: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['subtitle'] as String,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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

/// Helper model for category items
class _CategoryItem {
  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final IconData icon;
  final Color iconColor;

  _CategoryItem({
    required this.title,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.icon,
    required this.iconColor,
  });
}

/// Auto-sliding and swipeable Banners Carousel with Bottom-Center Dots Indicator
class _BannersCarouselWidget extends StatefulWidget {
  final List<DeliveryBannerModel> banners;

  const _BannersCarouselWidget({required this.banners});

  @override
  State<_BannersCarouselWidget> createState() => _BannersCarouselWidgetState();
}

class _BannersCarouselWidgetState extends State<_BannersCarouselWidget> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  // Curated HungerStation-style fallback banners if none yet uploaded in Dashboard
  static const List<Map<String, String>> _fallbackBanners = [
    {
      'title': 'صيدلية الدواء الحين في هنجرستيشن',
      'subtitle': 'اطلب الحين مع خصم حتى 70%',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80',
    },
    {
      'title': 'عروض الصيف الكبرى على جميع المطاعم',
      'subtitle': 'توصيل مجاني وسريع لباب بيتك',
      'image': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=1200&q=80',
    },
    {
      'title': 'ألذ وجبات ومشروبات القهوة والحلى',
      'subtitle': 'خصم خاص 30% على أول طلبين',
      'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1200&q=80',
    },
    {
      'title': 'مقاضي الأسبوع الطازجة من H ماركت',
      'subtitle': 'توصيل سريع خلال 20 دقيقة',
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

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final String imageUrl = hasRealBanners
                      ? widget.banners[index].imageUrl
                      : _fallbackBanners[index]['image']!;
                  final String title = hasRealBanners
                      ? (widget.banners[index].title ?? '')
                      : _fallbackBanners[index]['title']!;
                  final String? subtitle = hasRealBanners
                      ? null
                      : _fallbackBanners[index]['subtitle'];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Network banner image
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: const Color(0xFFFFE082),
                              child: const Center(
                                child: Icon(Icons.fastfood_rounded, size: 48, color: Colors.black45),
                              ),
                            ),
                          ),

                          // Subtle gradient overlay for text legibility
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.65),
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),

                          // Banner Title & Subtitle text
                          Positioned(
                            bottom: 24,
                            right: 16,
                            left: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Dynamic Indicator Dots Overlay ("الدوائر الصغيرة اللي بتعرف في كام اعلان")
              if (total > 1)
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
            ],
          ),
        ),
      ],
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
