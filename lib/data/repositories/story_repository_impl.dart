import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(client: Supabase.instance.client);
});

class StoryRepositoryImpl implements StoryRepository {
  final SupabaseClient _client;

  StoryRepositoryImpl({required this._client});

  @override
  Future<List<Map<String, dynamic>>> fetchActiveStories(List<String> userIds) async {
    final response = await _client
        .from('stories')
        .select('*, user:profiles(id, username, first_name, last_name, avatar_url)')
        .inFilter('user_id', userIds)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchStoryViewers(String storyId) async {
    final response = await _client
        .from('story_views')
        .select('created_at, user:profiles(id, username, first_name, last_name, avatar_url)')
        .eq('story_id', storyId);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> markStoryAsViewed({
    required String storyId,
    required String userId,
  }) async {
    await _client.from('story_views').insert({
      'story_id': storyId,
      'user_id': userId,
    });
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _client.from('stories').delete().eq('id', storyId);
  }

  @override
  Future<void> sendStoryReply({
    required String senderId,
    required String receiverId,
    required String storyMediaUrl,
    required String replyText,
  }) async {
    // 1. Fetch existing threads for current user
    final threadsResponse = await _client
        .from('chat_threads')
        .select()
        .or('user1_id.eq.$senderId,user2_id.eq.$senderId');

    final threads = List<Map<String, dynamic>>.from(threadsResponse);
    final existingThreadIndex = threads.indexWhere(
      (t) => (t['user1_id'] == senderId && t['user2_id'] == receiverId) ||
             (t['user1_id'] == receiverId && t['user2_id'] == senderId),
    );

    String? threadId;
    if (existingThreadIndex != -1) {
      threadId = threads[existingThreadIndex]['id'];
    } else {
      // Create a new thread
      final insertResponse = await _client.from('chat_threads').insert({
        'user1_id': senderId,
        'user2_id': receiverId,
      }).select().single();
      threadId = insertResponse['id'];
    }

    if (threadId != null) {
      // Insert message replying to story
      await _client.from('chat_messages').insert({
        'thread_id': threadId,
        'sender_id': senderId,
        'message_type': 'text',
        'content': replyText,
      });
    }
  }
}
