import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExploreSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final String searchQuery;
  final List<Map<String, dynamic>> suggestions;
  final String? userAvatarUrl;
  final VoidCallback? onAvatarTapped;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onBackToTimeline;
  final ValueChanged<Map<String, dynamic>> onSuggestionTapped;
  final IconData Function(String) iconDataGetter;
  final double topPadding;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onTap;
  final VoidCallback? onAddFriendTapped;
  final String hintText;

  const ExploreSearchBar({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.searchQuery,
    required this.suggestions,
    this.userAvatarUrl,
    this.onAvatarTapped,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onBackToTimeline,
    required this.onSuggestionTapped,
    required this.iconDataGetter,
    required this.topPadding,
    this.onFilterPressed,
    this.onTap,
    this.onAddFriendTapped,
    this.hintText = "Find a place",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 10,
        bottom: 10,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTapped ?? onBackToTimeline,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: ClipOval(
                child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: userAvatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFEDE6FC),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF7C57FC),
                            size: 18,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFEDE6FC),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF7C57FC),
                          size: 18,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Search field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181C26) : Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
                readOnly: onTap != null,
                onTap: onTap,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.7) : const Color(0x9A1A1A2E),
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 16, right: 8),
                    child: SvgPicture.asset(
                      'assets/explore/search_01.svg',
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF82858C),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 18,
                  ),
                  suffixIcon: isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CupertinoActivityIndicator(
                            color: Color(0xFF7C57FC),
                            radius: 8,
                          ),
                        )
                      : ((searchQuery.isNotEmpty || searchController.text.isNotEmpty)
                          ? GestureDetector(
                              onTap: onClearSearch,
                              child: Icon(
                                Icons.close,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF82858C),
                                size: 18,
                              ),
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
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
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181C26) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B303C) : const Color(0xFFE8E8E8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.tune,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF82858C),
                  size: 20,
                ),
              ),
            ),
          ],
          if (onAddFriendTapped != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onAddFriendTapped,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF181C26) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_add_outlined,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1F242E),
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

