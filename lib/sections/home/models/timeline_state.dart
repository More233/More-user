import '../models/timeline_post.dart';

class TimelineState {
  final int selectedTabIndex;
  final int selectedNavIndex;
  final bool isFirstCheckIn;
  final bool showCoachmark;
  final int userCoins;
  final Set<String> followedUsernames;
  final List<TimelinePost> posts;
  final String? currentUserAvatarUrl;
  final bool isLoading;

  TimelineState({
    required this.selectedTabIndex,
    required this.selectedNavIndex,
    required this.isFirstCheckIn,
    required this.showCoachmark,
    required this.userCoins,
    required this.followedUsernames,
    required this.posts,
    this.currentUserAvatarUrl,
    required this.isLoading,
  });

  factory TimelineState.initial() {
    return TimelineState(
      selectedTabIndex: 0,
      selectedNavIndex: 0,
      isFirstCheckIn: true,
      showCoachmark: false,
      userCoins: 0,
      followedUsernames: {},
      posts: [],
      currentUserAvatarUrl: null,
      isLoading: true,
    );
  }

  TimelineState copyWith({
    int? selectedTabIndex,
    int? selectedNavIndex,
    bool? isFirstCheckIn,
    bool? showCoachmark,
    int? userCoins,
    Set<String>? followedUsernames,
    List<TimelinePost>? posts,
    String? currentUserAvatarUrl,
    bool? isLoading,
    bool clearAvatar = false,
  }) {
    return TimelineState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      isFirstCheckIn: isFirstCheckIn ?? this.isFirstCheckIn,
      showCoachmark: showCoachmark ?? this.showCoachmark,
      userCoins: userCoins ?? this.userCoins,
      followedUsernames: followedUsernames ?? this.followedUsernames,
      posts: posts ?? this.posts,
      currentUserAvatarUrl: clearAvatar ? null : (currentUserAvatarUrl ?? this.currentUserAvatarUrl),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
