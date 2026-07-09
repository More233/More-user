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

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash toggle button (Top Left)
          if (state.isCameraInitialized)
            GestureDetector(
              onTap: onToggleFlash,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: Icon(
                  state.flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          // Close button (Top Right)
          StoryIconButton(
            svgAsset: 'assets/home/icons/cancel_01.svg',
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}
