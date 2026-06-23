import '../../sections/home/models/collection_model.dart';

abstract class CollectionRepository {
  Future<List<CollectionModel>> fetchCollections(String userId);
  Future<void> createCollection(String userId, String name, String? coverImageUrl, {List<String> sharedUserIds = const []});
  Future<void> deleteCollection(String collectionId);
  Future<void> addPostToCollection(String collectionId, String postId);
  Future<void> removePostFromCollection(String collectionId, String postId);
  Future<void> removePostFromAllCollections(String postId);
  Future<void> updatePostBookmarkState(String postId, bool isBookmarked);
  Future<String> getOrCreateSavedCollection(String userId);
}
