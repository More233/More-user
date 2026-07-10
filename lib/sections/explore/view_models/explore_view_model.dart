import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/repositories/explore_repository.dart';
import '../../../data/repositories/explore_repository_impl.dart';
import '../helpers/bookmark_tracker.dart';
import '../helpers/explore_screen_helpers.dart';
import '../models/explore_state.dart';
import '../models/filter_state.dart';

final exploreViewModelProvider = StateNotifierProvider.autoDispose<ExploreViewModel, ExploreState>((ref) {
  final exploreRepo = ref.watch(exploreRepositoryProvider);
  return ExploreViewModel(exploreRepository: exploreRepo);
});

class ExploreViewModel extends StateNotifier<ExploreState> {
  final ExploreRepository _exploreRepository;

  ExploreViewModel({required this._exploreRepository}) : super(ExploreState.initial());

  Future<void> init() async {
    await BookmarkTracker().init();
    final savedPlaces = BookmarkTracker().getBookmarkedPlaces();
    
    // Add bookmarks to initial state places list
    final list = List<Map<String, dynamic>>.from(state.allPlaces);
    final existingIds = list.map((p) => p['id'].toString()).toSet();
    for (final sp in savedPlaces) {
      final spIdStr = sp['id'].toString();
      if (!existingIds.contains(spIdStr)) {
        list.add(sp);
      }
    }

    state = state.copyWith(allPlaces: list);
    await getUserLocation();
  }

  Future<void> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await fetchNearbyPlaces(24.7136, 46.6753);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        state = state.copyWith(userLocation: () => LatLng(position.latitude, position.longitude));
        await fetchNearbyPlaces(position.latitude, position.longitude);
      } else {
        await fetchNearbyPlaces(24.7136, 46.6753);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      await fetchNearbyPlaces(24.7136, 46.6753);
    }
  }

  Future<void> fetchNearbyPlaces(double lat, double lng, {String? category, double zoom = 13.0}) async {
    try {
      state = state.copyWith(lastFetchedLocation: () => LatLng(lat, lng), isLoading: true);
      
      // Calculate dynamic radius and box size based on zoom level
      double? boxSize = 0.05; // ~5.5 km local
      double radius = 3000;

      if (zoom < 7.0) {
        boxSize = null; // Global search!
        radius = 50000; // max radius for Google API
      } else if (zoom < 10.0) {
        boxSize = 1.0; // ~110 km
        radius = 50000;
      } else if (zoom < 13.0) {
        boxSize = 0.2; // ~22 km
        radius = 15000;
      }

      final results = await Future.wait([
        _exploreRepository.fetchNearbyFoursquarePlaces(lat, lng, radius: radius),
        _exploreRepository.fetchSupabaseCheckinsAndVenues(lat, lng, boxSize: boxSize),
        _exploreRepository.fetchNearbyFoursquarePlaces(lat, lng, radius: radius, keyword: 'cinema|stadium|museum|theater|concert|sports'),
      ]);

      final normalPlaces = results[0] as List<Map<String, dynamic>>;
      final supabaseResults = results[1] as Map<String, dynamic>;
      final eventPlaces = results[2] as List<Map<String, dynamic>>;

      // Merge places and remove duplicates by ID
      final Map<String, Map<String, dynamic>> combinedFoursquareMap = {};
      for (final p in normalPlaces) {
        combinedFoursquareMap[p['id'].toString()] = p;
      }
      for (final p in eventPlaces) {
        combinedFoursquareMap[p['id'].toString()] = p;
      }
      final foursquarePlaces = combinedFoursquareMap.values.toList();

      final checkins = supabaseResults['checkins'] as List<Map<String, dynamic>>;
      final customVenues = supabaseResults['customVenues'] as List<Map<String, dynamic>>;
      final postsRaw = List<dynamic>.from(supabaseResults['postsRaw'] as List? ?? []);

      final placeVisitorCounts = <String, int>{};
      final placeVisitorsMap = <String, List<Map<String, dynamic>>>{};
      final placeSeenUser = <String, Set<String>>{};

      for (final postObj in postsRaw) {
        final post = postObj as Map<String, dynamic>;
        final placeId = post['place_id']?.toString();
        if (placeId != null && placeId.isNotEmpty) {
          final author = post['author'] as Map<String, dynamic>?;
          final authorName = author != null ? '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim() : 'Anonymous';
          final authorAvatar = author?['avatar_url'] as String?;
          final createdAt = post['created_at'] as String? ?? '';
          final double weight = ExploreScreenHelpers.calculateTimeDecayWeight(createdAt);
          
          placeSeenUser.putIfAbsent(placeId, () => <String>{});
          if (!placeSeenUser[placeId]!.contains(authorName)) {
            placeSeenUser[placeId]!.add(authorName);
            placeVisitorsMap.putIfAbsent(placeId, () => <Map<String, dynamic>>[]).add({
              'userId': author?['id'] as String?,
              'name': authorName,
              'avatarUrl': authorAvatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
              'createdAt': createdAt,
              'weight': weight,
            });
          }
        }
      }

      placeVisitorsMap.forEach((placeId, visitors) {
        final activeCount = visitors.where((v) => (v['weight'] as double? ?? 0.0) > 0.0).length;
        placeVisitorCounts[placeId] = activeCount;
      });

      final list = List<Map<String, dynamic>>.from(state.allPlaces);
      final existingIds = list.map((p) => p['id'].toString()).toSet();

      Map<String, dynamic> updatePlaceData(Map<String, dynamic> p) {
        final pid = p['id'].toString();
        final updated = Map<String, dynamic>.from(p);
        updated['isSaved'] = BookmarkTracker().isBookmarked(pid);
        final int baseCount = p['basePeopleCount'] as int? ?? 0;
        if (placeVisitorCounts.containsKey(pid) && (placeVisitorCounts[pid] ?? 0) > 0) {
          updated['peopleCount'] = (placeVisitorCounts[pid] ?? 0) + baseCount;
          updated['visitors'] = placeVisitorsMap[pid];
        } else {
          updated['peopleCount'] = baseCount;
          updated['visitors'] = <Map<String, dynamic>>[];
        }
        return updated;
      }

      for (final p in foursquarePlaces) {
        final updated = updatePlaceData(p);
        final pidStr = p['id'].toString();
        if (!existingIds.contains(pidStr)) {
          list.add(updated);
        } else {
          final index = list.indexWhere((x) => x['id'].toString() == pidStr);
          if (index != -1) {
            list[index] = updatePlaceData(list[index]);
          }
        }
      }
      for (final c in checkins) {
        final cidStr = c['id'].toString();
        if (!existingIds.contains(cidStr)) {
          list.add(c);
        }
      }
      for (final v in customVenues) {
        final updated = updatePlaceData(v);
        final vidStr = v['id'].toString();
        if (!existingIds.contains(vidStr)) {
          list.add(updated);
        } else {
          final index = list.indexWhere((x) => x['id'].toString() == vidStr);
          if (index != -1) {
            list[index] = updatePlaceData(list[index]);
          }
        }
      }

      final savedPlaces = BookmarkTracker().getBookmarkedPlaces();
      for (final sp in savedPlaces) {
        final spIdStr = sp['id'].toString();
        if (!existingIds.contains(spIdStr)) {
          list.add(sp);
        }
      }

      state = state.copyWith(allPlaces: list, isLoading: false);
    } catch (e) {
      debugPrint("Error fetching nearby places: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> searchPlaces(String query) async {
    final lat = state.userLocation?.latitude ?? 24.7136;
    final lng = state.userLocation?.longitude ?? 46.6753;

    state = state.copyWith(isSearching: true);
    try {
      final results = await _exploreRepository.searchPlaces(query, lat, lng);
      final list = List<Map<String, dynamic>>.from(state.allPlaces);
      final existingIds = list.map((p) => p['id'].toString()).toSet();

      for (final r in results) {
        final updated = Map<String, dynamic>.from(r);
        updated['isSaved'] = BookmarkTracker().isBookmarked(r['id'].toString());
        final pidStr = r['id'].toString();
        if (!existingIds.contains(pidStr)) {
          list.add(updated);
        } else {
          final index = list.indexWhere((x) => x['id'].toString() == pidStr);
          if (index != -1) {
            list[index] = updated;
          }
        }
      }
      state = state.copyWith(
        allPlaces: list,
        selectedPlace: () => results.isNotEmpty ? results.first : null,
        isSearching: false,
      );
    } catch (e) {
      debugPrint("Error searching places: $e");
      state = state.copyWith(isSearching: false);
    }
  }

  void selectPlaceAndLoadDetails(Map<String, dynamic> place) {
    state = state.copyWith(selectedPlace: () => place);
    final String placeId = place['id'].toString();
    final String name = place['name'] as String? ?? '';
    final double plat = (place['latitude'] as num?)?.toDouble() ?? 0.0;
    final double plng = (place['longitude'] as num?)?.toDouble() ?? 0.0;

    final bool isFoursquare = !placeId.startsWith('tapped_') &&
                              !placeId.startsWith('swarm_') &&
                              place['isCheckIn'] != true &&
                              place['isCustomVenue'] != true;

    final double userLat = state.userLocation?.latitude ?? plat;
    final double userLng = state.userLocation?.longitude ?? plng;

    if (isFoursquare) {
      _exploreRepository.fetchPlaceDetails(
        placeId,
        name,
        plat,
        plng,
        userLat,
        userLng,
      ).then((fullPlace) {
        if (fullPlace != null && state.selectedPlace?['id'] == placeId) {
          final list = List<Map<String, dynamic>>.from(state.allPlaces);
          final idx = list.indexWhere((p) => p['id'] == placeId);
          if (idx != -1) {
            list[idx] = fullPlace;
          }
          state = state.copyWith(allPlaces: list, selectedPlace: () => fullPlace);
        }
      });
    } else {
      _exploreRepository.fetchVisitorsForNonFoursquare(place).then((updatedPlace) {
        if (updatedPlace != null && state.selectedPlace?['id'] == placeId) {
          final list = List<Map<String, dynamic>>.from(state.allPlaces);
          final idx = list.indexWhere((p) => p['id'] == placeId);
          if (idx != -1) {
            list[idx] = updatedPlace;
          }
          state = state.copyWith(allPlaces: list, selectedPlace: () => updatedPlace);
        }
      });
    }
  }

  void toggleBookmark(Map<String, dynamic> place, bool val) {
    BookmarkTracker().setBookmarked(place, val);
    final list = List<Map<String, dynamic>>.from(state.allPlaces);
    final idx = list.indexWhere((p) => p['id'] == place['id']);
    if (idx != -1) {
      list[idx]['isSaved'] = val;
    }
    
    Map<String, dynamic>? updatedSelected;
    if (state.selectedPlace != null && state.selectedPlace!['id'] == place['id']) {
      updatedSelected = Map<String, dynamic>.from(state.selectedPlace!);
      updatedSelected['isSaved'] = val;
    } else {
      updatedSelected = state.selectedPlace;
    }

    state = state.copyWith(
      allPlaces: list,
      selectedPlace: () => updatedSelected,
    );
  }

  void addRecentPlace(Map<String, dynamic> place) {
    final recent = List<Map<String, dynamic>>.from(state.recentPlaces);
    if (!recent.any((p) => p['id'] == place['id'])) {
      recent.insert(0, place);
    }
    state = state.copyWith(recentPlaces: recent);
  }

  void updateFilterState(FilterState filter) {
    state = state.copyWith(
      filterState: filter,
      selectedPlace: () => null,
    );
  }

  void updateCategory(String category) {
    state = state.copyWith(
      selectedCategory: category,
      selectedPlace: () => null,
      isListView: false,
    );
  }

  void updateMapTab(int index) {
    state = state.copyWith(
      selectedMapTab: index,
      selectedPlace: () => null,
    );
  }

  void updateListView(bool isList) {
    state = state.copyWith(isListView: isList);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSelectedPlaceManual(Map<String, dynamic>? place) {
    state = state.copyWith(selectedPlace: () => place);
  }

  void updateAllPlacesManual(List<Map<String, dynamic>> list) {
    state = state.copyWith(allPlaces: list);
  }
}
