import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../view_models/story_editor_view_model.dart';

class TrashCanOverlay extends ConsumerWidget {
  const TrashCanOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyEditorViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!state.isDragging) return const SizedBox.shrink();

    return Positioned(
      bottom: bottomPadding + 32,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: state.isNearTrash ? 76 : 60,
          height: state.isNearTrash ? 76 : 60,
          decoration: BoxDecoration(
            color: state.isNearTrash ? Colors.redAccent : Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(
              color: state.isNearTrash ? Colors.white : Colors.white54,
              width: state.isNearTrash ? 3 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            state.isNearTrash ? Icons.delete_forever_rounded : Icons.delete_outline_rounded,
            color: Colors.white,
            size: state.isNearTrash ? 38 : 28,
          ),
        ),
      ),
    );
  }
}
