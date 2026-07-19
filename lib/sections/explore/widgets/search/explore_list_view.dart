import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../place_details_screen.dart';
import '../cards/explore_list_place_card.dart';

class ExploreListView extends StatelessWidget {
  final double topPadding;
  final double navBarHeight;
  final List<Map<String, dynamic>> filteredPlaces;
  final String? userAvatarUrl;
  final VoidCallback? onAvatarTapped;
  final TextEditingController searchController;
  final bool isSearching;
  final String searchQuery;
  final VoidCallback onBackToTimeline;
  final VoidCallback onFilterPressed;
  final Function(String) onSearchChanged;
  final Function(String) onSearchSubmitted;
  final Function(Map<String, dynamic>) onPlaceActionTriggered;
  final Function(String) onCategoryTapped;
  final String selectedCategory;
  final VoidCallback onClearSearch;
  final VoidCallback? onSearchTap;

  const ExploreListView({
    super.key,
    required this.topPadding,
    required this.navBarHeight,
    required this.filteredPlaces,
    required this.userAvatarUrl,
    this.onAvatarTapped,
    required this.searchController,
    required this.isSearching,
    required this.searchQuery,
    required this.onBackToTimeline,
    required this.onFilterPressed,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onPlaceActionTriggered,
    required this.onCategoryTapped,
    required this.selectedCategory,
    required this.onClearSearch,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(
            top: topPadding + 12,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF0F0F0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAvatarTapped ?? onBackToTimeline,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: userAvatarUrl != null
                          ? CachedNetworkImageProvider(userAvatarUrl!)
                          : const AssetImage('assets/home/images/element.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF82858C),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          onSubmitted: onSearchSubmitted,
                          readOnly: onSearchTap != null,
                          onTap: onSearchTap,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            color: const Color(0xFF333333),
                          ),
                          decoration: InputDecoration(
                            hintText: "Find a place",
                            hintStyle: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              color: const Color(0xBF3B3C4F),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (isSearching)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: CupertinoActivityIndicator(
                            color: Color(0xFF7C57FC),
                            radius: 8,
                          ),
                        )
                      else if (searchQuery.isNotEmpty || searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: onClearSearch,
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF82858C),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onFilterPressed,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8E8E8),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Color(0xFF333333),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: ListView(
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
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFFAFAFA),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  "${filteredPlaces.length} results are found",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: navBarHeight + 80),
                    itemCount: filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaceDetailsScreen(
                                place: place,
                                onActionTriggered: () => onPlaceActionTriggered(place),
                              ),
                            ),
                          );
                        },
                        child: ExploreListPlaceCard(place: place),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
}
