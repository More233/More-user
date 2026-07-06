import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dynamic_place_image.dart';
import 'explore_place_card.dart';

class ExploreListPlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;

  const ExploreListPlaceCard({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    final type = place['type'] as String? ?? 'Other';
    final address = place['address'] as String? ?? 'Riyadh, Saudi Arabia';
    final rating = place['rating']?.toString() ?? '4.5';
    final reviewsCount = place['reviewsCount']?.toString() ?? '25';
    final distanceStr = place['distance'] as String? ?? '1.1 km';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8E8E8).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          DynamicPlaceImage(
            placeId: place['id']?.toString() ?? '',
            placeName: place['name']?.toString() ?? '',
            iconUrl: place['iconUrl']?.toString(),
            imageUrl: place['imageUrl']?.toString(),
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 12),

          // Right: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['name'] as String? ?? '',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$type • $address',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xBF3B3C4F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Badges Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Distance
                      ExplorePlaceCard.buildCardBadge(
                        icon: Icons.directions_walk,
                        label: distanceStr,
                      ),
                      const SizedBox(width: 6),
                      // Status (Open Now)
                      ExplorePlaceCard.buildStatusBadge(isOpen: true),
                      const SizedBox(width: 6),
                      // Rating
                      ExplorePlaceCard.buildCardBadge(
                        icon: Icons.star,
                        iconColor: const Color(0xFFFFCC00),
                        label: '$rating ($reviewsCount)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
