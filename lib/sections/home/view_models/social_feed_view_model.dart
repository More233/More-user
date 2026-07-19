import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/post_repository_impl.dart';
import '../../../data/repositories/story_repository.dart';
import '../../../data/repositories/story_repository_impl.dart';
import '../helpers/story_tracker.dart';
import '../models/social_feed_state.dart';
import '../models/timeline_post.dart';
import '../models/user_story_group.dart';

final socialFeedViewModelProvider = StateNotifierProvider<SocialFeedViewModel, SocialFeedState>((ref) {
  final postRepo = ref.watch(postRepositoryProvider);
  final storyRepo = ref.watch(storyRepositoryProvider);
  return SocialFeedViewModel(postRepository: postRepo, storyRepository: storyRepo);
});

class SocialFeedViewModel extends StateNotifier<SocialFeedState> {
  final PostRepository _postRepository;
  final StoryRepository _storyRepository;
  String? _currentUserId;

  SocialFeedViewModel({
    required this._postRepository,
    required this._storyRepository,
  }) : super(SocialFeedState.initial());

  Future<void> init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (_currentUserId == user.id && state.socialPosts.isNotEmpty) {
        return;
      }
      _currentUserId = user.id;
      state = state.copyWith(currentUserId: _currentUserId);
      await StoryTracker().init();
      await refreshFeed();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshFeed() async {
    if (_currentUserId == null) return;
    state = state.copyWith(isLoading: true, currentUserId: _currentUserId);
    try {
      final followData = await _postRepository.fetchFollowData(_currentUserId!);
      await Future.wait([
        fetchStories(followData.followedUserIds),
        fetchSocialFeed(followData.followedUserIds),
      ]);
    } catch (e) {
      debugPrint("Error refreshing social feed: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchStories(List<String> followedUserIds) async {
    if (_currentUserId == null) return;
    try {
      final userIds = List<String>.from(followedUserIds);
      if (!userIds.contains(_currentUserId!)) {
        userIds.add(_currentUserId!);
      }

      final storiesList = await _storyRepository.fetchActiveStories(userIds);

      // Group stories by user
      final Map<String, UserStoryGroup> grouped = {};
      for (var row in storiesList) {
        final user = row['user'];
        if (user == null) continue;

        final uId = user['id'] as String;
        final username = user['username'] as String? ?? 'unknown';
        final avatarUrl = user['avatar_url'] as String?;
        final mediaUrl = row['media_url'] as String;
        final createdAtStr = row['created_at'] as String;
        final createdAt = DateTime.parse(createdAtStr);
        final storyId = row['id'] as String;
        final storyOverlays = row['overlays'] as List<dynamic>? ?? [];

        if (grouped.containsKey(uId)) {
          grouped[uId]!.mediaUrls.add(mediaUrl);
          grouped[uId]!.createdTimes.add(createdAt);
          grouped[uId]!.storyIds.add(storyId);
          grouped[uId]!.overlays.add(storyOverlays);
        } else {
          grouped[uId] = UserStoryGroup(
            userId: uId,
            username: username,
            avatarUrl: avatarUrl,
            mediaUrls: [mediaUrl],
            createdTimes: [createdAt],
            storyIds: [storyId],
            overlays: [storyOverlays],
          );
        }
      }

      state = state.copyWith(storyGroups: grouped.values.toList());
    } catch (e) {
      debugPrint("Error fetching stories: $e");
    }
  }

  Future<void> fetchSocialFeed(List<String> followedUserIds) async {
    if (_currentUserId == null) return;
    try {
      final followingIds = List<String>.from(followedUserIds);
      if (!followingIds.contains(_currentUserId!)) {
        followingIds.add(_currentUserId!);
      }

      final fetchedPosts = await _postRepository.fetchSocialFeed(
        userId: _currentUserId!,
        followingIds: followingIds,
      );

      state = state.copyWith(socialPosts: fetchedPosts);
    } catch (e) {
      debugPrint("Error fetching social feed: $e");
    }
  }

  void hideFindFriendsCard() {
    state = state.copyWith(showFindFriendsCard: false);
  }

  void toggleLikeLocal(String postId) {
    final index = state.socialPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.socialPosts[index];
    final isLikedNow = !post.isLiked;

    final updatedPosts = List<TimelinePost>.from(state.socialPosts);
    updatedPosts[index] = post.copyWith(
      isLiked: isLikedNow,
      likesCount: post.likesCount + (isLikedNow ? 1 : -1),
    );
    state = state.copyWith(socialPosts: updatedPosts);
  }

  void toggleBookmarkLocal(String postId) {
    final index = state.socialPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.socialPosts[index];
    final isBookmarkedNow = !post.isBookmarked;

    final updatedPosts = List<TimelinePost>.from(state.socialPosts);
    updatedPosts[index] = post.copyWith(isBookmarked: isBookmarkedNow);
    state = state.copyWith(socialPosts: updatedPosts);
  }
}
