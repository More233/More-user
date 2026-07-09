import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'story_icon_button.dart';
import 'volume_button.dart';

class TopActionBar extends ConsumerWidget {
  final bool hasVideo;
  final VoidCallback onBackTap;
  final VoidCallback onVolumeTap;
  final VoidCallback onPostTap;

  const TopActionBar({
    super.key,
    required this.hasVideo,
    required this.onBackTap,
    required this.onVolumeTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Arrow
          StoryIconButton(
            svgAsset: 'assets/home/icons/arrow_left_01.svg',
            onTap: onBackTap,
          ),
          
          // Audio/Mute indicator & Publish Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasVideo) ...[
                VolumeButton(onTap: onVolumeTap),
                const SizedBox(width: 12),
              ],
              
              // Publish Button
              GestureDetector(
                onTap: onPostTap,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Post Story",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
