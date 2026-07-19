import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders a row with a rounded box, a custom SVG icon, and text blocks.
class FeatureRow extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color backgroundColor;
  final bool hasShadow;

  const FeatureRow({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.backgroundColor = Colors.white,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color resolvedBgColor = backgroundColor;
    if (backgroundColor == Colors.white) {
      resolvedBgColor = isDark ? const Color(0xFF1E2433) : Colors.white;
    } else if (backgroundColor == const Color(0xFFF7F6FC)) {
      resolvedBgColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFF7F6FC);
    }

    final Color titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF9CA3AF);
    final Color iconBgColor = isDark ? const Color(0xFF2A1C54) : const Color(0xFFF2EEFC);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: const Color(0xFF2C354A)) : null,
        boxShadow: (hasShadow && !isDark)
            ? [
                BoxShadow(
                  color: const Color(0xFF8B60FC).withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF7C57FC),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Columns
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}
