import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(client: Supabase.instance.client);
});

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _client;

  ChatRepositoryImpl({required this._client});

  @override
  Future<List<Map<String, dynamic>>> loadThreads(String currentUserId) async {
    final response = await _client
        .from('chat_threads')
        .select('''
          id,
          user1_id,
          user2_id,
          created_at,
          updated_at,
          user1:profiles!chat_threads_user1_id_fkey(id, first_name, last_name, username, avatar_url),
          user2:profiles!chat_threads_user2_id_fkey(id, first_name, last_name, username, avatar_url),
          chat_messages(id, content, message_type, sender_id, created_at, is_read)
        ''')
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .order('created_at', referencedTable: 'chat_messages', ascending: false)
        .limit(1, referencedTable: 'chat_messages');

    final rawThreads = List<Map<String, dynamic>>.from(response as List);
    final List<String> threadIds = rawThreads.map((t) => t['id'] as String).toList();

    // Fetch unread messages to count them per thread, scoped to the current user's threads
    final Map<String, int> unreadCounts = {};
    if (threadIds.isNotEmpty) {
      final unreadResponse = await _client
          .from('chat_messages')
          .select('thread_id')
          .inFilter('thread_id', threadIds)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
      
      final unreadList = List<Map<String, dynamic>>.from(unreadResponse as List);
      for (var msg in unreadList) {
        final tId = msg['thread_id'] as String;
        unreadCounts[tId] = (unreadCounts[tId] ?? 0) + 1;
      }
    }

    List<Map<String, dynamic>> populatedThreads = [];

    for (var threadData in rawThreads) {
      final threadId = threadData['id'];
      final user1Id = threadData['user1_id'];
      final user2Id = threadData['user2_id'];
      final createdAt = threadData['created_at'];
      final updatedAt = threadData['updated_at'];

      final user1 = threadData['user1'] as Map<String, dynamic>?;
      final user2 = threadData['user2'] as Map<String, dynamic>?;

      final isUser1Me = user1Id == currentUserId;
      final otherProfile = isUser1Me ? user2 : user1;
      
      final messagesList = threadData['chat_messages'] as List<dynamic>?;
      final lastMsg = (messagesList != null && messagesList.isNotEmpty)
          ? messagesList.first as Map<String, dynamic>
          : null;

      populatedThreads.add({
        'thread': {
          'id': threadId,
          'user1_id': user1Id,
          'user2_id': user2Id,
          'created_at': createdAt,
          'updated_at': updatedAt,
        },
        'otherProfile': otherProfile ?? {
          'id': isUser1Me ? user2Id : user1Id,
          'first_name': 'Unknown',
          'last_name': 'User',
          'username': 'unknown',
          'avatar_url': null,
        },
        'lastMessage': lastMsg,
        'unreadCount': unreadCounts[threadId] ?? 0,
      });
    }

    // Sort threads by last message's created_at or thread's updated_at descending
    populatedThreads.sort((a, b) {
      final aTimeStr = a['lastMessage']?['created_at'] ?? a['thread']['updated_at'];
      final bTimeStr = b['lastMessage']?['created_at'] ?? b['thread']['updated_at'];
      final aTime = DateTime.parse(aTimeStr);
      final bTime = DateTime.parse(bTimeStr);
      return bTime.compareTo(aTime);
    });

    return populatedThreads;
  }

  @override
  Stream<List<Map<String, dynamic>>> streamMessages(String threadId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
  }

  @override
  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String messageType,
    required String content,
    int? mediaDuration,
  }) async {
    await _client.from('chat_messages').insert({
      'thread_id': threadId,
      'sender_id': senderId,
      'message_type': messageType,
      'content': content,
      'media_duration': mediaDuration,
    });
  }

  @override
  Future<void> markMessagesAsRead({
    required String threadId,
    required String currentUserId,
  }) async {
    await _client
        .from('chat_messages')
        .update({'is_read': true})
        .eq('thread_id', threadId)
        .neq('sender_id', currentUserId)
        .eq('is_read', false);
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
    required String currentUserId,
  }) async {
    // Implement soft delete by appending currentUserId to deleted_by uuid array
    final response = await _client
        .from('chat_messages')
        .select('deleted_by')
        .eq('id', messageId)
        .single();
    
    final currentDeletedBy = List<String>.from(response['deleted_by'] ?? []);
    if (!currentDeletedBy.contains(currentUserId)) {
      currentDeletedBy.add(currentUserId);
      await _client
          .from('chat_messages')
          .update({'deleted_by': currentDeletedBy})
          .eq('id', messageId);
    }
  }

  @override
  Future<String> uploadChatMedia({
    required String threadId,
    required File file,
    required bool isAudio,
  }) async {
    final folder = isAudio ? 'chat_audio' : 'chat_images';
    final ext = isAudio ? 'm4a' : 'jpg';
    final fileName = '$folder/${threadId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('post-images').upload(
      fileName,
      file,
      fileOptions: const FileOptions(cacheControl: '31536000', upsert: true),
    );

    return _client.storage.from('post-images').getPublicUrl(fileName);
  }

  @override
  RealtimeChannel subscribeToMessages({
    required String channelName,
    required void Function(dynamic payload) callback,
  }) {
    return _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: callback,
        );
  }
}
