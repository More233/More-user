import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Stack(
      children: [
        if (hasPhotos)
          SizedBox(
            height: 280,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                );
              },
            ),
          )
        else
          // Premium header placeholder
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_camera_back_outlined,
                  color: Color(0xFF82858C),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  "No images available for this place",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ],
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
