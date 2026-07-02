class SettingsState {
  final bool loading;
  final String preferredLanguage;
  final String profileVisibility;
  final String friendRequestsVisibility;
  final String checkInVisibility;
  final bool showMeHereNow;
  final bool letFriendsCheckInWithMe;
  final String showStatsStreaks;
  final bool showSavedPlacesProfile;
  final bool allowTagsMentions;
  final Map<String, bool> pushSettings;
  final String locationPermission;
  final bool preciseLocation;
  final bool showNearbyPlaces;
  final bool nearbyCheckInPrompts;
  final bool showCheckInSuggestions;
  final bool suggestPlacesWhenNearby;
  final bool suggestFromRecentVisits;
  final bool usePhotoTimeLocation;
  final List<Map<String, dynamic>> blockedUsers;
  final bool blockingLoading;

  SettingsState({
    this.loading = true,
    this.preferredLanguage = 'en',
    this.profileVisibility = 'friends',
    this.friendRequestsVisibility = 'friends_of_friends',
    this.checkInVisibility = 'friends',
    this.showMeHereNow = true,
    this.letFriendsCheckInWithMe = true,
    this.showStatsStreaks = 'friends',
    this.showSavedPlacesProfile = true,
    this.allowTagsMentions = true,
    this.pushSettings = const {},
    this.locationPermission = 'while_using',
    this.preciseLocation = true,
    this.showNearbyPlaces = true,
    this.nearbyCheckInPrompts = true,
    this.showCheckInSuggestions = true,
    this.suggestPlacesWhenNearby = true,
    this.suggestFromRecentVisits = true,
    this.usePhotoTimeLocation = true,
    this.blockedUsers = const [],
    this.blockingLoading = false,
  });

  SettingsState copyWith({
    bool? loading,
    String? preferredLanguage,
    String? profileVisibility,
    String? friendRequestsVisibility,
    String? checkInVisibility,
    bool? showMeHereNow,
    bool? letFriendsCheckInWithMe,
    String? showStatsStreaks,
    bool? showSavedPlacesProfile,
    bool? allowTagsMentions,
    Map<String, bool>? pushSettings,
    String? locationPermission,
    bool? preciseLocation,
    bool? showNearbyPlaces,
    bool? nearbyCheckInPrompts,
    bool? showCheckInSuggestions,
    bool? suggestPlacesWhenNearby,
    bool? suggestFromRecentVisits,
    bool? usePhotoTimeLocation,
    List<Map<String, dynamic>>? blockedUsers,
    bool? blockingLoading,
  }) {
    return SettingsState(
      loading: loading ?? this.loading,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      friendRequestsVisibility: friendRequestsVisibility ?? this.friendRequestsVisibility,
      checkInVisibility: checkInVisibility ?? this.checkInVisibility,
      showMeHereNow: showMeHereNow ?? this.showMeHereNow,
      letFriendsCheckInWithMe: letFriendsCheckInWithMe ?? this.letFriendsCheckInWithMe,
      showStatsStreaks: showStatsStreaks ?? this.showStatsStreaks,
      showSavedPlacesProfile: showSavedPlacesProfile ?? this.showSavedPlacesProfile,
      allowTagsMentions: allowTagsMentions ?? this.allowTagsMentions,
      pushSettings: pushSettings ?? this.pushSettings,
      locationPermission: locationPermission ?? this.locationPermission,
      preciseLocation: preciseLocation ?? this.preciseLocation,
      showNearbyPlaces: showNearbyPlaces ?? this.showNearbyPlaces,
      nearbyCheckInPrompts: nearbyCheckInPrompts ?? this.nearbyCheckInPrompts,
      showCheckInSuggestions: showCheckInSuggestions ?? this.showCheckInSuggestions,
      suggestPlacesWhenNearby: suggestPlacesWhenNearby ?? this.suggestPlacesWhenNearby,
      suggestFromRecentVisits: suggestFromRecentVisits ?? this.suggestFromRecentVisits,
      usePhotoTimeLocation: usePhotoTimeLocation ?? this.usePhotoTimeLocation,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      blockingLoading: blockingLoading ?? this.blockingLoading,
    );
  }
}
