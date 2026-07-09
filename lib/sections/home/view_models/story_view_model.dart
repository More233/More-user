import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/story_repository.dart';
import '../../../data/repositories/story_repository_impl.dart';
import '../helpers/story_tracker.dart';
import '../models/story_view_state.dart';
import '../models/user_story_group.dart';

// Expose StoryViewModel family provider taking an initial index parameter
final storyViewModelProvider = StateNotifierProvider.autoDispose
    .family<StoryViewModel, StoryViewState, int>((ref, initialGroupIndex) {
  final storyRepo = ref.watch(storyRepositoryProvider);
  return StoryViewModel(
    storyRepository: storyRepo,
    initialGroupIndex: initialGroupIndex,
  );
});

class StoryViewModel extends StateNotifier<StoryViewState> {
  final StoryRepository _storyRepository;

  StoryViewModel({
    required this._storyRepository,
    required int initialGroupIndex,
  }) : super(StoryViewState.initial(initialGroupIndex: initialGroupIndex));

  Future<void> startStory(List<UserStoryGroup> storyGroups) async {
    final currentGroupIndex = state.currentGroupIndex;
    final currentStoryIndex = state.currentStoryIndex;

    if (storyGroups.isEmpty || currentGroupIndex >= storyGroups.length) return;

    final currentGroup = storyGroups[currentGroupIndex];
    if (currentStoryIndex >= currentGroup.mediaUrls.length) return;

    final currentMediaUrl = currentGroup.mediaUrls[currentStoryIndex];
    final currentStoryId = currentGroup.storyIds[currentStoryIndex];

    // Mark as viewed locally
    StoryTracker().markAsViewed(currentMediaUrl);

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      if (currentGroup.userId == currentUser.id) {
        await fetchStoryViews(currentStoryId);
      } else {
        await recordStoryView(currentStoryId, currentUser.id);
      }
    }
  }

  Future<void> recordStoryView(String storyId, String userId) async {
    try {
      await _storyRepository.markStoryAsViewed(
        storyId: storyId,
        userId: userId,
      );
    } catch (e) {
      debugPrint("Note: view already recorded or error: $e");
    }
  }

  Future<void> fetchStoryViews(String storyId) async {
    try {
      final viewersList = await _storyRepository.fetchStoryViewers(storyId);
      if (!mounted) return;
      state = state.copyWith(
        viewers: viewersList,
        viewsCount: viewersList.length,
      );
    } catch (e) {
      debugPrint("Error fetching story views: $e");
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _storyRepository.deleteStory(storyId);
    } catch (e) {
      debugPrint("Error deleting story: $e");
      rethrow;
    }
  }

  Future<void> sendDM(String content, List<UserStoryGroup> storyGroups) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    if (mounted) {
      state = state.copyWith(isSending: true);
    }

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      final currentUserId = currentUser.id;
      final otherUserId = storyGroups[state.currentGroupIndex].userId;

      if (currentUserId == otherUserId) {
        throw Exception("Cannot send a reply to your own story");
      }

      final currentStoryIndex = state.currentStoryIndex;
      final currentGroup = storyGroups[state.currentGroupIndex];
      final currentMediaUrl = currentGroup.mediaUrls[currentStoryIndex];

      await _storyRepository.sendStoryReply(
        senderId: currentUserId,
        receiverId: otherUserId,
        storyMediaUrl: currentMediaUrl,
        replyText: cleanContent,
      );
    } catch (e) {
      debugPrint("Error sending story reply: $e");
      rethrow;
    } finally {
      if (mounted) {
        state = state.copyWith(isSending: false);
      }
    }
  }

  void nextStory(List<UserStoryGroup> storyGroups, VoidCallback onCompleted) {
    if (state.isSending) return;

    final currentGroupIndex = state.currentGroupIndex;
    final currentStoryIndex = state.currentStoryIndex;

    final currentGroup = storyGroups[currentGroupIndex];
    if (currentStoryIndex < currentGroup.mediaUrls.length - 1) {
      state = state.copyWith(currentStoryIndex: currentStoryIndex + 1);
      startStory(storyGroups);
    } else {
      if (currentGroupIndex < storyGroups.length - 1) {
        state = state.copyWith(
          currentGroupIndex: currentGroupIndex + 1,
          currentStoryIndex: 0,
          isReactionTrayOpen: false,
        );
        startStory(storyGroups);
      } else {
        onCompleted();
      }
    }
  }

  void previousStory(List<UserStoryGroup> storyGroups) {
    if (state.isSending) return;

    final currentGroupIndex = state.currentGroupIndex;
    final currentStoryIndex = state.currentStoryIndex;

    if (currentStoryIndex > 0) {
      state = state.copyWith(currentStoryIndex: currentStoryIndex - 1);
      startStory(storyGroups);
    } else {
      if (currentGroupIndex > 0) {
        state = state.copyWith(
          currentGroupIndex: currentGroupIndex - 1,
          currentStoryIndex: storyGroups[currentGroupIndex - 1].mediaUrls.length - 1,
          isReactionTrayOpen: false,
        );
        startStory(storyGroups);
      } else {
        startStory(storyGroups);
      }
    }
  }

  void setReactionTrayOpen(bool open) {
    state = state.copyWith(isReactionTrayOpen: open);
  }

  void nextGroup(List<UserStoryGroup> storyGroups, VoidCallback onCompleted) {
    final currentGroupIndex = state.currentGroupIndex;
    if (currentGroupIndex < storyGroups.length - 1) {
      state = state.copyWith(
        currentGroupIndex: currentGroupIndex + 1,
        currentStoryIndex: 0,
        isReactionTrayOpen: false,
      );
      startStory(storyGroups);
    } else {
      onCompleted();
    }
  }

  void previousGroup(List<UserStoryGroup> storyGroups) {
    final currentGroupIndex = state.currentGroupIndex;
    if (currentGroupIndex > 0) {
      state = state.copyWith(
        currentGroupIndex: currentGroupIndex - 1,
        currentStoryIndex: 0,
        isReactionTrayOpen: false,
      );
      startStory(storyGroups);
    }
  }
}
