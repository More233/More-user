import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_section_model.dart';

class CuisinesSectionWidget extends StatelessWidget {
  final HomeSectionModel section;
  final Function(HomeSectionItemModel item)? onItemTapped;

  const CuisinesSectionWidget({
    super.key,
    required this.section,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<HomeSectionItemModel>.from(section.items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 30),
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
          const SizedBox(height: 14),

          // Horizontal Circular Cuisines List
          SizedBox(
            height: 115,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onItemTapped?.call(item);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pure Image - No white background, no border, no shadow
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cuisine Title
                      SizedBox(
                        width: 78,
                        child: Text(
                          item.title,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2022),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
