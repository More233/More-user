import '../../sections/home/models/timeline_post.dart';

class FollowData {
  final Set<String> followedUsernames;
  final List<String> followedUserIds;

  FollowData({required this.followedUsernames, required this.followedUserIds});
}

abstract class PostRepository {
  Future<FollowData> fetchFollowData(String userId);
  Future<Set<String>> fetchFollows(String userId);

  Future<void> toggleFollow({
    required String followerId,
    required String username,
    required bool follow,
  });

  Future<void> createNotification({
    required String senderId,
    required String receiverId,
    required String type,
    String? postId,
    Map<String, dynamic>? metadata,
  });

  Future<List<TimelinePost>> fetchPosts(String? currentUserId);

  Future<List<TimelinePost>> fetchSocialFeed({
    required String userId,
    required List<String> followingIds,
  });

  Future<String?> fetchUserAvatar(String userId);

  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  });

  Future<void> updateBookmark({
    required String postId,
    required bool isBookmarked,
  });

  Future<void> deletePost(String postId);
}
