import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sections/explore/services/explore_data_service.dart';
import 'explore_repository.dart';

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepositoryImpl();
});

class ExploreRepositoryImpl implements ExploreRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchNearbyFoursquarePlaces(double lat, double lng) {
    return ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng);
  }

  @override
  Future<Map<String, dynamic>> fetchSupabaseCheckinsAndVenues(double lat, double lng) {
    return ExploreDataService.fetchSupabaseCheckinsAndVenues(lat, lng);
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
    double userLng,
  ) {
    return ExploreDataService.fetchPlaceDetails(
      placeId,
      name,
      lat,
      lng,
      userLat,
      userLng,
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchVisitorsForNonFoursquare(Map<String, dynamic> place) {
    return ExploreDataService.fetchVisitorsForNonFoursquare(place);
  }
}
