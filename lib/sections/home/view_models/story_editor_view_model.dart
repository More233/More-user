import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_editor_state.dart';
import '../models/story_overlay_item.dart';
import '../models/user_story_group.dart';
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
    double? fontSize,
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
      selectedFontSize: fontSize,
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
    required List<String> hiddenMentionUserIds,
    required VoidCallback onSuccess,
    required ValueChanged<String> onError,
  }) async {
    state = state.copyWith(isPublishing: true);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      
      if (currentUser == null) {
        final mockUserId = 'guest_user_id';
        final mockUsername = 'guest_user';
        final mockAvatar = 'assets/home/images/avatar_placeholder.png';

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

        final localStoryGroup = UserStoryGroup(
          userId: mockUserId,
          username: mockUsername,
          avatarUrl: mockAvatar,
          mediaUrls: [localFilePath],
          createdTimes: [DateTime.now()],
          storyIds: ['local_story_${DateTime.now().millisecondsSinceEpoch}'],
          overlays: [overlaysJson],
        );

        final feedViewModel = _ref.read(socialFeedViewModelProvider.notifier);
        final currentGroups = List<UserStoryGroup>.from(feedViewModel.state.storyGroups);
        currentGroups.removeWhere((g) => g.userId == mockUserId);
        currentGroups.insert(0, localStoryGroup);

        feedViewModel.state = feedViewModel.state.copyWith(
          storyGroups: currentGroups,
          currentUserId: mockUserId,
        );

        state = state.copyWith(isPublishing: false);
        onSuccess();
        return;
      }

      final file = File(localFilePath);
      if (!await file.exists()) throw Exception("Media file does not exist");

      final fileExt = localFilePath.split('.').last;
      final fileName = '${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}_story.$fileExt';

      await client.storage.from('post-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '31536000', upsert: true),
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

      // Extract and deduplicate all mentioned receiver IDs
      final Set<String> mentionReceiverIds = {};

      // 1. Add hidden mentions selected via bottom sheet
      mentionReceiverIds.addAll(hiddenMentionUserIds);

      // 2. Parse from visible overlays (both 'mention' type and 'text' type containing @username)
      final RegExp mentionRegex = RegExp(r'@([a-zA-Z0-9_\.]+)');
      for (final item in state.overlays) {
        String? textToParse;
        if (item.type == 'mention') {
          textToParse = item.data as String?;
        } else if (item.type == 'text') {
          final dataMap = item.data as Map<String, dynamic>?;
          textToParse = dataMap?['text'] as String?;
        }

        if (textToParse != null && textToParse.isNotEmpty) {
          final matches = mentionRegex.allMatches(textToParse);
          for (final match in matches) {
            final targetUsername = match.group(1);
            if (targetUsername != null && targetUsername.isNotEmpty) {
              try {
                final profile = await client
                    .from('profiles')
                    .select('id')
                    .eq('username', targetUsername)
                    .maybeSingle();
                if (profile != null) {
                  final receiverId = profile['id'] as String;
                  mentionReceiverIds.add(receiverId);
                }
              } catch (e) {
                debugPrint("Error looking up profile for username $targetUsername: $e");
              }
            }
          }
        }
      }

      // Process notifications & chat messages for all unique mentions
      for (final receiverId in mentionReceiverIds) {
        if (receiverId == currentUser.id) continue;
        try {
          // Send push notification
          await client.from('notifications').insert({
            'sender_id': currentUser.id,
            'receiver_id': receiverId,
            'type': 'mention',
            'metadata': {
              'story_id': storyId,
              'media_url': publicUrl,
            },
          });

          // Send chat mention messages (thread setup + image + text)
          final threadsResponse = await client
              .from('chat_threads')
              .select()
              .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}');

          final threads = List<Map<String, dynamic>>.from(threadsResponse);
          final existingThreadIndex = threads.indexWhere(
            (t) => (t['user1_id'] == currentUser.id && t['user2_id'] == receiverId) ||
                   (t['user1_id'] == receiverId && t['user2_id'] == currentUser.id),
          );

          String? threadId;
          if (existingThreadIndex != -1) {
            threadId = threads[existingThreadIndex]['id'];
          } else {
            final insertResponse = await client.from('chat_threads').insert({
              'user1_id': currentUser.id,
              'user2_id': receiverId,
            }).select().single();
            threadId = insertResponse['id'];
          }

          if (threadId != null) {
            // Send single story_share message containing the story media URL
            await client.from('chat_messages').insert({
              'thread_id': threadId,
              'sender_id': currentUser.id,
              'message_type': 'story_share',
              'content': publicUrl,
            });
          }
        } catch (e) {
          debugPrint("Error processing mention actions for $receiverId: $e");
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
