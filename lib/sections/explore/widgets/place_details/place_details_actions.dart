import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceDetailsActions extends StatelessWidget {
  final double bottomPadding;
  final bool hasCheckedIn;
  final bool isSaved;
  final VoidCallback onCheckInTap;
  final VoidCallback onSaveTap;
  final VoidCallback onShareTap;

  const PlaceDetailsActions({
    super.key,
    required this.bottomPadding,
    required this.hasCheckedIn,
    required this.isSaved,
    required this.onCheckInTap,
    required this.onSaveTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color buttonBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFF5F6F8);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F242E);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding > 0 ? bottomPadding + 6 : 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Check In button
          GestureDetector(
            onTap: onCheckInTap,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasCheckedIn ? const Color(0xFFEDE6FC) : const Color(0xFF7C57FC),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: hasCheckedIn ? const Color(0xFF7C57FC) : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasCheckedIn ? "Checked In" : "Check In",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasCheckedIn ? const Color(0xFF7C57FC) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Save and Share side-by-side
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onSaveTap,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSaved ? const Color(0xFFEDE6FC) : buttonBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? const Color(0xFF7C57FC) : textColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Save",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSaved ? const Color(0xFF7C57FC) : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onShareTap,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: buttonBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share,
                          color: textColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Share",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
