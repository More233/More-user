import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreSearchLists extends StatelessWidget {
  final String searchQuery;
  final bool isSearching;
  final List<Map<String, dynamic>> searchResults;
  final bool isLoadingNearby;
  final List<Map<String, dynamic>> nearbyPlaces;
  final List<Map<String, dynamic>> recentPlaces;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<Map<String, dynamic>> onPlaceTap;

  const ExploreSearchLists({
    super.key,
    required this.searchQuery,
    required this.isSearching,
    required this.searchResults,
    required this.isLoadingNearby,
    required this.nearbyPlaces,
    required this.recentPlaces,
    required this.onCategoryTap,
    required this.onPlaceTap,
  });

  Widget _buildPlaceItem(BuildContext context, Map<String, dynamic> place) {
    final String name = place['name'] as String? ?? '';
    final String distance = place['distance'] as String? ?? '';
    final String address = place['address'] as String? ?? '';
    
    String subtitle = distance;
    if (address.isNotEmpty) {
      final parts = address.split(',');
      final area = parts.isNotEmpty ? parts.first.trim() : address;
      subtitle = "$distance • $area";
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconBgColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF1F3F5);
    final Color iconColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.location_on,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF82858C),
        ),
      ),
      onTap: () => onPlaceTap(place),
    );
  }

  Widget _buildAddNewPlaceItem(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color itemBgColor = isDark ? const Color(0xFF181C26) : Colors.white;
    final Color iconBgColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF1F3F5);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color borderColor = isDark ? const Color(0xFF2B313F) : const Color(0xFFE8E8E8);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context, {
          'type': 'add_new_place',
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: itemBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: textColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Add a new place",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF82858C),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchQuery.isNotEmpty) {
      if (isSearching) {
        return Center(
          child: CupertinoActivityIndicator(
            color: Color(0xFF7C57FC),
            radius: 12,
          ),
        );
      }
      if (searchResults.isEmpty) {
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  "No places found",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ),
            ),
            _buildAddNewPlaceItem(context),
            const SizedBox(height: 16),
          ],
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: searchResults.length + 1,
        itemBuilder: (context, index) {
          if (index == searchResults.length) {
            return _buildAddNewPlaceItem(context);
          }
          return _buildPlaceItem(context, searchResults[index]);
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nearby section
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Nearby",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isLoadingNearby)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: CupertinoActivityIndicator(
                  color: Color(0xFF7C57FC),
                  radius: 12,
                ),
              ),
            )
          else if (nearbyPlaces.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "No nearby places found",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  color: const Color(0xFF82858C),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: nearbyPlaces.length > 5 ? 5 : nearbyPlaces.length,
              itemBuilder: (context, index) {
                return _buildPlaceItem(context, nearbyPlaces[index]);
              },
            ),

          // Add New Place item directly under nearby places list
          _buildAddNewPlaceItem(context),

          // Recent section
          if (recentPlaces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Recent",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: recentPlaces.length,
              itemBuilder: (context, index) {
                return _buildPlaceItem(context, recentPlaces[index]);
              },
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
