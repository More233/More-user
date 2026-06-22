import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatRepository {
  Future<List<Map<String, dynamic>>> loadThreads(String currentUserId);
  
  Stream<List<Map<String, dynamic>>> streamMessages(String threadId);
  
  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String messageType,
    required String content,
    int? mediaDuration,
  });
  
  Future<void> markMessagesAsRead({
    required String threadId,
    required String currentUserId,
  });
  
  Future<void> deleteMessage({
    required String messageId,
    required String currentUserId,
  });
  
  Future<String> uploadChatMedia({
    required String threadId,
    required File file,
    required bool isAudio,
  });
  
  RealtimeChannel subscribeToMessages({
    required String channelName,
    required void Function(dynamic payload) callback,
  });
}
