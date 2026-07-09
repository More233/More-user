import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../../view_models/story_composer_view_model.dart';

class ComposerBottomControls extends ConsumerWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressEndDetails) onLongPressEnd;
  final VoidCallback onLongPressCancel;
  final VoidCallback onToggleCamera;

  const ComposerBottomControls({
    super.key,
    required this.onGalleryTap,
    required this.onShutterTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyComposerViewModelProvider);

    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery Thumbnail Button
          if (!state.isRecording)
            GestureDetector(
              onTap: onGalleryTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: state.latestAsset != null
                      ? AssetEntityImage(
                          state.latestAsset!,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize(80, 80),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.white10,
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            'assets/home/icons/google_photos.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
          
          // Shutter Button (Tap for photo, Long-press for video)
          GestureDetector(
            onTap: onShutterTap,
            onLongPressStart: onLongPressStart,
            onLongPressEnd: onLongPressEnd,
            onLongPressCancel: onLongPressCancel,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(
                      color: state.isRecording ? Colors.red : Colors.white.withValues(alpha: 0.6),
                      width: 4,
                    ),
                  ),
                ),
                // Recording Progress Circular indicator
                if (state.isRecording)
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      value: state.recordingProgress,
                      color: Colors.red,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                // Inner button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: state.isRecording ? 40 : 58,
                  height: state.isRecording ? 40 : 58,
                  decoration: BoxDecoration(
                    shape: state.isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: state.isRecording ? BorderRadius.circular(8) : null,
                    color: state.isRecording ? Colors.red : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Flip Camera Button
          if (!state.isRecording)
            GestureDetector(
              onTap: onToggleCamera,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/home/icons/change_camera.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}
