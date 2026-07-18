import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
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
              color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF333333),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF333333),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
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
              color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
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
          : (selectedMapTab == 1
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryPill("Movies", Icons.movie_outlined),
                    const SizedBox(width: 8),
                    _buildCategoryPill("Concerts", Icons.music_note),
                    const SizedBox(width: 8),
                    _buildCategoryPill("Sports", Icons.sports_soccer),
                  ],
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
                    _buildCategoryPill("Desserts", Icons.icecream_outlined),
                    const SizedBox(width: 8),
                    _buildCategoryPill("Juices", Icons.local_drink_outlined),
                    const SizedBox(width: 8),
                    _buildCategoryPill("Parks", Icons.park_outlined),
                    const SizedBox(width: 8),
                    _buildCategoryPill("Hotels", Icons.hotel_outlined),
                  ],
                )),
    );
  }
}
