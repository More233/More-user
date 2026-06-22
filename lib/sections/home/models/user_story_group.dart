class UserStoryGroup {
  final String userId;
  final String username;
  final String? avatarUrl;
  final List<String> mediaUrls;
  final List<DateTime> createdTimes;
  final List<String> storyIds;

  UserStoryGroup({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.mediaUrls,
    required this.createdTimes,
    required this.storyIds,
  });
}
