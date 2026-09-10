import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_section_model.dart';

class FeaturedMealsWidget extends StatelessWidget {
  final HomeSectionModel section;
  final Function(HomeSectionItemModel item)? onItemTapped;
  final Function(HomeSectionItemModel item)? onAddToCart;
  final VoidCallback? onViewAllTapped;

  const FeaturedMealsWidget({
    super.key,
    required this.section,
    this.onItemTapped,
    this.onAddToCart,
    this.onViewAllTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<HomeSectionItemModel>.from(section.items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (items.isEmpty) return const SizedBox.shrink();

    final hasCustomBanner = section.bannerImageUrl != null &&
        section.bannerImageUrl!.isNotEmpty &&
        section.bannerImageUrl!.startsWith('http') &&
        !section.bannerImageUrl!.contains('unsplash.com/photo-1562967914');

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFDE8ED),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Promotional Meals Image Banner with Top Rounded Corners (12)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onViewAllTapped?.call();
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: hasCustomBanner
                          ? Image.network(
                              section.bannerImageUrl!,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Image.asset(
                                'assets/home/images/meals_banner_default.png',
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/home/images/meals_banner_default.png',
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                    ),

                    // Action Button on the Left (Arrow tap target)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onViewAllTapped?.call();
                        },
                        child: hasCustomBanner
                            ? Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                    color: Color(0xFF1E2022),
                                  ),
                                ),
                              )
                            : const SizedBox(width: 44, height: 44),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Horizontal Meal Cards List
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  height: 228,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // RTL
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final meal = items[index];
                      return _buildMealCard(context, meal);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, HomeSectionItemModel meal) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onItemTapped?.call(meal);
      },
      child: Container(
        width: 152,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Meal Image Container
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: Image.network(
                      meal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.fastfood_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Top Left Brand Logo or Yellow Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lunch_dining_rounded,
                        size: 15,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                  ),
                ),

                // Top Right: Optional "إعلان" Badge
                if (meal.badgeText != null && meal.badgeText!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meal.badgeText!,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Bottom Left: Plus (+) Button for Quick Add
                Positioned(
                  bottom: -14,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAddToCart?.call(meal);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Text Info Container
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Title
                  Text(
                    meal.title,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2022),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),

                  // Delivery info: 30 دقائق | مجاني
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'مجاني',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.delivery_dining_rounded,
                        size: 13,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        meal.subtitle ?? '30 دقيقة',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price Row: 29 ر.س (red) + 41.43 ر.س (line-through)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (meal.oldPrice != null) ...[
                        Text(
                          '${meal.oldPrice} ﷼',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (meal.price != null)
                        Text(
                          '${meal.price} ﷼',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFF2D55),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
