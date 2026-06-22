class StoryViewState {
  final int currentGroupIndex;
  final int currentStoryIndex;
  final bool isReactionTrayOpen;
  final int viewsCount;
  final List<Map<String, dynamic>> viewers;
  final bool isSending;

  StoryViewState({
    required this.currentGroupIndex,
    required this.currentStoryIndex,
    required this.isReactionTrayOpen,
    required this.viewsCount,
    required this.viewers,
    required this.isSending,
  });

  factory StoryViewState.initial({int initialGroupIndex = 0}) {
    return StoryViewState(
      currentGroupIndex: initialGroupIndex,
      currentStoryIndex: 0,
      isReactionTrayOpen: false,
      viewsCount: 0,
      viewers: [],
      isSending: false,
    );
  }

  StoryViewState copyWith({
    int? currentGroupIndex,
    int? currentStoryIndex,
    bool? isReactionTrayOpen,
    int? viewsCount,
    List<Map<String, dynamic>>? viewers,
    bool? isSending,
  }) {
    return StoryViewState(
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      currentStoryIndex: currentStoryIndex ?? this.currentStoryIndex,
      isReactionTrayOpen: isReactionTrayOpen ?? this.isReactionTrayOpen,
      viewsCount: viewsCount ?? this.viewsCount,
      viewers: viewers ?? this.viewers,
      isSending: isSending ?? this.isSending,
    );
  }
}
