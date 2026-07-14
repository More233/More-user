import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sections/explore/services/explore_data_service.dart';
import 'explore_repository.dart';

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepositoryImpl();
});

class ExploreRepositoryImpl implements ExploreRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchNearbyFoursquarePlaces(
    double lat, 
    double lng, {
    double radius = 3000, 
    String? keyword,
    bool cacheOnly = false,
  }) {
    return ExploreDataService.fetchNearbyFoursquarePlaces(
      lat, 
      lng, 
      radius: radius, 
      keyword: keyword,
      cacheOnly: cacheOnly,
    );
  }

  @override
  Future<Map<String, dynamic>> fetchSupabaseCheckinsAndVenues(double lat, double lng, {double? boxSize = 0.5}) {
    return ExploreDataService.fetchSupabaseCheckinsAndVenues(lat, lng, boxSize: boxSize);
  }

  @override
  Future<List<Map<String, dynamic>>> searchPlaces(String query, double lat, double lng) {
    return ExploreDataService.searchFoursquarePlaces(query, lat, lng);
  }

  @override
  Future<Map<String, dynamic>?> fetchPlaceDetails(
    String placeId,
    String name,
    double lat,
    double lng,
    double userLat,
    double userLng, {
    String? defaultType,
  }) {
    return ExploreDataService.fetchPlaceDetails(
      placeId,
      name,
      lat,
      lng,
      userLat,
      userLng,
      defaultType: defaultType ?? 'Other',
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchVisitorsForNonFoursquare(Map<String, dynamic> place) {
    return ExploreDataService.fetchVisitorsForNonFoursquare(place);
  }
}
