import 'package:flutter/material.dart';
import 'story_icon_button.dart';

class SidebarButtons extends StatelessWidget {
  final VoidCallback onTextTap;
  final VoidCallback onStickerTap;
  final VoidCallback onMentionTap;
  final VoidCallback onMoreTap;

  const SidebarButtons({
    super.key,
    required this.onTextTap,
    required this.onStickerTap,
    required this.onMentionTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 80,
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
            svgAsset: 'assets/home/icons/user_add.svg',
            onTap: onMentionTap,
          ),
          const SizedBox(height: 12),
          
          // More options button
          StoryIconButton(
            svgAsset: 'assets/home/icons/post_options.svg',
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}
