class NotificationsState {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;
  final String? error;
  final bool hasUnread;
  final int unreadCount;

  NotificationsState({
    required this.activities,
    required this.isLoading,
    this.error,
    this.hasUnread = false,
    this.unreadCount = 0,
  });

  factory NotificationsState.initial() {
    return NotificationsState(
      activities: [],
      isLoading: true,
      error: null,
      hasUnread: false,
      unreadCount: 0,
    );
  }

  NotificationsState copyWith({
    List<Map<String, dynamic>>? activities,
    bool? isLoading,
    String? error,
    bool? hasUnread,
    int? unreadCount,
  }) {
    return NotificationsState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasUnread: hasUnread ?? this.hasUnread,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
