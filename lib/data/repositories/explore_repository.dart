abstract class ExploreRepository {
  Future<List<Map<String, dynamic>>> fetchNearbyFoursquarePlaces(
    double lat, 
    double lng, {
    double radius = 3000, 
    String? keyword,
    bool cacheOnly = false,
  });
  Future<Map<String, dynamic>> fetchSupabaseCheckinsAndVenues(double lat, double lng, {double? boxSize = 0.5});
  Future<List<Map<String, dynamic>>> searchPlaces(String query, double lat, double lng);
  Future<Map<String, dynamic>?> fetchPlaceDetails(
    String placeId,
    String name,
    double lat,
    double lng,
    double userLat,
    double userLng, {
    String? defaultType,
  });
  Future<Map<String, dynamic>?> fetchVisitorsForNonFoursquare(Map<String, dynamic> place);
}
