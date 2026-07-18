import 'user_story_group.dart';
import '../models/timeline_post.dart';

class SocialFeedState {
  final bool isLoading;
  final List<TimelinePost> socialPosts;
  final List<UserStoryGroup> storyGroups;
  final bool showFindFriendsCard;
  final String? currentUserId;

  SocialFeedState({
    required this.isLoading,
    required this.socialPosts,
    required this.storyGroups,
    required this.showFindFriendsCard,
    this.currentUserId,
  });

  factory SocialFeedState.initial() {
    return SocialFeedState(
      isLoading: true,
      socialPosts: [],
      storyGroups: [],
      showFindFriendsCard: true,
      currentUserId: null,
    );
  }

  SocialFeedState copyWith({
    bool? isLoading,
    List<TimelinePost>? socialPosts,
    List<UserStoryGroup>? storyGroups,
    bool? showFindFriendsCard,
    String? currentUserId,
  }) {
    return SocialFeedState(
      isLoading: isLoading ?? this.isLoading,
      socialPosts: socialPosts ?? this.socialPosts,
      storyGroups: storyGroups ?? this.storyGroups,
      showFindFriendsCard: showFindFriendsCard ?? this.showFindFriendsCard,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
