import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_details_state.dart';
import '../services/explore_data_service.dart';
import '../services/explore_db_cache_service.dart';
import '../helpers/bookmark_tracker.dart';

final placeDetailsViewModelProvider = StateNotifierProvider.family.autoDispose<
    PlaceDetailsViewModel, PlaceDetailsState, Map<String, dynamic>>((ref, place) {
  return PlaceDetailsViewModel(place: place);
});

class PlaceDetailsViewModel extends StateNotifier<PlaceDetailsState> {
  final Map<String, dynamic> place;

  PlaceDetailsViewModel({required this.place})
      : super(PlaceDetailsState.initial(
          place: place,
          initialImages: _getInitialImages(place),
        )) {
    loadPlaceDetails();
    loadPlacePosts();
    loadSimilarPlaces();
  }

  Future<void> loadPlaceDetails() async {
    try {
      final double lat = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
      final double lng = (place['longitude'] as num?)?.toDouble() ?? 30.697478;
      final String placeId = place['id'].toString();

      // 1. Try to load from SQLite cache first for instant UI response
      final cached = await ExploreDbCacheService.getPlaceById(placeId);
      if (cached != null) {
        final updatedPlace = Map<String, dynamic>.from(place)..addAll(cached);
        List<String> cachedImages = [];
        final List<dynamic>? placePhotos = cached['photos'] as List<dynamic>?;
        if (placePhotos != null && placePhotos.isNotEmpty) {
          cachedImages = List<String>.from(placePhotos.where((img) => img != null && !img.toString().contains('unsplash.com/photo-') && img.toString().isNotEmpty));
        }

        // Fallback check (only if not placeholder)
        if (cachedImages.isEmpty) {
          final String? defaultImg = cached['imageUrl']?.toString();
          if (defaultImg != null && defaultImg.isNotEmpty && !defaultImg.contains('unsplash.com/photo-') && !defaultImg.contains('placeholder_for_')) {
            cachedImages = [defaultImg];
          }
        }

        state = state.copyWith(
          place: updatedPlace,
          images: cachedImages,
        );
      }

      // 2. Check if we need to fetch fresh data from API
      // If cached is null, or it has no photos, or it is stale (cached more than 7 days ago)
      final int cachedAt = cached?['cachedAt'] as int? ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      final bool isStale = (now - cachedAt > 7 * 24 * 60 * 60 * 1000); // 7 days
      final bool hasNoPhotos = cached == null || (cached['photos'] as List?)?.isEmpty == true;

      if (cached == null || isStale || hasNoPhotos) {
        final details = await ExploreDataService.fetchPlaceDetails(
          placeId,
          place['name']?.toString() ?? '',
          lat,
          lng,
          lat,
          lng,
          forceRefresh: true, // Force fresh fetch from APIs
        );

        if (details != null) {
          final updatedPlace = Map<String, dynamic>.from(place)..addAll(details);

          List<String> detailsImages = [];
          final List<dynamic>? placePhotos = details['photos'] as List<dynamic>?;
          if (placePhotos != null && placePhotos.isNotEmpty) {
            detailsImages = List<String>.from(placePhotos.where((img) => img != null && !img.toString().contains('unsplash.com/photo-') && img.toString().isNotEmpty));
          }

          if (detailsImages.isEmpty) {
            final String? defaultImg = details['imageUrl']?.toString();
            if (defaultImg != null && defaultImg.isNotEmpty && !defaultImg.contains('unsplash.com/photo-') && !defaultImg.contains('placeholder_for_')) {
              detailsImages = [defaultImg];
            }
          }

          state = state.copyWith(
            place: updatedPlace,
            images: detailsImages,
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading place details: $e");
    }
  }

  static List<String> _getInitialImages(Map<String, dynamic> place) {
    final List<dynamic>? placePhotos = place['photos'] as List<dynamic>?;
    if (placePhotos != null && placePhotos.isNotEmpty) {
      return List<String>.from(placePhotos.where((img) => img != null && !img.toString().contains('unsplash.com/photo-') && img.toString().isNotEmpty));
    }

    final String? defaultImg = place['imageUrl']?.toString();
    if (defaultImg != null && defaultImg.isNotEmpty) {
      final bool isPlaceholder = defaultImg.contains('unsplash.com/photo-') || defaultImg.contains('placeholder_for_');
      if (!isPlaceholder) {
        return [defaultImg];
      }
    }
    return [];
  }

  Future<void> loadPlacePosts() async {
    state = state.copyWith(isLoadingPosts: true);
    try {
      final client = Supabase.instance.client;
      final postsRes = await client
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(*)')
          .eq('place_id', place['id'].toString())
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> postsList = List<Map<String, dynamic>>.from(postsRes as List);
      
      // If postsList is empty and googleReviews are available, populate them
      if (postsList.isEmpty && place['googleReviews'] != null) {
        final List<dynamic> rawGoogleReviews = place['googleReviews'] as List<dynamic>;
        for (final review in rawGoogleReviews) {
          if (review is Map) {
            postsList.add(Map<String, dynamic>.from(review));
          }
        }
      }

      // Extract people images
      final List<String> imageUrls = [];
      for (final p in postsList) {
        final url = p['image_url'] as String?;
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }

      state = state.copyWith(
        placePosts: postsList,
        peopleImages: imageUrls,
        isLoadingPosts: false,
      );
    } catch (e) {
      debugPrint("Error loading place posts: $e");
      state = state.copyWith(isLoadingPosts: false);
    }
  }

  Future<void> loadSimilarPlaces() async {
    state = state.copyWith(isLoadingSimilar: true);
    try {
      final double lat = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
      final double lng = (place['longitude'] as num?)?.toDouble() ?? 30.697478;
      final String category = place['type']?.toString() ?? '';

      final results = await ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng);
      
      // Filter similar places by category
      final List<Map<String, dynamic>> filtered = [];
      for (final p in results) {
        if (p['id'] == place['id']) continue;

        final String rawUrl = p['imageUrl'] as String? ?? '';
        if (rawUrl.isEmpty) continue;

        if (category.isNotEmpty && p['type'] == category) {
          filtered.add(p);
        }
      }

      if (filtered.length < 5) {
        for (final p in results) {
          if (p['id'] == place['id']) continue;

          final String rawUrl = p['imageUrl'] as String? ?? '';
          if (rawUrl.isEmpty) continue;

          if (!filtered.any((item) => item['id'] == p['id'])) {
            filtered.add(p);
          }
        }
      }

      state = state.copyWith(
        similarPlaces: filtered,
        isLoadingSimilar: false,
      );
    } catch (e) {
      debugPrint("Error loading similar places: $e");
      state = state.copyWith(isLoadingSimilar: false);
    }
  }

  void updatePage(int index) {
    state = state.copyWith(currentPage: index);
  }

  void submitRating(int ratingIndex) {
    state = state.copyWith(selectedRatingIndex: () => ratingIndex);
  }

  void toggleBookmark() {
    final nextSaved = !state.isSaved;
    BookmarkTracker().setBookmarked(place, nextSaved);
    place['isSaved'] = nextSaved;
    state = state.copyWith(isSaved: nextSaved);
  }

  void addCheckInVisitor(String myName, String? avatarUrl) {
    final defaultAvatar = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100';
    final visitorObj = {
      'name': myName,
      'avatarUrl': avatarUrl ?? defaultAvatar,
    };

    final newVisitors = List<Map<String, dynamic>>.from(state.visitors);
    newVisitors.insert(0, visitorObj);

    final placeVisitors = place['visitors'] as List?;
    if (placeVisitors != null) {
      place['visitors'] = [
        visitorObj,
        ...placeVisitors,
      ];
    } else {
      place['visitors'] = [visitorObj];
    }

    state = state.copyWith(
      hasCheckedIn: true,
      visitors: newVisitors,
    );
  }
}
