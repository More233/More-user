import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExploreSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final String searchQuery;
  final List<Map<String, dynamic>> suggestions;
  final String? userAvatarUrl;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onBackToTimeline;
  final ValueChanged<Map<String, dynamic>> onSuggestionTapped;
  final IconData Function(String) iconDataGetter;
  final double topPadding;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onTap;

  const ExploreSearchBar({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.searchQuery,
    required this.suggestions,
    this.userAvatarUrl,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onBackToTimeline,
    required this.onSuggestionTapped,
    required this.iconDataGetter,
    required this.topPadding,
    this.onFilterPressed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onBackToTimeline,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: userAvatarUrl != null
                    ? NetworkImage(userAvatarUrl!) as ImageProvider
                    : const AssetImage(
                        'assets/home/images/element.png',
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Search field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                readOnly: onTap != null,
                onTap: onTap,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Find a place",
                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0x9A1A1A2E),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/explore/search_01.svg',
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF82858C),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C57FC),
                              ),
                            ),
                          ),
                        )
                      : (searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: onClearSearch,
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF82858C),
                                size: 18,
                              ),
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          if (onFilterPressed != null && (searchQuery.isNotEmpty || searchController.text.isNotEmpty)) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterPressed,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.tune,
                  color: Color(0xFF82858C),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

