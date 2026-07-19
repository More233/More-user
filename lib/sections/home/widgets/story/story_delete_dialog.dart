import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryDeleteDialog extends StatelessWidget {
  const StoryDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF131722) : const Color(0xFFF2F2F2);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF333333);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFD1D1D6);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  Text(
                    "Delete this photo?",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can restore unarchived stories for 24 hours, or 30 days for archived stories, from Recently deleted in Your activity. After that, it will be permanently deleted.",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: secondaryTextColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: dividerColor, thickness: 0.5),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context, true),
              child: Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  "Delete",
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFFD32F2F),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: dividerColor, thickness: 0.5),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context, false),
              child: Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  "Cancel",
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
