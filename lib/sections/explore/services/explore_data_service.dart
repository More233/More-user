import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/secrets.dart';
import '../../home/widgets/bottom_sheets/location_search_sheet.dart';
import 'explore_db_cache_service.dart';

class ExploreDataService {
  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: Secrets.googlePlacesApiKey,
  );

  static final http.Client _client = http.Client();
  static final Map<String, List<Map<String, dynamic>>> _placesCache = {};
  static final Map<String, Map<String, dynamic>> _supabaseCache = {};

  static void clearSupabaseCache() {
    _supabaseCache.clear();
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static const List<String> _coffeeImages = [
    'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=500',
    'https://images.unsplash.com/photo-1498804103079-a6351b050096?w=500',
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500',
    'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500',
  ];

  static const List<String> _bakeryImages = [
    'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
    'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=500',
    'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500',
    'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=500',
  ];

  static const List<String> _barImages = [
    'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=500',
    'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=500',
    'https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=500',
    'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=500',
  ];

  static const List<String> _restaurantImages = [
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500',
    'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500',
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=500',
  ];

  static const List<String> _parkImages = [
    'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=500',
    'https://images.unsplash.com/photo-1448375240586-882707db888b?w=500',
    'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=500',
  ];

  static const List<String> _hotelImages = [
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500',
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=500',
    'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=500',
  ];

  static const List<String> _supermarketImages = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500',
    'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500',
  ];

  static const List<String> _pharmacyImages = [
    'https://images.unsplash.com/photo-1607619056574-7b8d304f3c6f?w=500',
    'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=500',
  ];

  static const List<String> _otherImages = [
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=500',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=500',
    'https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=500',
    'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=500',
  ];

  static String getPlaceholderUrl(String type, String id) {
    final int hash = id.hashCode.abs();
    switch (type) {
      case 'Coffee':
        return _coffeeImages[hash % _coffeeImages.length];
      case 'Bakery':
        return _bakeryImages[hash % _bakeryImages.length];
      case 'Bars':
        return _barImages[hash % _barImages.length];
      case 'Restaurant':
        return _restaurantImages[hash % _restaurantImages.length];
      case 'Park':
        return _parkImages[hash % _parkImages.length];
      case 'Airport':
        return 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500';
      case 'Hotel':
        return _hotelImages[hash % _hotelImages.length];
      case 'Supermarket':
        return _supermarketImages[hash % _supermarketImages.length];
      case 'Pharmacy':
        return _pharmacyImages[hash % _pharmacyImages.length];
      default:
        return _otherImages[hash % _otherImages.length];
    }
  }

  static String mapFoursquareCategoryToType(List<dynamic> categories) {
    if (categories.isEmpty) return 'Other';
    final cat = categories.first;
    final String name = (cat['name'] as String? ?? '').toLowerCase();

    if (name.contains('cinema') || name.contains('movie')) {
      return 'Movies';
    }
    if (name.contains('stadium') || name.contains('sports') || name.contains('gym') || name.contains('basketball') || name.contains('soccer') || name.contains('athletic')) {
      return 'Sports';
    }
    if (name.contains('theater') ||
        name.contains('museum') ||
        name.contains('entertainment') ||
        name.contains('ticket') ||
        name.contains('event') ||
        name.contains('show') ||
        name.contains('art gallery') ||
        name.contains('aquarium') ||
        name.contains('zoo') ||
        name.contains('theme park')) {
      return 'Concerts';
    }

    if (name.contains('restaurant') ||
        name.contains('food') ||
        name.contains('dining') ||
        name.contains('diner') ||
        name.contains('pizza') ||
        name.contains('burger') ||
        name.contains('steakhouse') ||
        name.contains('sushi') ||
        name.contains('bistro') ||
        name.contains('grill') ||
        name.contains('eatery')) {
      return 'Restaurant';
    }
    if (name.contains('coffee') ||
        name.contains('cafe') ||
        name.contains('espresso') ||
        name.contains('tea room') ||
        name.contains('coffe')) {
      return 'Coffee';
    }
    if (name.contains('bakery') ||
        name.contains('donut') ||
        name.contains('pastry')) {
      return 'Bakery';
    }
    if (name.contains('dessert') ||
        name.contains('cake') ||
        name.contains('sweet') ||
        name.contains('ice cream') ||
        name.contains('yogurt') ||
        name.contains('candy') ||
        name.contains('creperie')) {
      return 'Desserts';
    }
    if (name.contains('bar') ||
        name.contains('pub') ||
        name.contains('nightclub') ||
        name.contains('lounge') ||
        name.contains('brewery') ||
        name.contains('distillery') ||
        name.contains('juice') ||
        name.contains('smoothie')) {
      return 'Juices';
    }
    if (name.contains('supermarket') ||
        name.contains('grocery') ||
        name.contains('market') ||
        name.contains('convenience') ||
        name.contains('mart')) {
      return 'Supermarket';
    }
    if (name.contains('pharmacy') ||
        name.contains('drugstore') ||
        name.contains('chemist') ||
        name.contains('apothecary')) {
      return 'Pharmacy';
    }
    if (name.contains('hotel') ||
        name.contains('motel') ||
        name.contains('hostel') ||
        name.contains('resort') ||
        name.contains('lodging') ||
        name.contains('inn')) {
      return 'Hotels';
    }
    if (name.contains('park') ||
        name.contains('garden') ||
        name.contains('playground') ||
        name.contains('nature reserve')) {
      return 'Parks';
    }
    if (name.contains('airport') || name.contains('terminal')) {
      return 'Airport';
    }

    final int? id = cat['categoryCode'] as int?;
    if (id != null) {
      if (id == 13065) return 'Restaurant';
      if (id == 13009 || id == 13035) return 'Coffee';
      if (id == 13002) return 'Bakery';
      if (id == 13003) return 'Juices';
      if (id == 17089) return 'Supermarket';
      if (id == 11134) return 'Pharmacy';
    }

    return 'Other';
  }

  static Map<String, dynamic> parseFoursquareVenue(
    Map<String, dynamic> venue,
    double userLat,
    double userLng,
    Map<String, dynamic>? item,
  ) {
    final id = venue['id'] as String? ?? '';
    final name = venue['name'] as String? ?? '';
    final location = venue['location'] as Map<String, dynamic>?;
    final address = location?['address'] as String? ?? 
                    (location?['formattedAddress'] as List<dynamic>?)?.join(', ') ?? '';
    final plat = (location?['lat'] as num?)?.toDouble() ?? userLat;
    final plng = (location?['lng'] as num?)?.toDouble() ?? userLng;
    final categories = venue['categories'] as List<dynamic>? ?? [];

    final double meters = Geolocator.distanceBetween(userLat, userLng, plat, plng);
    final double km = meters / 1000;
    final String distanceStr = km < 1 
        ? '${meters.toStringAsFixed(0)} m' 
        : '${km.toStringAsFixed(1)} km';

    final type = mapFoursquareCategoryToType(categories);

    String? iconUrl;
    if (categories.isNotEmpty) {
      final cat = categories.first;
      final iconObj = cat['icon'] as Map<String, dynamic>?;
      if (iconObj != null) {
        iconUrl = '${iconObj['prefix']}64${iconObj['suffix']}';
      }
    }

    String imageUrl = getPlaceholderUrl(type, id);
    if (item != null) {
      final photo = item['photo'] as Map<String, dynamic>?;
      if (photo != null) {
        final prefix = photo['prefix'] as String? ?? '';
        final suffix = photo['suffix'] as String? ?? '';
        if (prefix.isNotEmpty && suffix.isNotEmpty) {
          imageUrl = '${prefix}500x500$suffix';
        }
      }
    }

    final ratingVal = (venue['rating'] as num?)?.toDouble();
    final double rating = ratingVal != null ? double.parse((ratingVal / 2.0).toStringAsFixed(1)) : 4.0;

    final stats = venue['stats'] as Map<String, dynamic>?;
    final tipCount = (stats?['tipCount'] as num?)?.toInt() ?? 0;
    final checkinsCount = (stats?['checkinsCount'] as num?)?.toInt() ?? 0;
    final int reviewsCount = tipCount > 0 ? tipCount : (checkinsCount > 0 ? (checkinsCount / 12).clamp(1, 100).toInt() : 5);

    return {
      'id': id,
      'name': name,
      'arabicName': name,
      'address': address,
      'latitude': plat,
      'longitude': plng,
      'distance': distanceStr,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'price': r'$$',
      'peopleCount': 0,
      'type': type,
      'imageUrl': imageUrl,
      'isSaved': false,
      'isVisited': false,
      'iconUrl': iconUrl,
      'actionType': getActionTypeForPlaceType(type),
      'isRegistered': false,
      'visitors': <Map<String, dynamic>>[],
    };
  }

  static String mapGooglePlaceTypesToType(List<dynamic> types) {
    if (types.isEmpty) return 'Other';
    final typesLower = types.map((t) => (t as String).toLowerCase()).toList();

    if (typesLower.contains('mosque') || (typesLower.contains('place_of_worship') && !typesLower.contains('church') && !typesLower.contains('synagogue'))) {
      return 'mosque';
    }
    if (typesLower.contains('school') || typesLower.contains('university') || typesLower.contains('primary_school') || typesLower.contains('secondary_school')) {
      return 'school';
    }
    if (typesLower.contains('library')) {
      return 'library';
    }
    if (typesLower.contains('museum') || typesLower.contains('art_gallery')) {
      return 'museum';
    }
    if (typesLower.contains('exhibition_center') || typesLower.contains('convention_center')) {
      return 'exhibition';
    }

    if (typesLower.contains('movie_theater')) {
      return 'Movies';
    }
    if (typesLower.contains('stadium')) {
      return 'Sports';
    }
    if (typesLower.contains('museum') ||
        typesLower.contains('art_gallery') ||
        typesLower.contains('amusement_park') ||
        typesLower.contains('zoo') ||
        typesLower.contains('aquarium') ||
        typesLower.contains('bowling_alley') ||
        typesLower.contains('casino') ||
        typesLower.contains('theater')) {
      return 'Concerts';
    }

    if (typesLower.contains('cafe') || typesLower.contains('coffee') || typesLower.contains('tea_room')) {
      return 'Coffee';
    }
    if (typesLower.contains('bakery') || typesLower.contains('patisserie')) {
      return 'Bakery';
    }
    if (typesLower.contains('dessert_shop') || typesLower.contains('cake_shop') || typesLower.contains('ice_cream_shop') || typesLower.contains('confectionery')) {
      return 'Desserts';
    }
    if (typesLower.contains('bar') || typesLower.contains('night_club') || typesLower.contains('pub') || typesLower.contains('brewery') || typesLower.contains('juice_bar') || typesLower.contains('smoothie_shop')) {
      return 'Juices';
    }
    if (typesLower.contains('restaurant') || typesLower.contains('meal_takeaway') || typesLower.contains('meal_delivery') || typesLower.contains('food')) {
      return 'Restaurant';
    }
    if (typesLower.contains('supermarket') || typesLower.contains('grocery_or_supermarket') || typesLower.contains('convenience_store') || typesLower.contains('department_store')) {
      return 'Supermarket';
    }
    if (typesLower.contains('pharmacy') || typesLower.contains('drugstore')) {
      return 'Pharmacy';
    }
    if (typesLower.contains('lodging') || typesLower.contains('hotel') || typesLower.contains('resort')) {
      return 'Hotels';
    }
    if (typesLower.contains('park') || typesLower.contains('tourist_attraction') || typesLower.contains('museum') || typesLower.contains('zoo') || typesLower.contains('amusement_park')) {
      return 'Parks';
    }
    if (typesLower.contains('airport') || typesLower.contains('transit_station') || typesLower.contains('subway_station') || typesLower.contains('train_station') || typesLower.contains('bus_station')) {
      return 'Airport';
    }
    return 'Other';
  }

  static Map<String, dynamic> parseGooglePlace(
    Map<String, dynamic> place,
    double userLat,
    double userLng,
  ) {
    final id = place['place_id'] as String? ?? '';
    final name = place['name'] as String? ?? '';
    
    final geometry = place['geometry'] as Map<String, dynamic>?;
    final locationObj = geometry?['location'] as Map<String, dynamic>?;
    final plat = (locationObj?['lat'] as num?)?.toDouble() ?? userLat;
    final plng = (locationObj?['lng'] as num?)?.toDouble() ?? userLng;
    
    final address = place['vicinity'] as String? ?? place['formatted_address'] as String? ?? '';
    final types = place['types'] as List<dynamic>? ?? [];

    final double meters = Geolocator.distanceBetween(userLat, userLng, plat, plng);
    final double km = meters / 1000;
    final String distanceStr = km < 1 
        ? '${meters.toStringAsFixed(0)} m' 
        : '${km.toStringAsFixed(1)} km';

    final type = mapGooglePlaceTypesToType(types);

    final ratingVal = (place['rating'] as num?)?.toDouble();
    final double rating = ratingVal ?? 4.0;
    final reviewsCount = (place['user_ratings_total'] as num?)?.toInt() ?? 5;

    final photos = place['photos'] as List<dynamic>?;
    String imageUrl = getPlaceholderUrl(type, id);
    final List<String> photoUrls = [];
    if (photos != null && photos.isNotEmpty) {
      for (final photo in photos) {
        final photoRef = photo['photo_reference'] as String?;
        if (photoRef != null && photoRef.isNotEmpty) {
          photoUrls.add('https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$photoRef&key=$googlePlacesApiKey');
        }
      }
      if (photoUrls.isNotEmpty) {
        imageUrl = photoUrls.first;
      }
    }

    final website = place['website'] as String?;
    final phone = place['formatted_phone_number'] as String?;

    final openingHours = place['opening_hours'] as Map<String, dynamic>?;
    final bool? openNow = openingHours?['open_now'] as bool?;
    final List<dynamic>? weekdayText = openingHours?['weekday_text'] as List<dynamic>?;

    // Parse Google Reviews if present
    final List<dynamic>? rawReviews = place['reviews'] as List<dynamic>?;
    final List<Map<String, dynamic>> googleReviews = [];
    if (rawReviews != null) {
      for (final r in rawReviews) {
        final String authorName = r['author_name'] as String? ?? 'Anonymous';
        final names = authorName.split(' ');
        final String firstName = names.isNotEmpty ? names.first : 'Anonymous';
        final String lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        googleReviews.add({
          'id': 'google_review_${r['time']}_${authorName.hashCode}',
          'place_id': id,
          'title': '',
          'description': r['text'] as String? ?? '',
          'created_at': DateTime.fromMillisecondsSinceEpoch((r['time'] as int? ?? 0) * 1000).toIso8601String(),
          'author': {
            'first_name': firstName,
            'last_name': lastName,
            'avatar_url': r['profile_photo_url'] as String? ?? '',
          }
        });
      }
    }

    return {
      'id': id,
      'name': name,
      'arabicName': name,
      'address': address,
      'latitude': plat,
      'longitude': plng,
      'distance': distanceStr,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'price': r'$$',
      'peopleCount': 0,
      'type': type,
      'imageUrl': imageUrl,
      'photos': photoUrls,
      'isSaved': false,
      'isVisited': false,
      'iconUrl': null,
      'actionType': getActionTypeForPlaceType(type),
      'isRegistered': false,
      'visitors': <Map<String, dynamic>>[],
      'website': website,
      'phone': phone,
      'googleReviews': googleReviews,
      'openNow': openNow,
      'weekdayText': weekdayText != null ? List<String>.from(weekdayText) : null,
    };
  }

  static Future<void> seedRealGlobalPlacesFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeeded = prefs.getBool('global_places_seeded_api') ?? false;
      if (hasSeeded) return;

      debugPrint("ExploreDataService: Running one-time global startup Places API fetch...");

      final List<Map<String, double>> startupLocations = [
        {'lat': 24.7136, 'lng': 46.6753}, // Riyadh
        {'lat': 25.2048, 'lng': 55.2708}, // Dubai
        {'lat': 30.0444, 'lng': 31.2357}, // Cairo
        {'lat': 51.5074, 'lng': -0.1278}, // London
        {'lat': 40.7128, 'lng': -74.0060}, // New York
      ];

      for (final loc in startupLocations) {
        // Run a background fetch (radius 10km) for each city to pull 20 real active places
        fetchNearbyFoursquarePlaces(
          loc['lat']!,
          loc['lng']!,
          radius: 10000,
          cacheOnly: false,
        ).catchError((e) {
          debugPrint("Startup seed failed for ${loc['lat']}, ${loc['lng']}: $e");
          return <Map<String, dynamic>>[];
        });
      }

      await prefs.setBool('global_places_seeded_api', true);
      debugPrint("ExploreDataService: Scheduled background Google Places API fetch for 5 global cities.");
    } catch (e) {
      debugPrint("ExploreDataService: Error in startup seeding: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchNearbyFoursquarePlaces(
    double lat,
    double lng, {
    double radius = 3000,
    String? keyword,
    bool cacheOnly = false,
  }) async {
    final int roundedLat = (lat * 100).round();
    final int roundedLng = (lng * 100).round();
    final String cacheKey = '${roundedLat}_${roundedLng}_${radius.toInt()}_${keyword ?? ''}';

    // 1. Check in-memory Cache
    if (!cacheOnly && _placesCache.containsKey(cacheKey)) {
      _log("ExploreDataService: Returning cached Google places (in-memory) for key: $cacheKey");
      return _placesCache[cacheKey]!;
    }

    // 2. Compute bounding box for SQLite cache query
    final double latDelta = radius / 111000.0;
    final double radLat = lat * 3.141592653589793 / 180.0;
    final double cosLat = math.cos(radLat);
    final double lngDelta = radius / (111000.0 * (cosLat < 0.01 ? 0.01 : cosLat));

    final double minLat = lat - latDelta;
    final double maxLat = lat + latDelta;
    final double minLng = lng - lngDelta;
    final double maxLng = lng + lngDelta;

    // 3. Query local SQLite database
    final List<Map<String, dynamic>> cachedPlaces = await ExploreDbCacheService.getPlacesInBoundingBox(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );

    final double gridLat = (lat * 100).round() / 100.0;
    final double gridLng = (lng * 100).round() / 100.0;
    final String cellId = '${gridLat.toStringAsFixed(2)}_${gridLng.toStringAsFixed(2)}';

    if (cacheOnly) {
      _log("ExploreDataService: Returning cached places (cacheOnly). Count: ${cachedPlaces.length}");
      return cachedPlaces;
    }

    final bool isCellSynced = await ExploreDbCacheService.isCellSynced(cellId);
    if (isCellSynced && (keyword == null || keyword.isEmpty)) {
      _log("ExploreDataService: Cell $cellId already synced. Returning cache. Count: ${cachedPlaces.length}");
      _placesCache[cacheKey] = cachedPlaces;
      return cachedPlaces;
    }

    // 4. Fetch fresh places from Google Places API if cache is empty or stale
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=${radius.toInt()}'
          '&language=en'
          '&key=$googlePlacesApiKey';

      if (keyword != null && keyword.isNotEmpty) {
        url += '&keyword=${Uri.encodeComponent(keyword)}';
      }

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Google Places API URL: $url");
        debugPrint("Google Places API Response Status: ${data['status']}, error_message: ${data['error_message']}");
        final results = data['results'] as List<dynamic>? ?? [];
        debugPrint("Google Places API results count: ${results.length}");
        final List<Map<String, dynamic>> places = [];
        for (final item in results) {
          final place = item as Map<String, dynamic>;
          final parsed = parseGooglePlace(place, lat, lng);
          if (parsed['type'] != 'Airport') {
            places.add(parsed);
          }
        }

        // Limit to 2 pages to increase density while keeping load fast in the background
        final int maxPages = 2;

        // Handle pagination to fetch up to 60 places (maxPages)
        String? nextPageToken = data['next_page_token'] as String?;
        int pageCount = 1;
        while (nextPageToken != null && nextPageToken.isNotEmpty && pageCount < maxPages) {
          // Google Places API token has a small delay before it becomes valid
          await Future<void>.delayed(const Duration(milliseconds: 2000));
          
          final String nextPageUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
              '?pagetoken=$nextPageToken'
              '&key=$googlePlacesApiKey';
              
          final nextPageResponse = await _client.get(Uri.parse(nextPageUrl));
          if (nextPageResponse.statusCode == 200) {
            final nextPageData = json.decode(nextPageResponse.body);
            final nextPageResults = nextPageData['results'] as List<dynamic>? ?? [];
            for (final item in nextPageResults) {
              final place = item as Map<String, dynamic>;
              final parsed = parseGooglePlace(place, lat, lng);
              if (parsed['type'] != 'Airport') {
                places.add(parsed);
              }
            }
            nextPageToken = nextPageData['next_page_token'] as String?;
            pageCount++;
          } else {
            break;
          }
        }

        // Save to SQLite cache and mark region synced asynchronously (background)
        // This decouples disk write latency entirely from the UI response!
        ExploreDbCacheService.savePlaces(places);
        ExploreDbCacheService.markRegionSynced(lat, lng, radius);

        _placesCache[cacheKey] = places;
        return places;
      }
    } catch (e) {
      debugPrint("Error fetching Google nearby places: $e");
    }

    // Fallback to SQLite cache if API fails
    if (cachedPlaces.isNotEmpty) {
      debugPrint("ExploreDataService API failed: Falling back to local cache. Count: ${cachedPlaces.length}");
      return cachedPlaces;
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> searchFoursquarePlaces(String query, double lat, double lng) async {
    final List<Map<String, dynamic>> places = [];
    
    final String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(query)}'
        '&location=$lat,$lng'
        '&radius=50000'
        '&language=en'
        '&key=$googlePlacesApiKey';

    final double latMin = lat - 1.5;
    final double latMax = lat + 1.5;
    final double lngMin = lng - 1.5;
    final double lngMax = lng + 1.5;
    final client = Supabase.instance.client;

    try {
      final results = await Future.wait<dynamic>([
        _client.get(Uri.parse(url)),
        client
            .from('custom_venues')
            .select('*')
            .ilike('name', '%$query%')
            .gte('latitude', latMin)
            .lte('latitude', latMax)
            .gte('longitude', lngMin)
            .lte('longitude', lngMax)
            .limit(10),
      ]);

      final httpResponse = results[0] as http.Response;
      final venuesResponse = results[1];

      if (httpResponse.statusCode == 200) {
        final data = json.decode(httpResponse.body);
        final resultsList = data['results'] as List<dynamic>? ?? [];
        for (final item in resultsList) {
          final place = item as Map<String, dynamic>;
          final parsed = parseGooglePlace(place, lat, lng);
          if (parsed['type'] != 'Airport') {
            places.add(parsed);
          }
        }

        // Limit to 1 page to make loading instant (Google requires a 2-second delay per additional page)
        String? nextPageToken = data['next_page_token'] as String?;
        int pageCount = 1;
        while (nextPageToken != null && nextPageToken.isNotEmpty && pageCount < 1) {
          // Google Places API token has a small delay before it becomes valid
          await Future<void>.delayed(const Duration(milliseconds: 2000));
          
          final String nextPageUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?pagetoken=$nextPageToken'
              '&key=$googlePlacesApiKey';
              
          final nextPageResponse = await _client.get(Uri.parse(nextPageUrl));
          if (nextPageResponse.statusCode == 200) {
            final nextPageData = json.decode(nextPageResponse.body);
            final nextPageResults = nextPageData['results'] as List<dynamic>? ?? [];
            for (final item in nextPageResults) {
              final place = item as Map<String, dynamic>;
              final parsed = parseGooglePlace(place, lat, lng);
              if (parsed['type'] != 'Airport') {
                places.add(parsed);
              }
            }
            nextPageToken = nextPageData['next_page_token'] as String?;
            pageCount++;
          } else {
            break;
          }
        }
      }

      final venueResults = List<Map<String, dynamic>>.from(venuesResponse as List);
      for (final res in venueResults) {
        final id = res['id'] as String;
        if (places.any((p) => p['id'] == id)) continue;

        final plat = (res['latitude'] as num).toDouble();
        final plng = (res['longitude'] as num).toDouble();
        final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        places.add({
          'id': id,
          'name': res['name'] as String,
          'arabicName': res['name'] as String,
          'address': res['address'] as String,
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'rating': 4.5,
          'reviewsCount': 5,
          'price': r'$$',
          'peopleCount': 3,
          'type': res['category_name'] as String? ?? 'default',
          'imageUrl': getPlaceholderUrl(res['category_name'] as String? ?? 'Other', id),
          'isSaved': false,
          'isVisited': false,
          'actionType': getActionTypeForPlaceType(res['category_name'] as String? ?? 'Other'),
          'isCustomVenue': true,
        });
      }
    } catch (e) {
      debugPrint("Error performing parallel search: $e");
    }

    // Fallback: search local hardcoded locations matching search query
    final lowerQuery = query.toLowerCase();
    for (final loc in LocationSearchSheet.locations) {
      final name = loc['name'] as String;
      final address = loc['address'] as String;
      if (name.toLowerCase().contains(lowerQuery) || address.toLowerCase().contains(lowerQuery)) {
        if (places.any((p) => p['name'] == name)) continue;

        final plat = loc['latitude'] as double;
        final plng = loc['longitude'] as double;
        final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        places.add({
          'id': 'tapped_${name.hashCode}',
          'name': name,
          'arabicName': name,
          'address': address,
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'rating': 4.5,
          'reviewsCount': 10,
          'price': r'$$',
          'peopleCount': 2,
          'type': 'Other',
          'imageUrl': getPlaceholderUrl('Other', name),
          'isSaved': false,
          'isVisited': false,
          'actionType': getActionTypeForPlaceType('Other'),
        });
      }
    }

    if (places.isNotEmpty) {
      ExploreDbCacheService.savePlaces(places);
    }
    return places;
  }

  static Future<Map<String, dynamic>?> fetchPlaceDetails(
    String placeId,
    String defaultName,
    double defaultLat,
    double defaultLng,
    double userLat,
    double userLng, {
    String defaultType = 'Other',
  }) async {
    Map<String, dynamic>? placeMap;
    List<dynamic> visitorsRes = [];

    final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&language=en'
        '&key=$googlePlacesApiKey';

    final client = Supabase.instance.client;

    try {
      final results = await Future.wait<dynamic>([
        _client.get(Uri.parse(url)),
        client
            .from('posts')
            .select('*, author:profiles!posts_user_id_fkey(*)')
            .eq('place_id', placeId)
            .eq('is_private', false)
            .order('created_at', ascending: false)
            .limit(10),
      ]);

      final httpResponse = results[0] as http.Response;
      visitorsRes = results[1] as List<dynamic>;

      if (httpResponse.statusCode == 200) {
        final data = json.decode(httpResponse.body);
        final result = data['result'] as Map<String, dynamic>?;
        if (result != null) {
          placeMap = parseGooglePlace(result, userLat, userLng);
        }
      }
    } catch (e) {
      debugPrint("Error performing parallel place details fetch: $e");
    }

    if (placeMap == null) {
      final double meters = Geolocator.distanceBetween(userLat, userLng, defaultLat, defaultLng);
      final double km = meters / 1000;
      final String distanceStr = km < 1 
          ? '${meters.toStringAsFixed(0)} m' 
          : '${km.toStringAsFixed(1)} km';

      placeMap = {
        'id': placeId,
        'name': defaultName,
        'arabicName': defaultName,
        'address': '',
        'latitude': defaultLat,
        'longitude': defaultLng,
        'distance': distanceStr,
        'rating': 4.5,
        'reviewsCount': 0,
        'price': r'$$',
        'peopleCount': 0,
        'type': defaultType,
        'imageUrl': getPlaceholderUrl(defaultType, placeId),
        'isSaved': false,
        'isVisited': false,
        'iconUrl': null,
        'actionType': getActionTypeForPlaceType(defaultType),
        'isRegistered': false,
        'visitors': <Map<String, dynamic>>[],
        'website': null,
        'phone': null,
      };
    }

    try {
      final list = List<Map<String, dynamic>>.from(visitorsRes);
      final List<Map<String, dynamic>> parsedVisitors = [];
      for (final v in list) {
        final author = v['author'] as Map<String, dynamic>?;
        if (author != null) {
          final String name = '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim();
          parsedVisitors.add({
            'userId': author['id'] as String?,
            'name': name.isEmpty ? 'Anonymous' : name,
            'avatarUrl': author['avatar_url'] as String?,
            'createdAt': v['created_at'] as String? ?? '',
          });
        }
      }
      
      final seen = <String>{};
      final uniqueVisitors = <Map<String, dynamic>>[];
      for (final visitor in parsedVisitors) {
        final name = visitor['name'] as String;
        if (!seen.contains(name)) {
          seen.add(name);
          uniqueVisitors.add(visitor);
        }
      }

      placeMap['visitors'] = uniqueVisitors;
      placeMap['peopleCount'] = uniqueVisitors.length;
      if (uniqueVisitors.isNotEmpty) {
        placeMap['reviewsCount'] = uniqueVisitors.length;
      }
    } catch (e) {
      debugPrint("Error loading visitors in service for ${placeMap['id']}: $e");
    }

    // Save details to cache
    ExploreDbCacheService.savePlaces([placeMap]);

    return placeMap;
  }

  static Future<Map<String, dynamic>> fetchSupabaseCheckinsAndVenues(double lat, double lng, {double? boxSize = 0.5}) async {
    final int roundedLat = (lat * 100).round();
    final int roundedLng = (lng * 100).round();
    final String cacheKey = '${roundedLat}_${roundedLng}_${boxSize ?? 'global'}';

    if (_supabaseCache.containsKey(cacheKey)) {
      _log("ExploreDataService: Returning cached Supabase checkins/venues for key: $cacheKey");
      return _supabaseCache[cacheKey]!;
    }

    final List<Map<String, dynamic>> checkins = [];
    final List<Map<String, dynamic>> customVenues = [];
    List<Map<String, dynamic>> postResults = [];

    try {
      final client = Supabase.instance.client;
      
      final currentUserId = client.auth.currentUser?.id;
      var postsQuery = client
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(*)');
          
      if (currentUserId != null) {
        postsQuery = postsQuery.or('is_private.eq.false,user_id.eq.$currentUserId');
      } else {
        postsQuery = postsQuery.eq('is_private', false);
      }
          
      var venuesQuery = client
          .from('custom_venues')
          .select('*, creator:profiles(*)');

      if (boxSize != null) {
        final double latMin = lat - boxSize;
        final double latMax = lat + boxSize;
        final double lngMin = lng - boxSize;
        final double lngMax = lng + boxSize;

        postsQuery = postsQuery
            .gte('latitude', latMin)
            .lte('latitude', latMax)
            .gte('longitude', lngMin)
            .lte('longitude', lngMax);

        venuesQuery = venuesQuery
            .gte('latitude', latMin)
            .lte('latitude', latMax)
            .gte('longitude', lngMin)
            .lte('longitude', lngMax);
      }

      final results = await Future.wait<dynamic>([
        postsQuery,
        venuesQuery,
      ]);

      final postsResponse = results[0];
      final venuesResponse = results[1];

      postResults = List<Map<String, dynamic>>.from(postsResponse as List);
      for (final res in postResults) {
        final author = res['author'] as Map<String, dynamic>?;
        final authorName = author != null ? '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim() : 'Anonymous';
        final authorAvatar = author?['avatar_url'] as String?;
        final plat = (res['latitude'] as num).toDouble();
        final plng = (res['longitude'] as num).toDouble();

        final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        checkins.add({
          'id': res['id'] as String,
          'name': res['title'] as String? ?? 'Check-in',
          'address': res['location_address'] as String? ?? '',
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'rating': 5.0,
          'reviewsCount': 1,
          'price': r'$$',
          'peopleCount': 1,
          'type': res['category_name'] as String? ?? 'default',
          'imageUrl': res['image_url'] as String? ?? getPlaceholderUrl(res['category_name'] as String? ?? 'Other', res['id'] as String? ?? ''),
          'isSaved': false,
          'isVisited': true,
          'actionType': 'check-in',
          'isCheckIn': true,
          'authorName': authorName,
          'authorAvatar': authorAvatar,
          'description': res['description'] as String? ?? '',
          'stickerIndex': res['sticker_index'] as int? ?? -1,
          'createdAt': res['created_at'] as String? ?? '',
        });
      }

      final venueResults = List<Map<String, dynamic>>.from(venuesResponse as List);
      for (final res in venueResults) {
        final plat = (res['latitude'] as num).toDouble();
        final plng = (res['longitude'] as num).toDouble();

        final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        customVenues.add({
          'id': res['id'] as String,
          'name': res['name'] as String,
          'address': res['address'] as String,
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'rating': 4.5,
          'reviewsCount': 5,
          'price': r'$$',
          'peopleCount': 0,
          'type': res['category_name'] as String? ?? 'default',
          'imageUrl': getPlaceholderUrl(res['category_name'] as String? ?? 'Other', res['id'] as String? ?? ''),
          'isSaved': false,
          'isVisited': false,
          'actionType': getActionTypeForPlaceType(res['category_name'] as String? ?? 'Other'),
          'isCustomVenue': true,
        });
      }
    } catch (e) {
      debugPrint("Error fetching Supabase checkins and venues: $e");
    }

    final Map<String, dynamic> finalResult = {
      'checkins': checkins,
      'customVenues': customVenues,
      'postsRaw': postResults,
    };
    _supabaseCache[cacheKey] = finalResult;
    return finalResult;
  }

  static Future<Map<String, dynamic>?> fetchVisitorsForNonFoursquare(Map<String, dynamic> place) async {
    final placeId = place['id'].toString();
    try {
      final client = Supabase.instance.client;
      final visitorsRes = await client
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(*)')
          .eq('place_id', placeId)
          .eq('is_private', false)
          .order('created_at', ascending: false)
          .limit(10);

      final updatedPlace = Map<String, dynamic>.from(place);
      final list = List<Map<String, dynamic>>.from(visitorsRes as List);
      final List<Map<String, dynamic>> parsedVisitors = [];
      for (final v in list) {
        final author = v['author'] as Map<String, dynamic>?;
        if (author != null) {
          final String name = '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim();
          parsedVisitors.add({
            'name': name.isEmpty ? 'Anonymous' : name,
            'avatarUrl': author['avatar_url'] as String?,
            'createdAt': v['created_at'] as String? ?? '',
          });
        }
      }
      
      final seen = <String>{};
      final uniqueVisitors = <Map<String, dynamic>>[];
      for (final visitor in parsedVisitors) {
        final name = visitor['name'] as String;
        if (!seen.contains(name)) {
          seen.add(name);
          uniqueVisitors.add(visitor);
        }
      }

      updatedPlace['visitors'] = uniqueVisitors;
      updatedPlace['peopleCount'] = uniqueVisitors.length;
      if (uniqueVisitors.isNotEmpty) {
        updatedPlace['reviewsCount'] = uniqueVisitors.length;
      }
      return updatedPlace;
    } catch (e) {
      debugPrint("Error fetching visitors for non-foursquare place $placeId: $e");
      return place;
    }
  }

  static int calculateSimulatedBusyness(String placeId, int reviewsCount) {
    // 1. Generate a stable hash from the place ID
    final int hash = placeId.hashCode.abs();
    
    // Only simulate crowd for ~20% of popular venues to keep map clean (Swarm-style crowd density)
    if ((hash % 10) >= 2) {
      return 0;
    }
    
    // 2. Get current hour of the day
    final int hour = DateTime.now().hour;
    
    // 3. Compute scale factor based on the hour (busier in the afternoon and evening)
    double hourScale = 0.1;
    if (hour >= 6 && hour < 11) {
      hourScale = 0.2 + (hour - 6) * 0.06; // 0.2 to 0.5
    } else if (hour >= 11 && hour < 15) {
      hourScale = 0.8 - (hour - 11) * 0.05; // 0.8 to 0.6
    } else if (hour >= 15 && hour < 17) {
      hourScale = 0.5 + (hour - 15) * 0.05; // 0.5 to 0.6
    } else if (hour >= 17 && hour < 22) {
      hourScale = 0.8 + (hour - 17) * 0.04; // 0.8 to 1.0
    } else if (hour >= 22) {
      hourScale = 0.7 - (hour - 22) * 0.2; // 0.7 to 0.3
    } else {
      // 00:00 - 06:00
      hourScale = 0.1;
    }

    // 4. Base count on reviewsCount (more reviews = more popular)
    final int reviewsBracket = reviewsCount > 500 
        ? 15 
        : reviewsCount > 200 
            ? 12 
            : reviewsCount > 50 
                ? 9 
                : reviewsCount > 10 
                    ? 6 
                    : 3;
                    
    // 5. Add some stable variation using the hash
    final int hashVariation = hash % 5; // 0 to 4
    
    final double rawPeopleCount = (reviewsBracket + hashVariation) * hourScale;
    
    final int peopleCount = rawPeopleCount.round();
    return peopleCount < 2 ? (reviewsCount > 0 ? 2 : 0) : peopleCount;
  }

  static String getActionTypeForPlaceType(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'hotel' || t == 'ticket' || t == 'movies' || t == 'sports' || t == 'concerts') {
      return 'Book';
    } else if (t == 'restaurant' ||
        t == 'bakery' ||
        t == 'coffee' ||
        t == 'bars' ||
        t == 'supermarket' ||
        t == 'pharmacy') {
      return 'Order';
    } else {
      return 'check-in';
    }
  }
}
