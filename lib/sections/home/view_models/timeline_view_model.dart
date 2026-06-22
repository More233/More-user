import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/post_repository_impl.dart';
import '../models/timeline_post.dart';
import '../models/timeline_state.dart';

final timelineViewModelProvider = StateNotifierProvider.autoDispose<TimelineViewModel, TimelineState>((ref) {
  final postRepo = ref.watch(postRepositoryProvider);
  return TimelineViewModel(postRepository: postRepo);
});

class TimelineViewModel extends StateNotifier<TimelineState> {
  final PostRepository _postRepository;
  String? _currentUserId;

  TimelineViewModel({required this._postRepository})
      : super(TimelineState.initial());

  Future<void> init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      await refreshAll();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshAll() async {
    if (_currentUserId == null) return;
    state = state.copyWith(isLoading: true);
    await Future.wait([
      loadPosts(),
      loadUserProfile(),
      loadFollows(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadPosts() async {
    try {
      final fetchedPosts = await _postRepository.fetchPosts(_currentUserId);
      state = state.copyWith(
        posts: fetchedPosts,
        isFirstCheckIn: fetchedPosts.isEmpty,
      );
    } catch (e) {
      debugPrint("Error loading posts: $e");
    }
  }

  Future<void> loadUserProfile() async {
    if (_currentUserId == null) return;
    try {
      final avatar = await _postRepository.fetchUserAvatar(_currentUserId!);
      state = state.copyWith(currentUserAvatarUrl: avatar);
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    }
  }

  Future<void> loadFollows() async {
    if (_currentUserId == null) return;
    try {
      final follows = await _postRepository.fetchFollows(_currentUserId!);
      state = state.copyWith(followedUsernames: follows);
    } catch (e) {
      debugPrint("Error loading follows: $e");
    }
  }

  Future<void> toggleFollow(String username, bool follow) async {
    if (_currentUserId == null) return;
    try {
      final updatedFollows = Set<String>.from(state.followedUsernames);
      if (follow) {
        updatedFollows.add(username);
      } else {
        updatedFollows.remove(username);
      }
      state = state.copyWith(followedUsernames: updatedFollows);

      await _postRepository.toggleFollow(
        followerId: _currentUserId!,
        username: username,
        follow: follow,
      );
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    }
  }

  Future<void> toggleLike(String postId) async {
    if (_currentUserId == null) return;
    try {
      final index = state.posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      final post = state.posts[index];
      final isLikedNow = !post.isLiked;

      final updatedPosts = List<TimelinePost>.from(state.posts);
      updatedPosts[index] = post.copyWith(
        isLiked: isLikedNow,
        likesCount: post.likesCount + (isLikedNow ? 1 : -1),
      );
      state = state.copyWith(posts: updatedPosts);

      await _postRepository.toggleLike(
        postId: postId,
        userId: _currentUserId!,
        isLiked: isLikedNow,
      );
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  Future<void> updateBookmarkState(String postId, bool isBookmarked) async {
    try {
      final index = state.posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final updatedPosts = List<TimelinePost>.from(state.posts);
        updatedPosts[index] = state.posts[index].copyWith(isBookmarked: isBookmarked);
        state = state.copyWith(posts: updatedPosts);
      }

      await _postRepository.updateBookmark(
        postId: postId,
        isBookmarked: isBookmarked,
      );
    } catch (e) {
      debugPrint("Error updating bookmark: $e");
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final updatedPosts = List<TimelinePost>.from(state.posts)..removeWhere((p) => p.id == postId);
      state = state.copyWith(posts: updatedPosts);

      await _postRepository.deletePost(postId);
    } catch (e) {
      debugPrint("Error deleting post: $e");
      rethrow;
    }
  }

  void setSelectedTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  void setSelectedNavIndex(int index) {
    state = state.copyWith(selectedNavIndex: index);
  }

  void startOnboardingFlow() {
    state = state.copyWith(showCoachmark: false);
  }

  void setShowCoachmark(bool show) {
    state = state.copyWith(showCoachmark: show);
  }

  void completeFirstCheckIn() {
    state = state.copyWith(
      isFirstCheckIn: false,
      userCoins: 300,
    );
  }
}
