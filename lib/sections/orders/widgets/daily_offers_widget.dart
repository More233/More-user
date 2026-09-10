import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_section_model.dart';

class DailyOffersWidget extends StatelessWidget {
  final HomeSectionModel section;
  final Function(HomeSectionItemModel item)? onItemTapped;

  const DailyOffersWidget({
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
      padding: const EdgeInsets.only(top: 8, bottom: 16),
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

          // Horizontal Cards List
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL feel
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final displayText = (item.subtitle != null && item.subtitle!.trim().isNotEmpty)
                    ? item.subtitle!.trim()
                    : item.title.trim();

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onItemTapped?.call(item);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 135,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image
                            Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: const Color(0xFFE5E7EB),
                                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                              ),
                            ),

                            // Bottom Shadow Overlay + Centered Text
                            if (displayText.isNotEmpty)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.8),
                                        Colors.black.withValues(alpha: 0.35),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.65, 1.0],
                                    ),
                                  ),
                                  child: Text(
                                    displayText,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
