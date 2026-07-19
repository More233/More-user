import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moor/shared/models/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/explore_repository.dart';
import '../../../data/repositories/explore_repository_impl.dart';
import '../helpers/bookmark_tracker.dart';
import '../helpers/explore_screen_helpers.dart';
import '../helpers/marker_generator.dart';
import '../services/explore_db_cache_service.dart';
import '../models/explore_state.dart';
import '../models/filter_state.dart';

final exploreViewModelProvider = StateNotifierProvider<ExploreViewModel, ExploreState>((ref) {
  final exploreRepo = ref.watch(exploreRepositoryProvider);
  return ExploreViewModel(exploreRepository: exploreRepo);
});

class ExploreViewModel extends StateNotifier<ExploreState> {
  final ExploreRepository _exploreRepository;
  Timer? _apiDebounceTimer;

  ExploreViewModel({required this._exploreRepository}) : super(ExploreState.initial());


  Future<void> init() async {
    if (state.allPlaces.isNotEmpty && state.userLocation != null) {
      return;
    }
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
        final loc = LatLng(position.latitude, position.longitude);
        await fetchNearbyPlaces(position.latitude, position.longitude, newUserLocation: loc);
      } else {
        await fetchNearbyPlaces(24.7136, 46.6753);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      await fetchNearbyPlaces(24.7136, 46.6753);
    }
  }

  Future<void> fetchNearbyPlaces(
    double lat, 
    double lng, {
    String? category, 
    double zoom = 13.0,
    LatLng? newUserLocation,
  }) async {
    try {
      debugPrint("ExploreViewModel: fetchNearbyPlaces called at ($lat, $lng) with zoom $zoom");
      state = state.copyWith(
        lastFetchedLocation: () => LatLng(lat, lng), 
        isLoading: true,
        userLocation: newUserLocation != null ? () => newUserLocation : null,
      );
      
      double? boxSize = 0.15; // ~16.5 km local area preload
      double radius = 3000;   // Concentrated 3 km Google Places radius for high density

      if (zoom < 3.0) {
        boxSize = null; // Global search
        radius = 20000000; // ~20,000 km (covers the entire Earth)
      } else if (zoom < 5.0) {
        boxSize = null;
        radius = 10000000; // ~10,000 km
      } else if (zoom < 7.0) {
        boxSize = null;
        radius = 4000000; // ~4,000 km
      } else if (zoom < 9.0) {
        boxSize = 2.0;
        radius = 1500000; // ~1,500 km
      } else if (zoom < 11.0) {
        boxSize = 1.0;
        radius = 400000; // ~400 km
      } else if (zoom < 13.0) {
        boxSize = 0.4;
        radius = 40000; // ~40 km (Cap for Places API and search efficiency)
      }

      bool cacheOnly = zoom < 8.0;

      // 1. PHASE 1: LOAD INSTANTLY FROM LOCAL SQLITE CACHE (cacheOnly = true)
      // This loads preloaded/seeded places immediately in < 10ms!
      // We only run a single query since getPlacesInBoundingBox returns all cached places.
      final initialPlaces = await _exploreRepository.fetchNearbyFoursquarePlaces(
        lat, 
        lng, 
        radius: radius, 
        cacheOnly: true,
      );
      
      // DYNAMIC GLOBAL SEEDING: If local cache is empty in this region and zoom >= 5.0,
      // force a background sync fetch from the API (clamped to 30km radius) to seed the SQLite cache.
      if (cacheOnly && zoom >= 5.0 && initialPlaces.isEmpty) {
        cacheOnly = false;
        radius = 30000;
      }

      final list = List<Map<String, dynamic>>.from(state.allPlaces);
      final existingIds = list.map((p) => p['id'].toString()).toSet();
      
      for (final p in initialPlaces) {
        final pidStr = p['id'].toString();
        if (!existingIds.contains(pidStr)) {
          list.add(p);
        }
      }
      state = state.copyWith(allPlaces: list, isLoading: false);

      // 2. PHASE 2: BACKGROUND DELTA SYNC WITH DEBOUNCE
      if (!cacheOnly) {
        _apiDebounceTimer?.cancel();
        final Duration debounceDuration = initialPlaces.isEmpty 
            ? const Duration(milliseconds: 50)
            : const Duration(milliseconds: 250);
        _apiDebounceTimer = Timer(debounceDuration, () async {
          try {
            final double gridLat = (lat * 100).round() / 100.0;
            final double gridLng = (lng * 100).round() / 100.0;
            final String cellId = '${gridLat.toStringAsFixed(2)}_${gridLng.toStringAsFixed(2)}';

            final bool isCellSynced = await ExploreDbCacheService.isCellSynced(cellId);
            final bool hasCategory = category != null && category.isNotEmpty;

            // 1. Fetch Supabase check-ins and custom venues
            if (!hasCategory) {
              _exploreRepository.fetchSupabaseCheckinsAndVenues(lat, lng, boxSize: boxSize).then((data) {
                _mergeAndUpdatePlaces([], supabaseData: data);
                debugPrint("ExploreViewModel: Background sync Supabase checkins completed.");
              }).catchError((err) {
                debugPrint("ExploreViewModel Error Supabase sync: $err");
              });
            }

            // 2. Only query external Foursquare API if the cell has not been synced yet
            // Self-healing: if the cell is synced but has few places cached locally, sync anyway!
            final localPlacesCount = initialPlaces.length;
            if (isCellSynced && localPlacesCount > 5) {
              debugPrint("ExploreViewModel: Cell $cellId is already synced with $localPlacesCount places. Skipping background external API calls.");
              return;
            }

            final double apiRadius = 2500;

            String? apiKeyword;
            if (hasCategory) {
              final String catLower = category.toLowerCase().trim();
              if (catLower == 'restaurant') {
                apiKeyword = 'restaurant|food';
              } else if (catLower == 'coffee') {
                apiKeyword = 'coffee|cafe';
              } else if (catLower == 'bakery') {
                apiKeyword = 'bakery|bread';
              } else if (catLower == 'juices') {
                apiKeyword = 'juice|smoothie|drinks|lounge';
              } else if (catLower == 'desserts') {
                apiKeyword = 'dessert|sweets|ice_cream';
              } else if (catLower == 'parks') {
                apiKeyword = 'park|garden|playground';
              } else if (catLower == 'hotels') {
                apiKeyword = 'hotel|resort|lodging';
              } else if (catLower == 'movies') {
                apiKeyword = 'cinema|movie';
              } else if (catLower == 'concerts') {
                apiKeyword = 'concert|theater|music';
              } else if (catLower == 'sports') {
                apiKeyword = 'stadium|sports|gym';
              } else {
                apiKeyword = category;
              }
            }

            if (!hasCategory) {
              // Query combined categories in a single request to save API quota
              _exploreRepository.fetchNearbyFoursquarePlaces(
                lat,
                lng,
                radius: apiRadius,
                keyword: 'food|shops|sights',
                cacheOnly: false,
              ).then((places) {
                if (places.isNotEmpty) {
                  _mergeAndUpdatePlaces(places);
                  debugPrint("ExploreViewModel: Background sync completed. Fetched: ${places.length} places.");
                }
              }).catchError((err) {
                debugPrint("ExploreViewModel Error background sync: $err");
              });
            } else {
              _exploreRepository.fetchNearbyFoursquarePlaces(
                lat,
                lng,
                radius: apiRadius,
                keyword: apiKeyword,
                cacheOnly: false,
              ).then((places) {
                _mergeAndUpdatePlaces(places);
                debugPrint("ExploreViewModel: Background sync places completed for category: $category. Fetched: ${places.length}");
              }).catchError((err) {
                debugPrint("ExploreViewModel Error places sync: $err");
              });
            }
          } catch (e) {
            debugPrint("Error in background Foursquare sync: $e");
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching nearby places: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void _mergeAndUpdatePlaces(List<Map<String, dynamic>> newPlaces, {Map<String, dynamic>? supabaseData}) {
    final list = List<Map<String, dynamic>>.from(state.allPlaces);
    final existingIds = list.map((p) => p['id'].toString()).toSet();

    final List<Map<String, dynamic>> checkins = [];
    final List<Map<String, dynamic>> customVenues = [];
    final List<dynamic> postsRaw = [];

    if (supabaseData != null) {
      checkins.addAll(List<Map<String, dynamic>>.from(supabaseData['checkins'] as List? ?? []));
      customVenues.addAll(List<Map<String, dynamic>>.from(supabaseData['customVenues'] as List? ?? []));
      postsRaw.addAll(supabaseData['postsRaw'] as List? ?? []);
    }

    // Track which place IDs the *current* user has visited so we can mark
    // those Foursquare places as isVisited = true (powers the Visited filter).
    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final Set<String> currentUserVisitedPlaceIds = {};

    final placeVisitorsMap = <String, List<Map<String, dynamic>>>{};
    final placeSeenUser = <String, Set<String>>{};

    for (final postObj in postsRaw) {
      final post = postObj as Map<String, dynamic>;
      final placeId = post['place_id']?.toString();
      if (placeId != null && placeId.isNotEmpty) {
        final author = post['author'] as Map<String, dynamic>?;
        final authorId = author?['id'] as String?;
        final authorName = author != null ? '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim() : 'Anonymous';
        final authorAvatar = author?['avatar_url'] as String?;
        final createdAt = post['created_at'] as String? ?? '';
        final double weight = ExploreScreenHelpers.calculateTimeDecayWeight(createdAt);

        // Mark this place as visited by the current user
        if (currentUserId != null && authorId == currentUserId) {
          currentUserVisitedPlaceIds.add(placeId);
        }
        
        placeSeenUser.putIfAbsent(placeId, () => <String>{});
        if (!placeSeenUser[placeId]!.contains(authorName)) {
          placeSeenUser[placeId]!.add(authorName);
          placeVisitorsMap.putIfAbsent(placeId, () => <Map<String, dynamic>>[]).add({
            'userId': authorId,
            'name': authorName,
            'avatarUrl': authorAvatar ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
            'createdAt': createdAt,
            'weight': weight,
          });
        }
      }
    }

    Map<String, dynamic> updatePlaceData(Map<String, dynamic> p) {
      final pid = p['id'].toString();
      final updated = Map<String, dynamic>.from(p);
      updated['isSaved'] = BookmarkTracker().isBookmarked(pid);
      // If the current user has a check-in post for this place, mark it as visited
      if (currentUserVisitedPlaceIds.contains(pid)) {
        updated['isVisited'] = true;
      }
      final int baseCount = p['basePeopleCount'] as int? ?? p['peopleCount'] as int? ?? 0;
      if (placeVisitorsMap.containsKey(pid) && placeVisitorsMap[pid]!.isNotEmpty) {
        final visitors = placeVisitorsMap[pid]!;
        updated['visitors'] = visitors;
        updated['peopleCount'] = visitors.length + baseCount;

        // Decorate the Foursquare place as a check-in pin since visitors are here
        updated['isCheckIn'] = true;
        updated['authorAvatar'] = visitors.first['avatarUrl'];
        updated['authorName'] = visitors.first['name'];
      } else {
        updated['peopleCount'] = baseCount;
        updated['visitors'] = <Map<String, dynamic>>[];
        if (updated['isCustomVenue'] != true && updated['actionType'] != 'check-in') {
          updated['isCheckIn'] = false;
        }
      }
      return updated;
    }

    // 1. Decorate all existing places in the list using the Supabase check-in data
    for (int i = 0; i < list.length; i++) {
      list[i] = updatePlaceData(list[i]);
    }

    // 2. Add/update newPlaces
    for (final p in newPlaces) {
      final updated = updatePlaceData(p);
      final pidStr = p['id'].toString();
      if (!existingIds.contains(pidStr)) {
        list.add(updated);
      } else {
        final index = list.indexWhere((x) => x['id'].toString() == pidStr);
        if (index != -1) {
          list[index] = updated;
        }
      }
    }

    // Build a set of all Foursquare + Custom Venue IDs currently in list to prevent duplicate check-in markers
    final Set<String> existingPlaceIds = list
        .where((p) => p['actionType'] != 'check-in')
        .map((p) => p['id'].toString())
        .toSet();

    for (final c in checkins) {
      final cidStr = c['id'].toString();
      final String? pid = c['place_id']?.toString();

      // If this check-in is at a place that is already on the map, skip it
      if (pid != null && pid.isNotEmpty && existingPlaceIds.contains(pid)) {
        continue;
      }

      if (!existingIds.contains(cidStr)) {
        list.add(c);
      }
      
      final String? avatarUrl = c['authorAvatar'] as String?;
      final String authorName = c['authorName'] as String? ?? 'User';
      final String resolvedType = MarkerGenerator.resolveType(
        c['type']?.toString() ?? '',
        c['name']?.toString() ?? '',
        c['arabicName']?.toString() ?? '',
      );
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        MarkerGenerator.getCheckInCalloutPin(
          type: resolvedType,
          avatarUrl: avatarUrl,
          authorName: authorName,
          isSelected: false,
        ).catchError((e) {
          debugPrint("Failed to pre-download callout pin for false: $e");
          return Uint8List(0);
        });
        MarkerGenerator.getCheckInCalloutPin(
          type: resolvedType,
          avatarUrl: avatarUrl,
          authorName: authorName,
          isSelected: true,
        ).catchError((e) {
          debugPrint("Failed to pre-download callout pin for true: $e");
          return Uint8List(0);
        });
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

    // Pre-cache all check-in callout pins for instant Mapbox loading
    for (final p in list) {
      if (p['isCheckIn'] == true) {
        final String? avatarUrl = p['authorAvatar'] as String?;
        final String authorName = p['authorName'] as String? ?? 'User';
        final String resolvedType = MarkerGenerator.resolveType(
          p['type']?.toString() ?? '',
          p['name']?.toString() ?? '',
          p['arabicName']?.toString() ?? '',
        );
        MarkerGenerator.getCheckInCalloutPin(
          type: resolvedType,
          avatarUrl: avatarUrl,
          authorName: authorName,
          isSelected: false,
        ).catchError((_) => Uint8List(0));
        MarkerGenerator.getCheckInCalloutPin(
          type: resolvedType,
          avatarUrl: avatarUrl,
          authorName: authorName,
          isSelected: true,
        ).catchError((_) => Uint8List(0));
      }
    }

    state = state.copyWith(allPlaces: list, isLoading: false);
  }

  Future<void> searchPlaces(String query) async {
    final lat = state.userLocation?.latitude ?? 24.7136;
    final lng = state.userLocation?.longitude ?? 46.6753;

    state = state.copyWith(isSearching: true, searchQuery: query);
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
        defaultType: place['type']?.toString(),
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

  void updateZoom(double zoom) {
    state = state.copyWith(currentZoom: zoom);
  }

  void incrementMarkersVersion() {
    state = state.copyWith(markersLoadedVersion: state.markersLoadedVersion + 1);
  }

  Timer? _statusBadgeTimer;
  void triggerStatusBadge(String message) {
    _statusBadgeTimer?.cancel();
    state = state.copyWith(
      statusMessage: message,
      showStatusBadge: true,
    );
    _statusBadgeTimer = Timer(const Duration(seconds: 2), () {
      state = state.copyWith(showStatusBadge: false);
    });
  }

  Future<void> clearDatabaseCache() async {
    state = state.copyWith(isLoading: true);
    await ExploreDbCacheService.clearCache();
    state = state.copyWith(allPlaces: [], isLoading: false);
    if (state.lastFetchedLocation != null) {
      await fetchNearbyPlaces(
        state.lastFetchedLocation!.latitude,
        state.lastFetchedLocation!.longitude,
        zoom: state.currentZoom,
      );
    }
  }

  @override
  void dispose() {
    _statusBadgeTimer?.cancel();
    _apiDebounceTimer?.cancel();
    super.dispose();
  }
}
