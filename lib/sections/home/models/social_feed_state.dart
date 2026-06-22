import 'user_story_group.dart';
import '../models/timeline_post.dart';

class SocialFeedState {
  final bool isLoading;
  final List<TimelinePost> socialPosts;
  final List<UserStoryGroup> storyGroups;
  final bool showFindFriendsCard;

  SocialFeedState({
    required this.isLoading,
    required this.socialPosts,
    required this.storyGroups,
    required this.showFindFriendsCard,
  });

  factory SocialFeedState.initial() {
    return SocialFeedState(
      isLoading: true,
      socialPosts: [],
      storyGroups: [],
      showFindFriendsCard: true,
    );
  }

  SocialFeedState copyWith({
    bool? isLoading,
    List<TimelinePost>? socialPosts,
    List<UserStoryGroup>? storyGroups,
    bool? showFindFriendsCard,
  }) {
    return SocialFeedState(
      isLoading: isLoading ?? this.isLoading,
      socialPosts: socialPosts ?? this.socialPosts,
      storyGroups: storyGroups ?? this.storyGroups,
      showFindFriendsCard: showFindFriendsCard ?? this.showFindFriendsCard,
    );
  }
}
