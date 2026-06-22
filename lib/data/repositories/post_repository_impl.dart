import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../sections/home/models/timeline_post.dart';
import 'post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(client: Supabase.instance.client);
});

class PostRepositoryImpl implements PostRepository {
  final SupabaseClient _client;

  PostRepositoryImpl({required this._client});

  @override
  Future<Set<String>> fetchFollows(String userId) async {
    final List<dynamic> response = await _client
        .from('follows')
        .select('following_id, profiles!follows_following_id_fkey(username)')
        .eq('follower_id', userId);

    final Set<String> followingUsernames = {};
    for (var row in response) {
      if (row['profiles'] != null && row['profiles']['username'] != null) {
        followingUsernames.add(row['profiles']['username'] as String);
      }
    }
    return followingUsernames;
  }

  @override
  Future<void> toggleFollow({
    required String followerId,
    required String username,
    required bool follow,
  }) async {
    final profileResponse = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    if (profileResponse == null) return;
    final followingId = profileResponse['id'] as String;

    if (follow) {
      await _client.from('follows').upsert({
        'follower_id': followerId,
        'following_id': followingId,
      });

      await createNotification(
        senderId: followerId,
        receiverId: followingId,
        type: 'follow',
      );
    } else {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    }
  }

  @override
  Future<void> createNotification({
    required String senderId,
    required String receiverId,
    required String type,
    String? postId,
    Map<String, dynamic>? metadata,
  }) async {
    if (senderId == receiverId) return;

    await _client.from('notifications').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type,
      'post_id': postId,
      'metadata': ?metadata,
    });
  }

  @override
  Future<List<TimelinePost>> fetchPosts(String? currentUserId) async {
    final List<dynamic> response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    Set<String> likedPostIds = {};
    if (currentUserId != null) {
      final likesResponse = await _client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', currentUserId);
      likedPostIds = List<Map<String, dynamic>>.from(likesResponse)
          .map((l) => l['post_id'] as String)
          .toSet();
    }

    Set<String> bookmarkedPostIds = {};
    if (currentUserId != null) {
      final collectionsResponse = await _client
          .from('collections')
          .select('id')
          .eq('user_id', currentUserId);
      final collectionIds = List<Map<String, dynamic>>.from(collectionsResponse)
          .map((c) => c['id'] as String)
          .toList();
      if (collectionIds.isNotEmpty) {
        final collectionPostsResponse = await _client
            .from('collection_posts')
            .select('post_id')
            .inFilter('collection_id', collectionIds);
        bookmarkedPostIds = List<Map<String, dynamic>>.from(collectionPostsResponse)
            .map((cp) => cp['post_id'] as String)
            .toSet();
      }
    }

    return response
        .map((postData) {
          final post = TimelinePost.fromMap(postData as Map<String, dynamic>);
          return post.copyWith(
            isLiked: likedPostIds.contains(post.id),
            isBookmarked: bookmarkedPostIds.contains(post.id),
          );
        })
        .toList();
  }

  @override
  Future<List<TimelinePost>> fetchSocialFeed({
    required String userId,
    required List<String> followingIds,
  }) async {
    if (followingIds.isEmpty) return [];

    final likesResponse = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId);
    final likedPostIds = List<Map<String, dynamic>>.from(likesResponse)
        .map((l) => l['post_id'] as String)
        .toSet();

    final collectionsResponse = await _client
        .from('collections')
        .select('id')
        .eq('user_id', userId);
    final collectionIds = List<Map<String, dynamic>>.from(collectionsResponse)
        .map((c) => c['id'] as String)
        .toList();

    Set<String> bookmarkedPostIds = {};
    if (collectionIds.isNotEmpty) {
      final collectionPostsResponse = await _client
          .from('collection_posts')
          .select('post_id')
          .inFilter('collection_id', collectionIds);
      bookmarkedPostIds = List<Map<String, dynamic>>.from(collectionPostsResponse)
          .map((cp) => cp['post_id'] as String)
          .toSet();
    }

    final postsResponse = await _client
        .from('posts')
        .select('*, author:profiles!posts_user_id_fkey(id, username, first_name, last_name, avatar_url)')
        .inFilter('user_id', followingIds)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(postsResponse).map((postData) {
      final post = TimelinePost.fromMap(postData);
      return post.copyWith(
        isLiked: likedPostIds.contains(post.id),
        isBookmarked: bookmarkedPostIds.contains(post.id),
      );
    }).toList();
  }

  @override
  Future<String?> fetchUserAvatar(String userId) async {
    final data = await _client
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    return data?['avatar_url'] as String?;
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    final postResponse = await _client
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (postResponse == null) return;
    final authorId = postResponse['user_id'] as String;

    if (isLiked) {
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });

      await createNotification(
        senderId: userId,
        receiverId: authorId,
        type: 'like',
        postId: postId,
      );
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }

  @override
  Future<void> updateBookmark({
    required String postId,
    required bool isBookmarked,
  }) async {
    await _client
        .from('posts')
        .update({'is_bookmarked': isBookmarked})
        .eq('id', postId);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }
}
