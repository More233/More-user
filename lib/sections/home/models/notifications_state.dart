class NotificationsState {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;
  final String? error;

  NotificationsState({
    required this.activities,
    required this.isLoading,
    this.error,
  });

  factory NotificationsState.initial() {
    return NotificationsState(
      activities: [],
      isLoading: true,
      error: null,
    );
  }

  NotificationsState copyWith({
    List<Map<String, dynamic>>? activities,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
