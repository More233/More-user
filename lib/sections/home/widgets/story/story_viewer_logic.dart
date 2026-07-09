part of 'story_viewer.dart';

extension _StoryViewerLogic on _StoryViewerState {
  void _preloadMedia(StoryViewState storyState) {
    if (widget.storyGroups.isEmpty || storyState.currentGroupIndex >= widget.storyGroups.length) return;
    
    final currentGroup = widget.storyGroups[storyState.currentGroupIndex];
    final currentUrl = currentGroup.mediaUrls[storyState.currentStoryIndex];
    
    String? nextUrl;
    if (storyState.currentStoryIndex + 1 < currentGroup.mediaUrls.length) {
      nextUrl = currentGroup.mediaUrls[storyState.currentStoryIndex + 1];
    }
    
    String? nextGroupFirstUrl;
    if (storyState.currentGroupIndex + 1 < widget.storyGroups.length) {
      final nextGroup = widget.storyGroups[storyState.currentGroupIndex + 1];
      if (nextGroup.mediaUrls.isNotEmpty) {
        nextGroupFirstUrl = nextGroup.mediaUrls[0];
      }
    }
    
    // Clean old controllers that are no longer needed
    _cleanVideoCache(currentUrl, nextUrl, nextGroupFirstUrl);
    
    // Preload current, next, and next group first video
    _preloadVideoAt(currentGroup, storyState.currentStoryIndex);
    _preloadVideoAt(currentGroup, storyState.currentStoryIndex + 1);
    if (storyState.currentGroupIndex + 1 < widget.storyGroups.length) {
      _preloadVideoAt(widget.storyGroups[storyState.currentGroupIndex + 1], 0);
    }

    // Preload images as well
    if (!isVideoFile(currentUrl)) {
      precacheImage(CachedNetworkImageProvider(currentUrl), context);
    }
    if (nextUrl != null && !isVideoFile(nextUrl)) {
      precacheImage(CachedNetworkImageProvider(nextUrl), context);
    }
    if (nextGroupFirstUrl != null && !isVideoFile(nextGroupFirstUrl)) {
      precacheImage(CachedNetworkImageProvider(nextGroupFirstUrl), context);
    }
  }

  void _preloadVideoAt(UserStoryGroup group, int storyIndex) {
    if (storyIndex < 0 || storyIndex >= group.mediaUrls.length) return;
    final url = group.mediaUrls[storyIndex];
    if (!isVideoFile(url)) return;
    
    if (!_videoControllers.containsKey(url) && !_initializingUrls.contains(url)) {
      // 1. Check if the video was already preloaded by HomeStoryPreloader on the home feed
      final preloadedController = HomeStoryPreloader.instance.getController(url);
      if (preloadedController != null && preloadedController.value.isInitialized) {
        _videoControllers[url] = preloadedController;
        // Remove it from HomeStoryPreloader so it is now owned by the viewer state
        HomeStoryPreloader.instance.preloadedHomeControllers.remove(url);
        _videoCacheRevisionNotifier.value++;

        // Re-trigger preloading update state if it is the current slide
        final storyState = ref.read(storyViewModelProvider(widget.initialGroupIndex));
        final currentGroup = widget.storyGroups[storyState.currentGroupIndex];
        final currentUrl = currentGroup.mediaUrls[storyState.currentStoryIndex];
        if (currentUrl == url) {
          _startStory(storyState);
        }
        return;
      }

      _initializingUrls.add(url);
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      controller.initialize().then((_) {
        if (mounted) {
          _videoControllers[url] = controller;
          _initializingUrls.remove(url);
          _videoCacheRevisionNotifier.value++;

          // Re-trigger preloading update state if it is the current slide
          final storyState = ref.read(storyViewModelProvider(widget.initialGroupIndex));
          final currentGroup = widget.storyGroups[storyState.currentGroupIndex];
          final currentUrl = currentGroup.mediaUrls[storyState.currentStoryIndex];
          if (currentUrl == url) {
            _startStory(storyState);
          }
        } else {
          controller.dispose();
        }
      }).catchError((e) {
        debugPrint("Error initializing preloaded video: $e");
        _initializingUrls.remove(url);
      });
    }
  }

  void _cleanVideoCache(String currentUrl, String? nextUrl, String? nextGroupFirstUrl) {
    final urlsToKeep = {currentUrl};
    if (nextUrl != null) urlsToKeep.add(nextUrl);
    if (nextGroupFirstUrl != null) urlsToKeep.add(nextGroupFirstUrl);
    
    final urlsToRemove = _videoControllers.keys.where((url) => !urlsToKeep.contains(url)).toList();
    for (final url in urlsToRemove) {
      final controller = _videoControllers.remove(url);
      controller?.dispose();
    }
  }

  void _startStory(StoryViewState storyState) {
    _animationController.reset();
    
    if (widget.storyGroups.isEmpty || storyState.currentGroupIndex >= widget.storyGroups.length) return;
    final currentGroup = widget.storyGroups[storyState.currentGroupIndex];
    final currentMediaUrl = currentGroup.mediaUrls[storyState.currentStoryIndex];

    if (isVideoFile(currentMediaUrl)) {
      final controller = _videoControllers[currentMediaUrl];
      if (controller != null && controller.value.isInitialized) {
        _animationController.duration = controller.value.duration;
        if (!_focusNode.hasFocus && !storyState.isReactionTrayOpen) {
          _animationController.forward();
        }
      } else {
        // Video is not ready yet; wait to play it when loaded
        _animationController.stop();
      }
    } else {
      _animationController.duration = const Duration(seconds: 5);
      if (!_focusNode.hasFocus && !storyState.isReactionTrayOpen) {
        _animationController.forward();
      }
    }
    
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).startStory(widget.storyGroups);
  }

  void _nextStory() {
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).nextStory(
      widget.storyGroups,
      () => Navigator.pop(context),
    );
  }

  void _previousStory() {
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).previousStory(widget.storyGroups);
  }

  List<Map<String, dynamic>> _getMockViewers() {
    return [
      {
        'user': {
          'username': 'karennne',
          'first_name': 'Karen',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar_female.png',
        },
        'badge': 'heart',
      },
      {
        'user': {
          'username': 'Sam_TD',
          'first_name': 'Sam',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar_male.png',
        },
        'badge': null,
      },
      {
        'user': {
          'username': 'kieron_d',
          'first_name': 'Kieron',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar.png',
        },
        'badge': 'fire',
      },
      {
        'user': {
          'username': 'craig_love',
          'first_name': 'Craig',
          'last_name': 'Love',
          'avatar_url': 'assets/home/images/profile_image2.png',
        },
        'badge': null,
      },
    ];
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    try {
      final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
      await notifier.sendDM(text, widget.storyGroups);
    } catch (e) {
      debugPrint("Failed to send message: $e");
    }

    final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
    if (!state.isReactionTrayOpen) {
      _animationController.forward();
    }
  }

  Future<void> _sendEmojiReaction(String emoji) async {
    final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
    notifier.setReactionTrayOpen(false);

    try {
      await notifier.sendDM(emoji, widget.storyGroups);
    } catch (e) {
      debugPrint("Failed to send message: $e");
    }

    if (!_focusNode.hasFocus) {
      _animationController.forward();
    }
  }
}
