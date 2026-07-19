import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreSearchHeader extends StatelessWidget {
  final double topPadding;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isSearching;
  final String searchQuery;
  final VoidCallback onBackTap;
  final VoidCallback onClearTap;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onCurrentLocationTap;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const ExploreSearchHeader({
    super.key,
    required this.topPadding,
    required this.controller,
    required this.onChanged,
    required this.isSearching,
    required this.searchQuery,
    required this.onBackTap,
    required this.onClearTap,
    required this.onCategoryTap,
    required this.onCurrentLocationTap,
    this.focusNode,
    this.onSubmitted,
  });

  Widget _buildCategoryChip(BuildContext context, String label, IconData icon, String type) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color chipBgColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF1F3F5);
    final Color chipBorderColor = isDark ? const Color(0xFF2B313F) : const Color(0xFFE8E8E8);
    final Color chipTextColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: () => onCategoryTap(type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: chipBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: chipTextColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: chipTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF1F3F5);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color iconColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color dividerColor = isDark ? const Color(0xFF2E3544) : const Color(0xFFE2E4E6);

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified grey card containing Search input and Current Location
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Back arrow + Search Input
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBackTap,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
                        child: Icon(
                          Icons.chevron_left,
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Find a place",
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            color: const Color(0xFF82858C),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: isSearching
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CupertinoActivityIndicator(
                                    color: Color(0xFF7C57FC),
                                    radius: 8,
                                  ),
                                )
                              : (searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: onClearTap,
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFF82858C),
                                        size: 18,
                                      ),
                                    )
                                  : null),
                        ),
                      ),
                    ),
                  ],
                ),
                // Subtle horizontal divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: dividerColor,
                  ),
                ),
                // Row 2: Current Location
                GestureDetector(
                  onTap: onCurrentLocationTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.transparent, // Ensure full area is clickable
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: iconColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Current Location",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal Category Pills
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _buildCategoryChip(context, "Restaurants", Icons.restaurant, "Restaurant"),
                _buildCategoryChip(context, "Coffee", Icons.local_cafe, "Coffee"),
                _buildCategoryChip(context, "Bakery", Icons.breakfast_dining, "Bakery"),
                _buildCategoryChip(context, "Bars", Icons.local_bar, "Bars"),
                _buildCategoryChip(context, "Desserts", Icons.icecream, "Desserts"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
