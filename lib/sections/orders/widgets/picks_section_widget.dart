import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_section_model.dart';

class PicksSectionWidget extends StatelessWidget {
  final HomeSectionModel section;
  final Function(HomeSectionItemModel item)? onItemTapped;

  const PicksSectionWidget({
    super.key,
    required this.section,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = section.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              section.title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2022),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Picks Cards List
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildPickCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickCard(BuildContext context, HomeSectionItemModel item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onItemTapped?.call(item);
      },
      child: Container(
        width: 285,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            // Cover Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: AspectRatio(
                    aspectRatio: 2.1,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.restaurant_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Top Left: Favorite Heart + Rating Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heart Icon
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: 17,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Rating Pill
                      if (item.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${item.rating} ${item.ratingCount != null ? '(${item.ratingCount})' : ''}',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E2022),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Top Right: Store Logo Square Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Center(
                      child: Text(
                        item.title.substring(0, item.title.length > 2 ? 2 : item.title.length),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Title + H+ Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (item.badgeText == 'H+')
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'H+',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Text(
                        item.title,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2022),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Subtitle / Cuisine
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  const SizedBox(height: 6),

                  // Delivery Time & Fee Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        item.price != null && item.price! > 0 ? '${item.price} ﷼' : 'مجاني',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.delivery_dining_rounded,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '35 - 50 د',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ],
                  ),

                  // Special Promo Pill Tag (e.g. توصيل مجاني وقسيمة بـ 10 ريال)
                  if (item.promoText != null && item.promoText!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.promoText!,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.card_giftcard_rounded,
                            size: 14,
                            color: Color(0xFFE65100),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
