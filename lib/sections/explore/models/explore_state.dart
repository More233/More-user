import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'filter_state.dart';

class ExploreState {
  final List<Map<String, dynamic>> allPlaces;
  final LatLng? userLocation;
  final Map<String, dynamic>? selectedPlace;
  final int selectedMapTab;
  final String selectedCategory;
  final String searchQuery;
  final bool isSearching;
  final bool isListView;
  final FilterState filterState;
  final List<Map<String, dynamic>> recentPlaces;
  final LatLng? lastFetchedLocation;
  final bool isLoading;

  ExploreState({
    required this.allPlaces,
    this.userLocation,
    this.selectedPlace,
    required this.selectedMapTab,
    required this.selectedCategory,
    required this.searchQuery,
    required this.isSearching,
    required this.isListView,
    required this.filterState,
    required this.recentPlaces,
    this.lastFetchedLocation,
    required this.isLoading,
  });

  factory ExploreState.initial() {
    return ExploreState(
      allPlaces: [],
      userLocation: null,
      selectedPlace: null,
      selectedMapTab: 0,
      selectedCategory: "",
      searchQuery: "",
      isSearching: false,
      isListView: false,
      filterState: FilterState(),
      recentPlaces: [],
      lastFetchedLocation: null,
      isLoading: false,
    );
  }

  ExploreState copyWith({
    List<Map<String, dynamic>>? allPlaces,
    LatLng? Function()? userLocation,
    Map<String, dynamic>? Function()? selectedPlace,
    int? selectedMapTab,
    String? selectedCategory,
    String? searchQuery,
    bool? isSearching,
    bool? isListView,
    FilterState? filterState,
    List<Map<String, dynamic>>? recentPlaces,
    LatLng? Function()? lastFetchedLocation,
    bool? isLoading,
  }) {
    return ExploreState(
      allPlaces: allPlaces ?? this.allPlaces,
      userLocation: userLocation != null ? userLocation() : this.userLocation,
      selectedPlace: selectedPlace != null ? selectedPlace() : this.selectedPlace,
      selectedMapTab: selectedMapTab ?? this.selectedMapTab,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      isListView: isListView ?? this.isListView,
      filterState: filterState ?? this.filterState,
      recentPlaces: recentPlaces ?? this.recentPlaces,
      lastFetchedLocation: lastFetchedLocation != null ? lastFetchedLocation() : this.lastFetchedLocation,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
