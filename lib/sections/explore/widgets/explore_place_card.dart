import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dynamic_place_image.dart';

class ExplorePlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final ValueChanged<bool> onSavedChanged;
  final VoidCallback onActionTriggered;
  final VoidCallback onViewPressed;
  final VoidCallback onInteractionPressed;

  const ExplorePlaceCard({
    super.key,
    required this.place,
    required this.onSavedChanged,
    required this.onActionTriggered,
    required this.onViewPressed,
    required this.onInteractionPressed,
  });

  static String _getStickerEmoji(int index) {
    if (index == 0) return "📍";
    if (index == 1) return "🔥";
    if (index == 2) return "🎉";
    if (index == 3) return "🍕";
    if (index == 4) return "☕";
    if (index == 5) return "🔥";
    if (index == 6) return "😍";
    return "📍";
  }

  static IconData _getActionIcon(String actionType) {
    if (actionType == 'Order') return Icons.shopping_bag;
    if (actionType == 'Book') return Icons.calendar_today;
    if (actionType == 'check-in') return Icons.location_on;
    return Icons.arrow_forward;
  }

  static Widget buildCardBadge({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? const Color(0xFF82858C),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF636268),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildStatusBadge({required bool isOpen}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF34C759), // Green dot
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "Open Now",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF636268),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCheckIn = place['isCheckIn'] as bool? ?? false;
    final String authorName = place['authorName'] as String? ?? '';
    final String? authorAvatar = place['authorAvatar'] as String?;
    final String description = place['description'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (isCheckIn) ...[
            // User Check-in UI
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF3F4F6),
                  backgroundImage: authorAvatar != null && authorAvatar.isNotEmpty
                      ? NetworkImage(authorAvatar)
                      : const AssetImage('assets/Timeline/images/element.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F242E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "قام بتسجيل تواجد في ${place['name']}",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: const Color(0xFF7C57FC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF4B5563),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (place['stickerIndex'] != null && (place['stickerIndex'] as int) != -1) ...[
                  const SizedBox(width: 8),
                  // Render a small sticker badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE6FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getStickerEmoji(place['stickerIndex'] as int),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Action button for Check-in
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onInteractionPressed,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C57FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "تفاعل مع تسجيل التواجد",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Normal Place Card UI
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Image with bookmark
                Stack(
                  children: [
                    DynamicPlaceImage(
                      placeId: place['id']?.toString() ?? '',
                      placeName: place['name']?.toString() ?? '',
                      iconUrl: place['iconUrl']?.toString(),
                      imageUrl: place['imageUrl']?.toString(),
                      width: 90,
                      height: 90,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: () {
                          onSavedChanged(!(place['isSaved'] as bool? ?? false));
                        },
                        child: Builder(
                          builder: (context) {
                            final bool isSaved = place['isSaved'] as bool? ?? false;
                            final bool hasImage = place['imageUrl'] != null && place['imageUrl'].toString().isNotEmpty;
                            return Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                isSaved
                                    ? 'assets/Timeline/icons/bookmark_02_1.svg'
                                    : 'assets/Timeline/icons/bookmark_02.svg',
                                width: 22,
                                height: 22,
                                colorFilter: ColorFilter.mode(
                                  hasImage
                                      ? Colors.white
                                      : const Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Right: info columns
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name']?.toString() ?? '',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${place['type']} • ${place['address']}",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Badges row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Distance Badge
                          buildCardBadge(
                            icon: Icons.directions_walk,
                            label: place['distance']?.toString() ?? '',
                          ),
                          // Status Badge
                          buildCardBadge(
                            icon: Icons.circle,
                            iconColor: Colors.green,
                            label: "Open Now",
                          ),
                          // Rating Badge
                          buildCardBadge(
                            icon: Icons.star,
                            iconColor: Colors.amber,
                            label: "${place['rating']} (${place['reviewsCount']})",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Visitors list (moved below the row)
            if (place['visitors'] != null && (place['visitors'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      final visitors = List<Map<String, dynamic>>.from(place['visitors'] as List);
                      final int total = visitors.length;
                      final int countToShow = total > 3 ? 3 : total;
                      return SizedBox(
                        width: total == 1 ? 20.0 : (total == 2 ? 32.0 : 44.0),
                        height: 20,
                        child: Stack(
                          children: List.generate(countToShow, (index) {
                            if (total > 3 && index == 2) {
                              return Positioned(
                                left: index * 12.0,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 9,
                                    backgroundColor: const Color(0xFFEDE6FC),
                                    child: Text(
                                      '+${total - 2}',
                                      style: const TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C57FC),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            final visitor = visitors[index];
                            final avatarUrl = visitor['avatarUrl'] as String?;
                            Widget avatarChild;
                            if (avatarUrl != null && avatarUrl.isNotEmpty) {
                              avatarChild = CircleAvatar(
                                radius: 9,
                                backgroundImage: NetworkImage(avatarUrl),
                              );
                            } else {
                              final initials = visitor['name']
                                  .toString()
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase();
                              avatarChild = CircleAvatar(
                                radius: 9,
                                backgroundColor: const Color(0xFFEDE6FC),
                                child: Text(
                                  initials.isNotEmpty ? initials : '?',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C57FC),
                                  ),
                                ),
                              );
                            }
                            return Positioned(
                              left: index * 12.0,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white,
                                child: avatarChild,
                              ),
                            );
                          }),
                        ),
                      );
                    }
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final visitors = List<Map<String, dynamic>>.from(place['visitors'] as List);
                        final int count = visitors.length;
                        String text = '';
                        if (count == 1) {
                          text = '${visitors[0]['name']} is here';
                        } else if (count == 2) {
                          text = '${visitors[0]['name']} and ${visitors[1]['name']} are here';
                        } else {
                          text = '${visitors[0]['name']}, ${visitors[1]['name']} and ${count - 2} others are here';
                        }
                        return Text(
                          text,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            color: const Color(0xFF636268),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Card Action Buttons
            Row(
              children: [
                // View Button
                Expanded(
                  child: GestureDetector(
                    onTap: onViewPressed,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7C57FC), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.visibility, color: Color(0xFF7C57FC), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "View",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF7C57FC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Dynamic Action Button (Order, Book, check-in)
                Expanded(
                  child: GestureDetector(
                    onTap: onActionTriggered,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C57FC),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getActionIcon(place['actionType'] as String? ?? 'Order'),
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (place['actionType'] == 'check-in') ? 'Check-in' : (place['actionType'] as String? ?? 'Order'),
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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
