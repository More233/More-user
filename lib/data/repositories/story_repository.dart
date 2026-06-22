abstract class StoryRepository {
  Future<List<Map<String, dynamic>>> fetchActiveStories(List<String> userIds);

  Future<List<Map<String, dynamic>>> fetchStoryViewers(String storyId);

  Future<void> markStoryAsViewed({
    required String storyId,
    required String userId,
  });

  Future<void> deleteStory(String storyId);

  Future<void> sendStoryReply({
    required String senderId,
    required String receiverId,
    required String storyMediaUrl,
    required String replyText,
  });
}
