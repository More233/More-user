import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_editor_state.dart';
import '../models/story_overlay_item.dart';
import 'social_feed_view_model.dart';

final storyEditorViewModelProvider = StateNotifierProvider.autoDispose<StoryEditorViewModel, StoryEditorState>((ref) {
  return StoryEditorViewModel(ref);
});

class StoryEditorViewModel extends StateNotifier<StoryEditorState> {
  final Ref _ref;

  StoryEditorViewModel(this._ref) : super(StoryEditorState.initial());

  Future<void> fetchFollowedUsers() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final followsResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = List<Map<String, dynamic>>.from(followsResponse)
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return;

      final profilesResponse = await client
          .from('profiles')
          .select('id, username, first_name, last_name, avatar_url')
          .inFilter('id', followingIds);

      state = state.copyWith(
        followedUsers: List<Map<String, dynamic>>.from(profilesResponse),
      );
    } catch (e) {
      debugPrint("Error fetching followed users: $e");
    }
  }

  void updateMentionSuggestions(String input) {
    if (input.isEmpty) {
      state = state.copyWith(mentionSuggestions: []);
      return;
    }
    final cleanInput = input.replaceFirst('@', '').toLowerCase();
    final suggestions = state.followedUsers.where((u) {
      final username = (u['username'] as String? ?? '').toLowerCase();
      return username.contains(cleanInput);
    }).toList();

    state = state.copyWith(mentionSuggestions: suggestions);
  }

  void addOverlay(StoryOverlayItem item) {
    state = state.copyWith(
      overlays: [...state.overlays, item],
      selectedOverlayId: item.id,
    );
  }

  void removeOverlay(String id) {
    state = state.copyWith(
      overlays: state.overlays.where((o) => o.id != id).toList(),
      clearSelectedOverlayId: state.selectedOverlayId == id,
    );
  }

  void updateOverlay(StoryOverlayItem item) {
    state = state.copyWith(
      overlays: state.overlays.map((o) => o.id == item.id ? item : o).toList(),
    );
  }

  void updateOverlayAndGuides(StoryOverlayItem item, double canvasWidth, double canvasHeight) {
    final centerX = canvasWidth / 2;
    final centerY = canvasHeight / 2;
    const threshold = 12.0;

    Offset position = item.position;
    bool showVertical = false;
    bool showHorizontal = false;
    bool showLeft = false;
    bool showRight = false;
    bool showTop = false;
    bool showBottom = false;
    bool isNearTrash = false;

    // Check proximity to vertical center
    if ((position.dx - centerX).abs() < threshold) {
      position = Offset(centerX, position.dy);
      showVertical = true;
    }

    // Check proximity to horizontal center
    if ((position.dy - centerY).abs() < threshold) {
      position = Offset(position.dx, centerY);
      showHorizontal = true;
    }

    // Margin guides
    const margin = 24.0;
    final itemWidth = item.size.width * item.scale;
    final itemHeight = item.size.height * item.scale;

    final leftBoundary = margin + itemWidth / 2;
    final rightBoundary = canvasWidth - margin - itemWidth / 2;
    final topBoundary = margin + itemHeight / 2;
    final bottomBoundary = canvasHeight - margin - itemHeight / 2;

    if ((position.dx - leftBoundary).abs() < threshold) {
      position = Offset(leftBoundary, position.dy);
      showLeft = true;
    }
    if ((position.dx - rightBoundary).abs() < threshold) {
      position = Offset(rightBoundary, position.dy);
      showRight = true;
    }
    if ((position.dy - topBoundary).abs() < threshold) {
      position = Offset(position.dx, topBoundary);
      showTop = true;
    }
    if ((position.dy - bottomBoundary).abs() < threshold) {
      position = Offset(position.dx, bottomBoundary);
      showBottom = true;
    }

    // Trash Proximity Check
    final trashX = centerX;
    final trashY = canvasHeight - 90.0;
    final distanceToTrash = (position - Offset(trashX, trashY)).distance;
    final detectionRadius = 70.0 + (itemWidth / 3).clamp(0.0, 120.0);
    isNearTrash = distanceToTrash < detectionRadius;

    if (isNearTrash) {
      showVertical = false;
      showHorizontal = false;
      showLeft = false;
      showRight = false;
      showTop = false;
      showBottom = false;
    }

    // Clamp the position to keep the item inside the screen bounds
    final halfWidth = (item.size.width * item.scale) / 2;
    final halfHeight = (item.size.height * item.scale) / 2;

    double minX = halfWidth;
    double maxX = canvasWidth - halfWidth;
    double minY = halfHeight;
    double maxY = canvasHeight - halfHeight;

    if (minX > maxX) {
      minX = canvasWidth / 2;
      maxX = canvasWidth / 2;
    }
    if (minY > maxY) {
      minY = canvasHeight / 2;
      maxY = canvasHeight / 2;
    }

    final clampedX = position.dx.clamp(minX, maxX);
    final clampedY = position.dy.clamp(minY, maxY);
    final finalItem = item.copyWith(
      position: Offset(clampedX, clampedY),
    );

    state = state.copyWith(
      overlays: state.overlays.map((o) => o.id == finalItem.id ? finalItem : o).toList(),
      isNearTrash: isNearTrash,
      showVerticalCenterGuide: showVertical,
      showHorizontalCenterGuide: showHorizontal,
      showLeftGuide: showLeft,
      showRightGuide: showRight,
      showTopGuide: showTop,
      showBottomGuide: showBottom,
    );
  }

  void selectOverlay(String? id) {
    if (id == null) {
      state = state.copyWith(clearSelectedOverlayId: true);
    } else {
      state = state.copyWith(selectedOverlayId: id);
    }
  }

  void setEditingText(bool editing) {
    state = state.copyWith(isEditingText: editing);
  }

  void setEditingMention(bool editing) {
    state = state.copyWith(isEditingMention: editing);
  }

  void updateTextStyling({
    Color? color,
    Color? bgColor,
    bool clearBgColor = false,
    String? fontFamily,
    TextAlign? alignment,
    bool? isBold,
    String? backgroundStyle,
    String? effect,
  }) {
    state = state.copyWith(
      selectedTextColor: color,
      selectedBgColor: bgColor,
      clearSelectedBgColor: clearBgColor,
      selectedFontFamily: fontFamily,
      selectedAlignment: alignment,
      selectedIsBold: isBold,
      selectedBackgroundStyle: backgroundStyle,
      selectedEffect: effect,
    );
  }

  void setAudioMuted(bool muted) {
    state = state.copyWith(isAudioMuted: muted);
  }

  void setDraggingState({required bool isDragging, required bool isNearTrash}) {
    state = state.copyWith(
      isDragging: isDragging,
      isNearTrash: isNearTrash,
    );
  }

  void updateGuides({
    bool? vertical,
    bool? horizontal,
    bool? left,
    bool? right,
    bool? top,
    bool? bottom,
  }) {
    state = state.copyWith(
      showVerticalCenterGuide: vertical,
      showHorizontalCenterGuide: horizontal,
      showLeftGuide: left,
      showRightGuide: right,
      showTopGuide: top,
      showBottomGuide: bottom,
    );
  }

  Future<void> publishStory({
    required String localFilePath,
    required double canvasWidth,
    required double canvasHeight,
    required VoidCallback onSuccess,
    required ValueChanged<String> onError,
  }) async {
    state = state.copyWith(isPublishing: true);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");

      final file = File(localFilePath);
      if (!await file.exists()) throw Exception("Media file does not exist");

      final fileExt = localFilePath.split('.').last;
      final fileName = '${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}_story.$fileExt';

      await client.storage.from('post-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

      // Serialize story overlays into json representation for backend storage
      final overlaysJson = state.overlays.map((item) {
        return {
          'type': item.type,
          'data': item.data,
          'normalizedX': item.position.dx / canvasWidth,
          'normalizedY': item.position.dy / canvasHeight,
          'scale': item.scale,
          'rotation': item.rotation,
          'width': item.size.width,
          'height': item.size.height,
        };
      }).toList();

      final storyResponse = await client.from('stories').insert({
        'user_id': currentUser.id,
        'media_url': publicUrl,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'overlays': overlaysJson,
      }).select().single();

      final storyId = storyResponse['id'] as String;

      // Process mentions and generate notifications
      final mentionOverlays = state.overlays.where((item) => item.type == 'mention').toList();
      for (final item in mentionOverlays) {
        final targetUser = (item.data as String).replaceAll('@', '').trim();
        if (targetUser.isNotEmpty) {
          try {
            final profile = await client
                .from('profiles')
                .select('id')
                .eq('username', targetUser)
                .maybeSingle();
            if (profile != null) {
              final receiverId = profile['id'] as String;
              if (receiverId != currentUser.id) {
                await client.from('notifications').insert({
                  'sender_id': currentUser.id,
                  'receiver_id': receiverId,
                  'type': 'mention',
                  'metadata': {
                    'story_id': storyId,
                    'media_url': publicUrl,
                  },
                });
              }
            }
          } catch (e) {
            debugPrint("Error creating mention notification for $targetUser: $e");
          }
        }
      }

      // Refresh social feed view model
      _ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
      onSuccess();
    } catch (e) {
      debugPrint("Error publishing story: $e");
      onError(e.toString());
    } finally {
      state = state.copyWith(isPublishing: false);
    }
  }
}
