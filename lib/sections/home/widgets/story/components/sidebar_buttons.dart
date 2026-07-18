import 'package:flutter/material.dart';
import 'story_icon_button.dart';
import 'volume_button.dart';

class SidebarButtons extends StatelessWidget {
  final VoidCallback onTextTap;
  final VoidCallback onStickerTap;
  final VoidCallback onMentionTap;
  final bool hasVideo;
  final VoidCallback? onVolumeTap;

  const SidebarButtons({
    super.key,
    required this.onTextTap,
    required this.onStickerTap,
    required this.onMentionTap,
    this.hasVideo = false,
    this.onVolumeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text button
          StoryIconButton(
            svgAsset: 'assets/home/icons/text_font.svg',
            onTap: onTextTap,
          ),
          const SizedBox(height: 12),
          
          // Stickers button
          StoryIconButton(
            svgAsset: 'assets/home/icons/smile.svg',
            onTap: onStickerTap,
          ),
          const SizedBox(height: 12),
          
          // Mention button
          StoryIconButton(
            svgAsset: 'assets/home/icons/at.svg',
            onTap: onMentionTap,
          ),
          const SizedBox(height: 12),

          // Volume button (if story has video)
          if (hasVideo && onVolumeTap != null) ...[
            VolumeButton(onTap: onVolumeTap!),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
