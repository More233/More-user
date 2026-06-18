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
                        'assets/Timeline/images/element.png',
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Search field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: onSearchSubmitted,
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
        ],
      ),
    );
  }
}

class ExploreCategoryFilters extends StatelessWidget {
  final int selectedMapTab;
  final String selectedCategory;
  final bool filterVisited;
  final bool filterSaved;
  final ValueChanged<String> onCategoryTapped;
  final VoidCallback onFilterVisitedTapped;
  final VoidCallback onFilterSavedTapped;
  final double topPadding;

  const ExploreCategoryFilters({
    super.key,
    required this.selectedMapTab,
    required this.selectedCategory,
    required this.filterVisited,
    required this.filterSaved,
    required this.onCategoryTapped,
    required this.onFilterVisitedTapped,
    required this.onFilterSavedTapped,
    required this.topPadding,
  });

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C57FC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? Colors.transparent : const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF333333),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category, IconData icon) {
    final bool isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () => onCategoryTapped(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C57FC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF333333),
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: selectedMapTab == 3
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterPill(
                    label: "Visited",
                    icon: Icons.history,
                    isActive: filterVisited,
                    onTap: onFilterVisitedTapped,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: "Saved",
                    icon: Icons.bookmark_outline,
                    isActive: filterSaved,
                    onTap: onFilterSavedTapped,
                  ),
                ],
              ),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryPill("Restaurant", Icons.restaurant),
                const SizedBox(width: 8),
                _buildCategoryPill("Coffee", Icons.local_cafe),
                const SizedBox(width: 8),
                _buildCategoryPill("Bakery", Icons.breakfast_dining),
                const SizedBox(width: 8),
                _buildCategoryPill("Bars", Icons.local_bar),
                const SizedBox(width: 8),
                _buildCategoryPill("Desserts", Icons.icecream),
              ],
            ),
    );
  }
}
