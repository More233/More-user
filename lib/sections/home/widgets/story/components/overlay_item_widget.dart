import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'measured_widget.dart';
import '../../../models/story_overlay_item.dart';
import '../../../view_models/story_editor_view_model.dart';

class OverlayItemWidget extends ConsumerStatefulWidget {
  final StoryOverlayItem item;
  final double canvasWidth;
  final double canvasHeight;
  final Widget Function(String type, dynamic data) buildOverlayContent;
  final VoidCallback onDoubleTapText;

  const OverlayItemWidget({
    super.key,
    required this.item,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.buildOverlayContent,
    required this.onDoubleTapText,
  });

  @override
  ConsumerState<OverlayItemWidget> createState() => _OverlayItemWidgetState();
}

class _OverlayItemWidgetState extends ConsumerState<OverlayItemWidget> {
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _startFocalPoint = Offset.zero;
  Offset _startOverlayPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    final isSelected = state.selectedOverlayId == widget.item.id;
    final isNearTrashThis = isSelected && state.isNearTrash;

    // Guidelines display scale parameters
    const double displayScale = 1.0;
    const double stickerPadding = 48.0;
    final paddedWidth = (widget.item.size.width + 2 * stickerPadding) * displayScale;
    final paddedHeight = (widget.item.size.height + 2 * stickerPadding) * displayScale;

    return Positioned(
      left: widget.item.position.dx - (paddedWidth / 2),
      top: widget.item.position.dy - (paddedHeight / 2),
      width: paddedWidth,
      height: paddedHeight,
      child: Transform.rotate(
        angle: widget.item.rotation,
        child: GestureDetector(
          onTap: () {
            notifier.selectOverlay(widget.item.id);
          },
          onDoubleTap: () {
            if (widget.item.type == 'text') {
              notifier.selectOverlay(widget.item.id);
              widget.onDoubleTapText();
            }
          },
          onScaleStart: (details) {
            notifier.selectOverlay(widget.item.id);
            _startScale = widget.item.scale;
            _startRotation = widget.item.rotation;
            _startFocalPoint = details.focalPoint;
            _startOverlayPosition = widget.item.position;
            notifier.setDraggingState(isDragging: true, isNearTrash: false);
          },
          onScaleUpdate: (details) {
            final newPosition = _startOverlayPosition + (details.focalPoint - _startFocalPoint);
            final newScale = details.scale != 1.0 ? (_startScale * details.scale).clamp(0.5, 8.0) : widget.item.scale;
            final newRotation = details.rotation != 0.0 ? _startRotation + details.rotation : widget.item.rotation;

            final updatedItem = widget.item.copyWith(
              position: newPosition,
              scale: newScale,
              rotation: newRotation,
            );
            notifier.updateOverlayAndGuides(updatedItem, widget.canvasWidth, widget.canvasHeight);
          },
          onScaleEnd: (details) {
            notifier.setDraggingState(isDragging: false, isNearTrash: false);
            if (state.isNearTrash && state.selectedOverlayId != null) {
              notifier.removeOverlay(state.selectedOverlayId!);
            }
            notifier.updateGuides(
              vertical: false,
              horizontal: false,
              left: false,
              right: false,
              top: false,
              bottom: false,
            );
          },
          child: Opacity(
            opacity: isNearTrashThis ? 0.4 : 1.0,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Container(
                padding: const EdgeInsets.all(stickerPadding),
                color: Colors.transparent,
                child: MeasuredWidget(
                  onSizeChanged: (newSize) {
                    if (widget.item.size != newSize) {
                      notifier.updateOverlay(widget.item.copyWith(size: newSize));
                    }
                  },
                  child: Transform.scale(
                    scale: widget.item.scale,
                    child: widget.buildOverlayContent(widget.item.type, widget.item.data),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
