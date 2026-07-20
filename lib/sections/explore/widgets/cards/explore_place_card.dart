import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moor/sections/explore/helpers/marker_generator.dart';
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


  static Widget buildCardBadge({
    required IconData icon,
    required String label,
    Color? iconColor,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2430) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3548) : const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? (isDark ? Colors.white70 : const Color(0xFF82858C)),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF636268),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildStatusBadge({required bool isOpen, bool isDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2430) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3548) : const Color(0xFFE8E8E8),
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
              color: isDark ? Colors.white70 : const Color(0xFF636268),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF82858C);
    final Color dragHandleColor = isDark ? const Color(0xFF323A4E) : Colors.grey[300]!;
    final Color iconColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color quoteColor = isDark ? Colors.white60 : const Color(0xFF4B5563);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
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
                color: dragHandleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Normal Place Card UI (Clean Google Maps / Foursquare style)
          GestureDetector(
            onTap: onViewPressed,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          placeType: place['type']?.toString(),
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: GestureDetector(
                            onTap: () {
                              onSavedChanged(!(place['isSaved'] as bool? ?? false));
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                place['isSaved'] as bool? ?? false
                                    ? 'assets/home/icons/bookmark_02.svg'
                                    : 'assets/home/icons/bookmark_02_1.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  place['imageUrl'] != null &&
                                  place['imageUrl'].toString().isNotEmpty &&
                                  !place['imageUrl'].toString().contains('unsplash.com/photo-') &&
                                  !place['imageUrl'].toString().contains('placeholder_for_')
                                      ? Colors.white
                                      : const Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
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
                            (() {
                              final String name = place['arabicName']?.toString().isNotEmpty == true
                                  ? place['arabicName'].toString()
                                  : (place['name']?.toString() ?? '');
                              return name.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
                            })(),
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (() {
                              final String resolved = MarkerGenerator.resolveType(
                                place['type']?.toString() ?? '',
                                place['name']?.toString() ?? '',
                                place['arabicName']?.toString() ?? '',
                              );
                              if (resolved == 'other') return 'Other';
                              return resolved[0].toUpperCase() + resolved.substring(1);
                            })(),
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            place['address']?.toString() ?? '',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Rating Row: Smile icon, Rating value, total reviews
                          Row(
                            children: [
                              Icon(
                                Icons.sentiment_satisfied_alt,
                                color: iconColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place['rating']?.toString() ?? '8.0',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${place['reviewsCount']?.toString() ?? '0'})",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Extract top review quote if available
                () {
                  final List<dynamic>? googleReviews = place['googleReviews'] as List<dynamic>?;
                  final String? description = place['description'] as String?;
                  String? quote;
                  if (description != null && description.isNotEmpty && place['isCheckIn'] != true) {
                    quote = description;
                  } else if (googleReviews != null && googleReviews.isNotEmpty) {
                    quote = googleReviews.first['description'] as String?;
                  }
                  if (quote != null && quote.trim().isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        '"${quote.trim()}"',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          color: quoteColor,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
