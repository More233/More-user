import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/chat_repository_impl.dart';
import '../models/conversation_state.dart';

final conversationViewModelProvider = StateNotifierProvider.autoDispose
    .family<ConversationViewModel, ConversationState, String>((ref, threadId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return ConversationViewModel(
    chatRepository: chatRepo,
    threadId: threadId,
  );
});

class ConversationViewModel extends StateNotifier<ConversationState> {
  final ChatRepository _chatRepository;
  final String _threadId;
  late String _currentUserId;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<Duration>? _playerPositionSubscription;

  Timer? _playbackTimer;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;

  ConversationViewModel({
    required this._chatRepository,
    required this._threadId,
  }) : super(ConversationState.initial()) {
    _initAudioPlayerListeners();
  }

  void init(String currentUserId) {
    _currentUserId = currentUserId;
    _checkMicPermission();
    _subscribeToMessages();
  }

  void _initAudioPlayerListeners() {
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      state = state.copyWith(playbackProgress: 1.0, clearActiveAudio: true);
    });

    _playerPositionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (state.activeAudioId != null && state.activeAudioDuration > 0) {
        double progress = pos.inMilliseconds / (state.activeAudioDuration * 1000);
        if (progress > 1.0) progress = 1.0;
        state = state.copyWith(playbackProgress: progress);
      }
    });
  }

  Future<void> _checkMicPermission() async {
    try {
      final hasPerm = await _audioRecorder.hasPermission();
      state = state.copyWith(hasMicPermission: hasPerm);
    } catch (e) {
      debugPrint("Error checking mic permission: $e");
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.streamMessages(_threadId).listen((data) {
      final filtered = data.where((msg) {
        final List<dynamic>? deletedBy = msg['deleted_by'] as List<dynamic>?;
        if (deletedBy == null) return true;
        return !deletedBy.contains(_currentUserId);
      }).toList();

      state = state.copyWith(
        messages: filtered,
        isLoadingMessages: false,
      );

      markMessagesAsRead();
    });
  }

  Future<void> markMessagesAsRead() async {
    try {
      await _chatRepository.markMessagesAsRead(
        threadId: _threadId,
        currentUserId: _currentUserId,
      );
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    try {
      await _chatRepository.sendMessage(
        threadId: _threadId,
        senderId: _currentUserId,
        messageType: 'text',
        content: cleanText,
      );
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> sendImage(File file) async {
    try {
      final publicUrl = await _chatRepository.uploadChatMedia(
        threadId: _threadId,
        file: file,
        isAudio: false,
      );

      await _chatRepository.sendMessage(
        threadId: _threadId,
        senderId: _currentUserId,
        messageType: 'image',
        content: publicUrl,
      );
    } catch (e) {
      debugPrint("Error sending image: $e");
      rethrow;
    }
  }

  Future<void> deleteMessageForMe(Map<String, dynamic> msg) async {
    try {
      await _chatRepository.deleteMessage(
        messageId: msg['id'],
        currentUserId: _currentUserId,
      );
    } catch (e) {
      debugPrint("Error deleting message for me: $e");
      rethrow;
    }
  }

  Future<void> deleteMessageForEveryone(Map<String, dynamic> msg) async {
    try {
      // Direct delete query using Supabase
      await _chatRepository.deleteMessage(
        messageId: msg['id'],
        currentUserId: _currentUserId,
      );
      // Wait, repository implementation only does soft delete on deleteMessage?
      // Let's check repository impl. Yes, it updates deleted_by.
      // But for everyone, we might want to actually delete from DB.
      // Let's call the repository's direct delete or implement a custom delete if needed.
      // Wait, let's look at the repository impl:
      // it only had `deleteMessage` which did soft delete.
      // But in the original `conversation_screen.dart`, delete for everyone was:
      // `await client.from('chat_messages').delete().eq('id', msg['id']);`
      // Wait, we can implement that directly in the view model using a supabase call, or just use the repo if we add it, or write a direct query. Let's write the query using repository or raw client if needed, but wait - repository pattern is cleaner!
      // In the repo impl, deleteMessage only soft-deleted. Let's do a direct call to the Supabase client from within the view model, or we can use the repository if we want. Wait, the repository is already injected, but wait, does it have delete everyone?
      // Let's check if the client is accessible. Yes, we can use `Supabase.instance.client` or we can modify the repo. Let's just do it directly with `Supabase.instance.client` to avoid changing the Repository interfaces unnecessarily, or we can use the repository. Let's check if the repo is clean.
      final client = Supabase.instance.client;
      await client.from('chat_messages').delete().eq('id', msg['id']);
    } catch (e) {
      debugPrint("Error deleting message for everyone: $e");
      rethrow;
    }
  }

  // Audio Playback
  Future<void> toggleAudioPlay(String msgId, String url, int durationSeconds) async {
    if (state.activeAudioId == msgId) {
      await _audioPlayer.pause();
      state = state.copyWith(clearActiveAudio: true);
    } else {
      await _audioPlayer.stop();

      state = state.copyWith(
        activeAudioId: msgId,
        activeAudioDuration: durationSeconds,
        playbackProgress: state.activeAudioId == msgId ? state.playbackProgress : 0.0,
      );

      if (state.playbackProgress >= 1.0) {
        state = state.copyWith(playbackProgress: 0.0);
      }

      try {
        String finalUrl = url;
        if (finalUrl == 'mock_audio_url') {
          finalUrl = 'https://www.w3schools.com/html/horse.mp3';
        }
        await _audioPlayer.setPlaybackRate(state.playbackSpeed);
        await _audioPlayer.play(UrlSource(finalUrl));
      } catch (e) {
        debugPrint("Error playing audio: $e");
      }
    }
  }

  Future<void> togglePlaybackSpeed() async {
    double newSpeed = 1.0;
    if (state.playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (state.playbackSpeed == 1.5) {
      newSpeed = 2.0;
    }

    state = state.copyWith(playbackSpeed: newSpeed);

    if (state.activeAudioId != null) {
      try {
        await _audioPlayer.setPlaybackRate(newSpeed);
      } catch (e) {
        debugPrint("Error setting playback speed: $e");
      }
    }
  }

  // Audio Recording
  Future<void> startRecording() async {
    try {
      if (state.hasMicPermission || await _audioRecorder.hasPermission()) {
        state = state.copyWith(hasMicPermission: true);

        final tempDir = await getTemporaryDirectory();
        final path = p.join(tempDir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        state = state.copyWith(
          isRecording: true,
          isPaused: false,
          recordingSeconds: 0,
          recordingWaveforms: List.filled(17, 4.0),
        );

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
        });
        _startAmplitudeTimer();
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  void _startAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!state.isRecording || state.isPaused) return;
      try {
        final amp = await _audioRecorder.getAmplitude();
        final db = amp.current;

        double volumeFactor = 0.15;
        if (db > -60) {
          volumeFactor = 0.15 + (60 + db) * (0.85 / 60.0);
        }
        if (volumeFactor > 1.0) volumeFactor = 1.0;

        final newWaveforms = List<double>.from(state.recordingWaveforms);
        for (int i = 0; i < newWaveforms.length; i++) {
          final time = DateTime.now().millisecondsSinceEpoch / 120.0;
          final base = math.sin(time + i * 0.7).abs();
          final noise = math.cos(time * 1.8 + i).abs() * 0.3;
          double height = 4.0 + (base + noise) * 20.0 * volumeFactor;
          if (height > 24.0) height = 24.0;
          if (height < 4.0) height = 4.0;
          newWaveforms[i] = height;
        }

        state = state.copyWith(recordingWaveforms: newWaveforms);
      } catch (e) {
        // Ignored
      }
    });
  }

  Future<void> cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _amplitudeTimer?.cancel();
      await _audioRecorder.stop();
      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        recordingSeconds: 0,
      );
    } catch (e) {
      debugPrint("Error cancelling recording: $e");
    }
  }

  Future<void> toggleRecordingPause() async {
    if (!state.isRecording) return;
    try {
      if (state.isPaused) {
        await _audioRecorder.resume();
        state = state.copyWith(isPaused: false);
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
        });
      } else {
        await _audioRecorder.pause();
        _recordingTimer?.cancel();
        state = state.copyWith(isPaused: true);
      }
    } catch (e) {
      debugPrint("Error toggling record pause: $e");
    }
  }

  Future<void> stopAndSendRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    if (!state.isRecording) return;

    final duration = state.recordingSeconds;
    state = state.copyWith(isRecording: false, isPaused: false);

    try {
      final path = await _audioRecorder.stop();
      if (duration < 1 || path == null) {
        throw 'Voice message too short';
      }

      final file = File(path);
      final publicUrl = await _chatRepository.uploadChatMedia(
        threadId: _threadId,
        file: file,
        isAudio: true,
      );

      await _chatRepository.sendMessage(
        threadId: _threadId,
        senderId: _currentUserId,
        messageType: 'audio',
        content: publicUrl,
        mediaDuration: duration,
      );
    } catch (e) {
      debugPrint("Error sending audio message: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _playbackTimer?.cancel();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
