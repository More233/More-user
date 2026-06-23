import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../sections/home/models/collection_model.dart';
import 'collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(client: Supabase.instance.client);
});

class CollectionRepositoryImpl implements CollectionRepository {
  final SupabaseClient client;

  CollectionRepositoryImpl({required this.client});

  @override
  Future<List<CollectionModel>> fetchCollections(String userId) async {
    try {
      final colsResponse = await client
          .from('collections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final List<String> userColIds = [];
      for (final colData in colsResponse) {
        userColIds.add(colData['id'] as String);
      }

      dynamic postsResponse = [];
      if (userColIds.isNotEmpty) {
        postsResponse = await client
            .from('collection_posts')
            .select('collection_id, post_id')
            .inFilter('collection_id', userColIds);
      }

      final List<CollectionModel> collections = [];
      for (final colData in colsResponse) {
        final colId = colData['id'] as String;
        final name = colData['name'] as String;
        final coverUrl = colData['cover_image_url'] as String?;
        final isPrivate = colData['is_private'] as bool? ?? true;

        final List<String> postIds = [];
        if (postsResponse is List) {
          for (final item in postsResponse) {
            if (item['collection_id'] == colId) {
              postIds.add(item['post_id'] as String);
            }
          }
        }

        final sharedIdsRaw = colData['shared_user_ids'] as List?;
        final List<String> sharedUserIds = sharedIdsRaw != null
            ? List<String>.from(sharedIdsRaw.map((id) => id.toString()))
            : [];

        collections.add(
          CollectionModel(
            id: colId,
            name: name,
            coverImageUrl: coverUrl,
            postIds: postIds,
            isPrivate: isPrivate,
            sharedUserIds: sharedUserIds,
          ),
        );
      }
      return collections;
    } catch (e) {
      debugPrint("Error loading collections: $e");
      rethrow;
    }
  }

  @override
  Future<void> createCollection(String userId, String name, String? coverImageUrl, {List<String> sharedUserIds = const []}) async {
    await client.from('collections').insert({
      'name': name,
      'cover_image_url': coverImageUrl,
      'user_id': userId,
      'shared_user_ids': sharedUserIds,
    });
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await client.from('collections').delete().eq('id', collectionId);
  }

  @override
  Future<void> addPostToCollection(String collectionId, String postId) async {
    await client.from('collection_posts').upsert({
      'collection_id': collectionId,
      'post_id': postId,
    });
  }

  @override
  Future<void> removePostFromCollection(String collectionId, String postId) async {
    await client
        .from('collection_posts')
        .delete()
        .eq('collection_id', collectionId)
        .eq('post_id', postId);
  }

  @override
  Future<void> removePostFromAllCollections(String postId) async {
    await client.from('collection_posts').delete().eq('post_id', postId);
  }

  @override
  Future<void> updatePostBookmarkState(String postId, bool isBookmarked) async {
    await client
        .from('posts')
        .update({'is_bookmarked': isBookmarked})
        .eq('id', postId);
  }

  @override
  Future<String> getOrCreateSavedCollection(String userId) async {
    final existing = await client
        .from('collections')
        .select()
        .eq('user_id', userId)
        .eq('name', 'Saved')
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final insertResponse = await client.from('collections').insert({
      'name': 'Saved',
      'user_id': userId,
    }).select().single();

    return insertResponse['id'] as String;
  }
}
