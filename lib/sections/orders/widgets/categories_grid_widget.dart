import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/home_section_model.dart';

class CategoriesGridWidget extends StatelessWidget {
  final HomeSectionModel section;
  final Function(HomeSectionItemModel item)? onItemTapped;

  const CategoriesGridWidget({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Section Title
          Text(
            section.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2022),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),

          // 4-column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCategoryCard(context, item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, HomeSectionItemModel item) {
    return GestureDetector(
      onTap: () => onItemTapped?.call(item),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full Image Container + badge
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // The square container itself is the image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                    ),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (ctx, err, stack) => Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),

                // Optional Badge pill at bottom of container
                if (item.badgeText != null && item.badgeText!.isNotEmpty)
                  Positioned(
                    bottom: -5,
                    child: _buildBadge(item.badgeText!, item.badgeColor),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Label
          Text(
            item.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E2022),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, String? colorType) {
    Color bg;
    Color textColor;

    switch (colorType) {
      case 'red':
        bg = const Color(0xFFFF2D55);
        textColor = Colors.white;
        break;
      case 'blue':
        bg = const Color(0xFF007AFF);
        textColor = Colors.white;
        break;
      case 'gray':
        bg = const Color(0xFF4A4A4A);
        textColor = Colors.white;
        break;
      case 'yellow':
      default:
        bg = const Color(0xFFFFD600);
        textColor = const Color(0xFF1E2022);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: textColor,
          height: 1.15,
        ),
      ),
    );
  }
}
