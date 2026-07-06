class ExploreSearchState {
  final String searchQuery;
  final bool isSearching;
  final List<Map<String, dynamic>> searchResults;
  final List<Map<String, dynamic>> nearbyPlaces;
  final bool isLoadingNearby;
  final Map<String, dynamic> localFilterState;

  ExploreSearchState({
    required this.searchQuery,
    required this.isSearching,
    required this.searchResults,
    required this.nearbyPlaces,
    required this.isLoadingNearby,
    required this.localFilterState,
  });

  factory ExploreSearchState.initial(Map<String, dynamic> initialFilters) {
    return ExploreSearchState(
      searchQuery: "",
      isSearching: false,
      searchResults: [],
      nearbyPlaces: [],
      isLoadingNearby: true,
      localFilterState: initialFilters,
    );
  }

  ExploreSearchState copyWith({
    String? searchQuery,
    bool? isSearching,
    List<Map<String, dynamic>>? searchResults,
    List<Map<String, dynamic>>? nearbyPlaces,
    bool? isLoadingNearby,
    Map<String, dynamic>? localFilterState,
  }) {
    return ExploreSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      isLoadingNearby: isLoadingNearby ?? this.isLoadingNearby,
      localFilterState: localFilterState ?? this.localFilterState,
    );
  }
}
