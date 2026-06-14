import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StoryTracker {
  static final StoryTracker _instance = StoryTracker._internal();
  factory StoryTracker() => _instance;
  StoryTracker._internal();

  Set<String> _viewedUrls = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final file = await _getTrackerFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _viewedUrls = list.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      debugPrint("Error loading viewed stories: $e");
    }
    _initialized = true;
  }

  Future<File> _getTrackerFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/viewed_stories.json');
  }

  bool isViewed(String mediaUrl) {
    return _viewedUrls.contains(mediaUrl);
  }

  bool isGroupViewed(List<String> mediaUrls) {
    if (mediaUrls.isEmpty) return false;
    return mediaUrls.every((url) => _viewedUrls.contains(url));
  }

  Future<void> markAsViewed(String mediaUrl) async {
    await init();
    if (_viewedUrls.contains(mediaUrl)) return;
    _viewedUrls.add(mediaUrl);
    try {
      final file = await _getTrackerFile();
      await file.writeAsString(jsonEncode(_viewedUrls.toList()));
    } catch (e) {
      debugPrint("Error saving viewed stories: $e");
    }
  }
}
