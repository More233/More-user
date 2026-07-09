import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../../view_models/story_composer_view_model.dart';
import 'story_icon_button.dart';

class ComposerTopControls extends ConsumerWidget {
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final VoidCallback onToggleCamera;

  const ComposerTopControls({
    super.key,
    required this.onClose,
    required this.onToggleFlash,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyComposerViewModelProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          StoryIconButton(
            svgAsset: 'assets/home/icons/cancel.svg',
            onTap: onClose,
          ),
          
          // Flash & Switch camera
          if (state.isCameraInitialized)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StoryIconButton(
                  svgAsset: state.flashMode == FlashMode.torch
                      ? 'assets/home/icons/flash.svg'
                      : 'assets/home/icons/flash_off.svg',
                  onTap: onToggleFlash,
                ),
                const SizedBox(width: 12),
                StoryIconButton(
                  svgAsset: 'assets/home/icons/camera_switch.svg',
                  onTap: onToggleCamera,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
