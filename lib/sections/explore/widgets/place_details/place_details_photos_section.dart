import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'full_screen_image_viewer.dart';

class PlacePhotosSection extends StatefulWidget {
  final List<String> images;
  final List<String> peopleImages;

  const PlacePhotosSection({
    super.key,
    required this.images,
    required this.peopleImages,
  });

  @override
  State<PlacePhotosSection> createState() => _PlacePhotosSectionState();
}

class _PlacePhotosSectionState extends State<PlacePhotosSection> {
  String _activePhotoTab = 'All';

  @override
  Widget build(BuildContext context) {
    final List<String> currentPhotos = _activePhotoTab == 'All' ? widget.images : widget.peopleImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Photos",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F242E),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.images.isEmpty && widget.peopleImages.isEmpty)
          Text(
            "No photos available for this place",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF82858C),
            ),
          )
        else ...[
          // Tab selectors
          Row(
            children: [
              _buildPhotoTabButton("All", widget.images.length, _activePhotoTab == 'All', () {
                setState(() {
                  _activePhotoTab = 'All';
                });
              }),
              if (widget.peopleImages.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildPhotoTabButton("People", widget.peopleImages.length, _activePhotoTab == 'People', () {
                  setState(() {
                    _activePhotoTab = 'People';
                  });
                }),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal list of actual photos
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentPhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          images: currentPhotos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: currentPhotos[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF5F6F8),
                          child: Center(
                            child: CupertinoActivityIndicator(
                              color: Color(0xFF7C57FC),
                              radius: 8,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF5F6F8),
                          child: const Icon(Icons.broken_image, color: Color(0xFF82858C)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoTabButton(String label, int count, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE6FC) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          "$label ($count)",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF636268),
          ),
        ),
      ),
    );
  }
}
