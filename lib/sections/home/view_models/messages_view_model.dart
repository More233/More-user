import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/chat_repository_impl.dart';

class MessagesState {
  final List<Map<String, dynamic>> threads;
  final bool isLoading;

  MessagesState({
    required this.threads,
    required this.isLoading,
  });

  MessagesState copyWith({
    List<Map<String, dynamic>>? threads,
    bool? isLoading,
  }) {
    return MessagesState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final messagesViewModelProvider = StateNotifierProvider<MessagesViewModel, MessagesState>((ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return MessagesViewModel(chatRepository: chatRepo);
});

class MessagesViewModel extends StateNotifier<MessagesState> {
  final ChatRepository _chatRepository;
  RealtimeChannel? _messagesSubscription;
  RealtimeChannel? _threadsSubscription;
  String _currentUserId = '';

  MessagesViewModel({required this._chatRepository})
      : super(MessagesState(threads: [], isLoading: true));

  Future<void> init(String currentUserId) async {
    if (_currentUserId == currentUserId && state.threads.isNotEmpty) {
      return;
    }
    _currentUserId = currentUserId;
    if (_messagesSubscription != null) {
      Supabase.instance.client.removeChannel(_messagesSubscription!);
      _messagesSubscription = null;
    }
    if (_threadsSubscription != null) {
      Supabase.instance.client.removeChannel(_threadsSubscription!);
      _threadsSubscription = null;
    }
    state = state.copyWith(isLoading: true);
    await loadData();
    _subscribeToMessages();
    _subscribeToThreads();
  }

  Future<void> loadData() async {
    try {
      final populatedThreads = await _chatRepository.loadThreads(_currentUserId);
      state = state.copyWith(threads: populatedThreads, isLoading: false);
    } catch (e) {
      debugPrint("Error loading chat data: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void _subscribeToThreads() {
    final client = Supabase.instance.client;
    _threadsSubscription = client
        .channel('public:chat_threads_user')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_threads',
          callback: (payload) async {
            await loadData();
          },
        );
    _threadsSubscription?.subscribe();
  }

  void _subscribeToMessages() {
    _messagesSubscription = _chatRepository.subscribeToMessages(
      channelName: 'public:chat_messages',
      callback: (payload) async {
        final newRecord = payload?.newRecord;
        final oldRecord = payload?.oldRecord;
        final threadId = (newRecord?['thread_id'] ?? oldRecord?['thread_id']) as String?;
        if (threadId != null) {
          final isForOurThreads = state.threads.any((t) => t['thread']['id'] == threadId);
          if (isForOurThreads) {
            await loadData();
          }
        }
      },
    );
    _messagesSubscription?.subscribe();
  }

  @override
  void dispose() {
    if (_messagesSubscription != null) {
      Supabase.instance.client.removeChannel(_messagesSubscription!);
    }
    if (_threadsSubscription != null) {
      Supabase.instance.client.removeChannel(_threadsSubscription!);
    }
    super.dispose();
  }
}
