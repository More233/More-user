import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaceDetailsHeader extends StatelessWidget {
  final double topPadding;
  final bool hasPhotos;
  final List<String> images;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBackTap;
  final VoidCallback? onMoreTap;

  const PlaceDetailsHeader({
    super.key,
    required this.topPadding,
    required this.hasPhotos,
    required this.images,
    required this.currentPage,
    required this.onPageChanged,
    required this.onBackTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasPhotos) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: topPadding, left: 8, right: 8),
        height: topPadding + 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF1F242E),
                size: 24,
              ),
              onPressed: onBackTap,
            ),
            IconButton(
              icon: const Icon(
                Icons.more_horiz,
                color: Color(0xFF1F242E),
                size: 24,
              ),
              onPressed: onMoreTap ?? () {},
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: images[index],
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                ),
              );
            },
          ),
        ),

        // Back button (dark circular card)
        Positioned(
          top: topPadding + 12,
          left: 16,
          child: GestureDetector(
            onTap: onBackTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Three-dot action button (dark circular card)
        Positioned(
          top: topPadding + 12,
          right: 16,
          child: GestureDetector(
            onTap: onMoreTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Image index indicator e.g. "1/18"
        if (hasPhotos)
          Positioned(
            bottom: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                "${currentPage + 1}/${images.length}",
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
