import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/user_story_group.dart';
import '../widgets/story/components/story_overlay_renderer.dart'; // for isVideoFile

class HomeStoryPreloader {
  static final HomeStoryPreloader instance = HomeStoryPreloader._internal();
  HomeStoryPreloader._internal();

  final Map<String, VideoPlayerController> preloadedHomeControllers = {};
  final Set<String> _initializingUrls = {};

  VideoPlayerController? getController(String url) {
    return preloadedHomeControllers[url];
  }

  void preloadFeedStories(BuildContext context, List<UserStoryGroup> groups) {
    if (groups.isEmpty) return;

    // Take first 3 groups to preload
    final targets = groups.take(3).toList();

    for (final group in targets) {
      if (group.mediaUrls.isEmpty) continue;
      final url = group.mediaUrls[0];

      if (isVideoFile(url)) {
        if (!preloadedHomeControllers.containsKey(url) && !_initializingUrls.contains(url)) {
          _initializingUrls.add(url);
          final controller = VideoPlayerController.networkUrl(Uri.parse(url));
          controller.initialize().then((_) {
            preloadedHomeControllers[url] = controller;
            _initializingUrls.remove(url);
            debugPrint("HomeStoryPreloader: Successfully preloaded video $url");
          }).catchError((e) {
            _initializingUrls.remove(url);
            controller.dispose();
            debugPrint("HomeStoryPreloader: Failed to preload video $url: $e");
          });
        }
      } else {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
  }

  void clearCache() {
    for (final controller in preloadedHomeControllers.values) {
      controller.dispose();
    }
    preloadedHomeControllers.clear();
    _initializingUrls.clear();
  }
}
