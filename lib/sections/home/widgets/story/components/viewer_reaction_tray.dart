import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ViewerReactionTray extends StatelessWidget {
  final bool isReactionTrayOpen;
  final ValueChanged<String> onReactionSelected;

  const ViewerReactionTray({
    super.key,
    required this.isReactionTrayOpen,
    required this.onReactionSelected,
  });

  Widget _buildStickerItem(String assetPath, String emoji) {
    final bool isSvg = assetPath.endsWith('.svg');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onReactionSelected(emoji),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: isSvg
              ? SvgPicture.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                )
              : Image.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      left: 16,
      right: 16,
      bottom: isReactionTrayOpen
          ? (78 + MediaQuery.of(context).padding.bottom + 16 + 62)
          : (78 + MediaQuery.of(context).padding.bottom + 16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isReactionTrayOpen ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !isReactionTrayOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white12, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStickerItem('assets/home/images/heart.png', '❤️'),
                _buildStickerItem('assets/home/images/heart_eyes.png', '😍'),
                _buildStickerItem('assets/home/images/hands_face.png', '🫣'),
                _buildStickerItem('assets/home/images/fire.png', '🔥'),
                _buildStickerItem('assets/home/images/thumbs_up.png', '👍'),
                _buildStickerItem('assets/home/images/beer.png', '🍻'),
                _buildStickerItem('assets/home/images/plus_one.png', '+1'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
