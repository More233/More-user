import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreSearchHeader extends StatelessWidget {
  final double topPadding;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isSearching;
  final String searchQuery;
  final VoidCallback onBackTap;
  final VoidCallback onClearTap;
  final VoidCallback onFilterTap;

  const ExploreSearchHeader({
    super.key,
    required this.topPadding,
    required this.controller,
    required this.onChanged,
    required this.isSearching,
    required this.searchQuery,
    required this.onBackTap,
    required this.onClearTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBackTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1A1A2E),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Search input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Find a place",
                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0x9A1A1A2E),
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF82858C),
                    size: 20,
                  ),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
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
                              onTap: onClearTap,
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF82858C),
                                size: 18,
                              ),
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter button
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.tune,
                color: Color(0xFF82858C),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
