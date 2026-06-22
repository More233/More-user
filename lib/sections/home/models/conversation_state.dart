class ConversationState {
  final List<Map<String, dynamic>> messages;
  final bool isLoadingMessages;
  final String? activeAudioId;
  final int activeAudioDuration;
  final double playbackProgress;
  final double playbackSpeed;
  final bool isRecording;
  final bool isPaused;
  final int recordingSeconds;
  final List<double> recordingWaveforms;
  final bool hasMicPermission;

  ConversationState({
    required this.messages,
    required this.isLoadingMessages,
    this.activeAudioId,
    required this.activeAudioDuration,
    required this.playbackProgress,
    required this.playbackSpeed,
    required this.isRecording,
    required this.isPaused,
    required this.recordingSeconds,
    required this.recordingWaveforms,
    required this.hasMicPermission,
  });

  factory ConversationState.initial() {
    return ConversationState(
      messages: [],
      isLoadingMessages: true,
      activeAudioId: null,
      activeAudioDuration: 0,
      playbackProgress: 0.0,
      playbackSpeed: 1.0,
      isRecording: false,
      isPaused: false,
      recordingSeconds: 0,
      recordingWaveforms: List.filled(17, 4.0),
      hasMicPermission: false,
    );
  }

  ConversationState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoadingMessages,
    String? activeAudioId,
    int? activeAudioDuration,
    double? playbackProgress,
    double? playbackSpeed,
    bool? isRecording,
    bool? isPaused,
    int? recordingSeconds,
    List<double>? recordingWaveforms,
    bool? hasMicPermission,
    bool clearActiveAudio = false,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      activeAudioId: clearActiveAudio ? null : (activeAudioId ?? this.activeAudioId),
      activeAudioDuration: activeAudioDuration ?? this.activeAudioDuration,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      recordingWaveforms: recordingWaveforms ?? this.recordingWaveforms,
      hasMicPermission: hasMicPermission ?? this.hasMicPermission,
    );
  }
}
