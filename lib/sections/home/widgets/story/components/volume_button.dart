import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../view_models/story_editor_view_model.dart';

class VolumeButton extends ConsumerWidget {
  final VoidCallback onTap;
  const VolumeButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyEditorViewModelProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(
          state.isAudioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
