import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreViewTogglePill extends StatelessWidget {
  final bool isListView;
  final Function(bool) onViewChanged;

  const ExploreViewTogglePill({
    super.key,
    required this.isListView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onViewChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: !isListView ? const Color(0xFFEDE6FC) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: !isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Map",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: !isListView ? FontWeight.w600 : FontWeight.normal,
                      color: !isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onViewChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isListView ? const Color(0xFFEDE6FC) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 18,
                    color: isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "List",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: isListView ? FontWeight.w600 : FontWeight.normal,
                      color: isListView ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
