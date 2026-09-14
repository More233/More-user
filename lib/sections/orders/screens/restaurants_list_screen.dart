import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/restaurants_provider.dart';
import '../widgets/restaurant_card_widget.dart';

class RestaurantsListScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? initialCategory;

  const RestaurantsListScreen({
    super.key,
    this.initialSearch,
    this.initialCategory,
  });

  @override
  ConsumerState<RestaurantsListScreen> createState() =>
      _RestaurantsListScreenState();
}

class _RestaurantsListScreenState extends ConsumerState<RestaurantsListScreen> {
  late final TextEditingController _searchController;
  final List<String> _categories = [
    'الكل',
    'المطاعم',
    'البقالة',
    'الصيدليات',
    'المتاجر',
    'الحلويات',
    'مخابز',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    Future.microtask(() {
      if (widget.initialSearch != null) {
        ref.read(restaurantSearchQueryProvider.notifier).state = widget.initialSearch!;
      }
      if (widget.initialCategory != null) {
        ref.read(selectedCategoryFilterProvider.notifier).state = widget.initialCategory!;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final restaurants = ref.watch(filteredRestaurantsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Search Header (Screenshot 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Search Input Capsule
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref.read(restaurantSearchQueryProvider.notifier).state = '';
                              },
                              child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن مطعم أو صنف...',
                                hintStyle: GoogleFonts.ibmPlexSansArabic(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (val) {
                                ref.read(restaurantSearchQueryProvider.notifier).state = val;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.search_rounded, color: Color(0xFF4B5563), size: 22),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Back Button (White circle, black arrow, Screenshot 1)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Promo Banner Pill (Screenshot 1: "توصيل مجاني لطلبك الأول 🛵")
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Soft peach bg
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'توصيل مجاني لطلبك الأول',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('🛵', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),

            // 3. Category Selector Tabs (Screenshot 1: الكل, المطاعم, البقالة, الصيدليات...)
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                  ),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true, // RTL
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = selectedCat == cat;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(selectedCategoryFilterProvider.notifier).state = cat;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFF1E2022) : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? textColor : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Section Title Header ("المطاعم")
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المطاعم',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ),

            // 5. Restaurants List
            Expanded(
              child: restaurants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'لم نتمكن من إيجاد مطاعم مطابقة',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: restaurants.length + 1,
                      itemBuilder: (context, idx) {
                        if (idx == restaurants.length) {
                          // "عرض المزيد من المطاعم" Pill button (Screenshot 1)
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFF1E2022),
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'عرض المزيد من المطاعم',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        }

                        final rest = restaurants[idx];
                        return RestaurantCardWidget(restaurant: rest);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
