import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class EngagementButton extends StatelessWidget {
  final String iconPath;
  final int count;
  final bool active;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;
  final double spacing;

  const EngagementButton({
    super.key,
    required this.iconPath,
    required this.count,
    required this.active,
    this.onTap,
    this.iconSize = 20.0,
    this.fontSize = 14.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white54 : const Color(0xFF5A5D67);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(
              active ? const Color(0xFF7C57FC) : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
          if (count > 0) ...[
            SizedBox(width: spacing),
            Text(
              '$count',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: active ? const Color(0xFF7C57FC) : inactiveColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
