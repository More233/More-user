import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle getFontFamilyStyle(String name) {
  switch (name) {
    case 'Literature':
      return GoogleFonts.playfairDisplay();
    case 'Classic':
      return GoogleFonts.lora();
    case 'Modern':
      return GoogleFonts.montserrat();
    case 'Typewriter':
      return GoogleFonts.courierPrime();
    case 'Elegant':
      return GoogleFonts.dancingScript();
    case 'Directional':
      return GoogleFonts.cinzel();
    default:
      return GoogleFonts.ibmPlexSansArabic();
  }
}

Widget buildStoryOverlayWidget(String type, dynamic data) {
  switch (type) {
    case 'music':
      final track = Map<String, String>.from(data as Map? ?? {});
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, color: Color(0xFF7C57FC), size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track['title'] ?? '',
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  track['artist'] ?? '',
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    case 'mention':
      final mention = data as String;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C57FC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          mention,
          style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    case 'sticker':
      final emoji = data as String;
      return Material(
        color: Colors.transparent,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 48),
        ),
      );
    case 'text':
      final String text;
      final Color textColor;
      final Color? bgColor;
      final String fontFamily;
      final TextAlign alignment;
      final bool isBold;
      final String backgroundStyle;
      
      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        text = dataMap['text'] as String? ?? '';
        textColor = Color(dataMap['color'] as int? ?? Colors.white.toARGB32());
        bgColor = dataMap['backgroundColor'] != null ? Color(dataMap['backgroundColor'] as int) : null;
        fontFamily = dataMap['fontFamily'] as String? ?? 'Default';
        final alignStr = dataMap['alignment'] as String? ?? 'center';
        alignment = alignStr == 'left' ? TextAlign.left : (alignStr == 'right' ? TextAlign.right : TextAlign.center);
        isBold = dataMap['isBold'] as bool? ?? false;
        backgroundStyle = dataMap['backgroundStyle'] as String? ?? 'normal';
      } else {
        text = data as String? ?? '';
        textColor = Colors.white;
        bgColor = Colors.black87;
        fontFamily = 'Default';
        alignment = TextAlign.center;
        isBold = false;
        backgroundStyle = 'normal';
      }

      TextStyle textStyle = getFontFamilyStyle(fontFamily).copyWith(
        color: textColor,
        fontSize: 16,
        fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      );

      if (backgroundStyle == 'neon') {
        textStyle = textStyle.copyWith(
          shadows: [
            Shadow(
              color: textColor.withValues(alpha: 0.8),
              blurRadius: 10,
            ),
          ],
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: backgroundStyle == 'normal' && bgColor != null
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.zero,
              )
            : backgroundStyle == 'neon'
                ? BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: textColor.withValues(alpha: 0.5), width: 1.5),
                  )
                : backgroundStyle == 'pixel'
                    ? BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: textColor, width: 2),
                      )
                    : null,
        child: Text(
          text,
          textAlign: alignment,
          style: textStyle,
        ),
      );
    default:
      return const SizedBox.shrink();
  }
}

bool isVideoFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
}
