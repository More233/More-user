import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class StoryVideoWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isSelected;
  final ValueChanged<bool>? onBufferingChanged;
  final VoidCallback? onVideoCompleted;

  const StoryVideoWidget({
    super.key,
    required this.controller,
    required this.isSelected,
    this.onBufferingChanged,
    this.onVideoCompleted,
  });

  @override
  State<StoryVideoWidget> createState() => _StoryVideoWidgetState();
}

class _StoryVideoWidgetState extends State<StoryVideoWidget> {
  bool _hasEnded = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
    _applyPlaybackState();
  }

  @override
  void didUpdateWidget(covariant StoryVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_videoListener);
      widget.controller.addListener(_videoListener);
      _hasEnded = false;
    }
    _applyPlaybackState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    if (!mounted) return;

    final value = widget.controller.value;
    
    // Buffering change callback
    if (widget.onBufferingChanged != null) {
      widget.onBufferingChanged!(value.isBuffering);
    }

    // Video completion check
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      if (!_hasEnded) {
        _hasEnded = true;
        if (widget.onVideoCompleted != null) {
          widget.onVideoCompleted!();
        }
      }
    } else {
      _hasEnded = false;
    }
  }

  void _applyPlaybackState() {
    if (widget.controller.value.isInitialized) {
      if (widget.isSelected) {
        if (!widget.controller.value.isPlaying) {
          widget.controller.play();
        }
      } else {
        if (widget.controller.value.isPlaying) {
          widget.controller.pause();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: widget.controller.value.size.width,
            height: widget.controller.value.size.height,
            child: VideoPlayer(widget.controller),
          ),
        ),
      );
    }
    return Center(
      child: CupertinoActivityIndicator(
        color: Colors.white,
        radius: 12,
      ),
    );
  }
}
