import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../place_details_screen.dart';

class PlaceSimilarPlacesSection extends StatelessWidget {
  final List<Map<String, dynamic>> similarPlaces;
  final VoidCallback onActionTriggered;

  const PlaceSimilarPlacesSection({
    super.key,
    required this.similarPlaces,
    required this.onActionTriggered,
  });

  @override
  Widget build(BuildContext context) {
    if (similarPlaces.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F242E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Similar places",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similarPlaces.length,
            itemBuilder: (context, index) {
              final p = similarPlaces[index];
              final name = p['name'] as String? ?? '';
              final type = p['type'] as String? ?? '';
              final double rating = (p['rating'] as num?)?.toDouble() ?? 4.0;
              final int reviews = p['reviewsCount'] as int? ?? 5;
              final String rawUrl = p['imageUrl'] as String? ?? '';
              final bool hasRealImage = rawUrl.isNotEmpty && !rawUrl.contains('unsplash.com/photo-');
              final String imageUrl = hasRealImage ? rawUrl : '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaceDetailsScreen(
                        place: p,
                        onActionTriggered: onActionTriggered,
                      ),
                    ),
                  );
                },
                child: _buildSimilarPlaceCard(
                  name: name,
                  typeAndPrice: "$type • \$\$",
                  rating: rating.toStringAsFixed(1),
                  reviews: reviews.toString(),
                  imageUrl: imageUrl,
                  isHappy: rating >= 4.0,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarPlaceCard({
    required String name,
    required String typeAndPrice,
    required String rating,
    required String reviews,
    required String imageUrl,
    required bool isHappy,
    required bool isDark,
  }) {
    final Color cardBg = isDark ? const Color(0xFF1F2430) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F242E);
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF82858C);

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12, bottom: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    width: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 100,
                      width: 180,
                      color: isDark ? const Color(0xFF131722) : const Color(0xFFF3F4F6),
                      child: const Center(
                        child: CupertinoActivityIndicator(
                          color: Color(0xFF7C57FC),
                          radius: 8,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildSimilarCardPlaceholder(isDark),
                  )
                : _buildSimilarCardPlaceholder(isDark),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeAndPrice,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: textMutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isHappy ? Icons.sentiment_satisfied_alt : Icons.sentiment_very_dissatisfied,
                      color: isHappy ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$rating ($reviews)",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarCardPlaceholder(bool isDark) {
    return Container(
      height: 100,
      width: 180,
      color: isDark ? const Color(0xFF131722) : const Color(0xFFF5F6F8),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        color: isDark ? Colors.white70 : const Color(0xFF82858C),
        size: 32,
      ),
    );
  }
}
