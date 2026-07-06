import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/explore_search_state.dart';
import '../services/explore_data_service.dart';

final exploreSearchViewModelProvider = StateNotifierProvider.family.autoDispose<
    ExploreSearchViewModel, ExploreSearchState, Map<String, dynamic>>((ref, initialFilters) {
  return ExploreSearchViewModel(initialFilters: initialFilters);
});

class ExploreSearchViewModel extends StateNotifier<ExploreSearchState> {
  final Map<String, dynamic> initialFilters;

  ExploreSearchViewModel({required this.initialFilters})
      : super(ExploreSearchState.initial(initialFilters));

  Future<void> loadNearbyPlaces(double lat, double lng) async {
    state = state.copyWith(isLoadingNearby: true);
    try {
      final places = await ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng);
      state = state.copyWith(
        nearbyPlaces: places,
        isLoadingNearby: false,
      );
    } catch (e) {
      debugPrint("Error loading search nearby places: $e");
      state = state.copyWith(isLoadingNearby: false);
    }
  }

  Future<void> onSearchChanged(String query, double lat, double lng) async {
    state = state.copyWith(searchQuery: query);

    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    try {
      final results = await ExploreDataService.searchFoursquarePlaces(query, lat, lng);
      // Verify query didn't change while loading
      if (state.searchQuery == query) {
        state = state.copyWith(
          searchResults: results,
          isSearching: false,
        );
      }
    } catch (e) {
      debugPrint("Error in place search: $e");
      if (state.searchQuery == query) {
        state = state.copyWith(isSearching: false);
      }
    }
  }

  void updateFilterState(Map<String, dynamic> newFilters) {
    state = state.copyWith(localFilterState: newFilters);
  }
}
