import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryOptionsSheet extends StatelessWidget {
  final VoidCallback onAddToStory;
  final VoidCallback onDeleteStory;

  const StoryOptionsSheet({
    super.key,
    required this.onAddToStory,
    required this.onDeleteStory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: SvgPicture.asset(
                'assets/home/icons/add_circle.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              title: Text(
                "Add to Story",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                onAddToStory();
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/home/icons/delete_03.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Color(0xFFFF453A), BlendMode.srcIn),
              ),
              title: Text(
                "Delete Story",
                style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFFFF453A), fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                onDeleteStory();
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/home/icons/cancel_01.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
              ),
              title: Text(
                "Cancel",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
