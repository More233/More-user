import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'view_models/explore_search_view_model.dart';
import 'widgets/search/explore_search_header.dart';
import 'widgets/search/explore_search_lists.dart';

class ExploreSearchScreen extends ConsumerStatefulWidget {
  final double userLat;
  final double userLng;
  final List<Map<String, dynamic>> recentPlaces;
  final ValueChanged<Map<String, dynamic>> onRecentPlaceAdded;
  final Map<String, dynamic> filterState;
  final ValueChanged<Map<String, dynamic>> onFilterStateChanged;

  const ExploreSearchScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.recentPlaces,
    required this.onRecentPlaceAdded,
    required this.filterState,
    required this.onFilterStateChanged,
  });

  @override
  ConsumerState<ExploreSearchScreen> createState() => _ExploreSearchScreenState();
}

class _ExploreSearchScreenState extends ConsumerState<ExploreSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(exploreSearchViewModelProvider(widget.filterState).notifier)
          .loadNearbyPlaces(widget.userLat, widget.userLng);
    });
    // Request keyboard focus after routing animation finishes
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreSearchViewModelProvider(widget.filterState));
    final viewModel = ref.read(exploreSearchViewModelProvider(widget.filterState).notifier);
    final double topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            ExploreSearchHeader(
              topPadding: topPadding,
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (query) {
                viewModel.onSearchChanged(query, widget.userLat, widget.userLng);
              },
              isSearching: state.isSearching,
              searchQuery: state.searchQuery,
              onBackTap: () => Navigator.pop(context),
              onClearTap: () {
                _searchController.clear();
                viewModel.onSearchChanged("", widget.userLat, widget.userLng);
              },
              onCategoryTap: (categoryType) {
                Navigator.pop(context, {
                  'type': 'category',
                  'category': categoryType,
                });
              },
              onCurrentLocationTap: () {
                Navigator.pop(context, {
                  'type': 'current_location',
                });
              },
            ),
            Expanded(
              child: ExploreSearchLists(
                searchQuery: state.searchQuery,
                isSearching: state.isSearching,
                searchResults: state.searchResults,
                isLoadingNearby: state.isLoadingNearby,
                nearbyPlaces: state.nearbyPlaces,
                recentPlaces: widget.recentPlaces,
                onCategoryTap: (categoryType) {
                  Navigator.pop(context, {
                    'type': 'category',
                    'category': categoryType,
                  });
                },
                onPlaceTap: (place) {
                  widget.onRecentPlaceAdded(place);
                  Navigator.pop(context, {
                    'type': 'place',
                    'place': place,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
