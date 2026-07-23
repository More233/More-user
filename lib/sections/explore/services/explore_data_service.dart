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
      'peopleCount': calculateSimulatedBusyness(id, reviewsCount),
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
          markSynced: false,
        ).catchError((e) {
          debugPrint("Startup seed failed for ${loc['lat']}, ${loc['lng']}: $e");
          return <Map<String, dynamic>>[];
        });
      }

      await prefs.setBool('global_places_seeded_api', true);
      debugPrint("ExploreDataService: Scheduled background Foursquare Places API fetch for 5 global cities.");
    } catch (e) {
      debugPrint("ExploreDataService: Error in startup seeding: $e");
    }
  }

  static const String foursquareApiKey = String.fromEnvironment(
    'FOURSQUARE_API_KEY',
    defaultValue: Secrets.foursquareApiKey,
  );


  static const String googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: Secrets.googlePlacesApiKey,
  );

  static final bool _isGooglePlacesKeyValid = googlePlacesApiKey.isNotEmpty && 
      googlePlacesApiKey != 'YOUR_GOOGLE_PLACES_API_KEY';

  static String? mapKeywordsToFoursquareCategories(String keyword) {
    final List<String> categories = [];
    final parts = keyword.toLowerCase().split('|');
    for (final part in parts) {
      final p = part.trim();
      if (p == 'restaurant' || p == 'dining') {
        categories.add('13065');
      } else if (p == 'food') {
        categories.add('13000');
      } else if (p == 'shops') {
        categories.add('17000');
      } else if (p == 'sights') {
        categories.add('10000,16000,19000');
      } else if (p == 'cafe' || p == 'coffee' || p == 'coffe' || p == 'espresso') {
        categories.add('13035');
      } else if (p == 'bakery' || p == 'bread' || p == 'pastry') {
        categories.add('13002');
      } else if (p == 'juice' || p == 'smoothie' || p == 'drinks') {
        categories.add('13003');
      } else if (p == 'bar' || p == 'pub' || p == 'nightclub' || p == 'night_club' || p == 'lounge') {
        categories.add('13003,13400');
      } else if (p == 'dessert' || p == 'sweets' || p == 'ice_cream' || p == 'cake') {
        categories.add('13040');
      } else if (p == 'park' || p == 'garden' || p == 'playground') {
        categories.add('16032');
      } else if (p == 'hotel' || p == 'resort' || p == 'lodging') {
        categories.add('19014');
      } else if (p == 'cinema' || p == 'movie') {
        categories.add('10024');
      } else if (p == 'concert' || p == 'theater' || p == 'music' || p == 'event' || p == 'show') {
        categories.add('10000');
      } else if (p == 'stadium' || p == 'sports' || p == 'gym') {
        categories.add('18000');
      } else if (p == 'mall') {
        categories.add('17114');
      } else if (p == 'store' || p == 'shop') {
        categories.add('17000');
      } else if (p == 'supermarket' || p == 'market') {
        categories.add('17089');
      } else if (p == 'museum') {
        categories.add('10027');
      } else if (p == 'mosque') {
        categories.add('12099');
      }
    }
    return categories.isNotEmpty ? categories.join(',') : null;
  }

  static Map<String, dynamic> parseFoursquareV3Venue(
    Map<String, dynamic> venue,
    double userLat,
    double userLng,
  ) {
    final id = venue['fsq_place_id'] as String? ?? venue['fsq_id'] as String? ?? venue['id'] as String? ?? '';
    final name = venue['name'] as String? ?? '';
    final location = venue['location'] as Map<String, dynamic>?;
    final address = location?['formatted_address'] as String? ?? 
                    location?['address'] as String? ?? '';
    
    final geocodes = venue['geocodes'] as Map<String, dynamic>?;
    final mainGeocode = geocodes?['main'] as Map<String, dynamic>?;
    final plat = (venue['latitude'] as num?)?.toDouble() ??
                 (mainGeocode?['latitude'] as num?)?.toDouble() ?? 
                 (location?['lat'] as num?)?.toDouble() ?? userLat;
    final plng = (venue['longitude'] as num?)?.toDouble() ??
                 (mainGeocode?['longitude'] as num?)?.toDouble() ?? 
                 (location?['lng'] as num?)?.toDouble() ?? userLng;

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

    final List<String> parsedPhotos = [];
    final photosList = venue['photos'] as List<dynamic>? ?? [];
    int count = 0;
    for (final p in photosList) {
      if (count >= 10) break;
      if (p is Map) {
        final prefix = p['prefix'] as String? ?? '';
        final suffix = p['suffix'] as String? ?? '';
        if (prefix.isNotEmpty && suffix.isNotEmpty) {
          parsedPhotos.add('${prefix}original$suffix');
          count++;
        }
      }
    }

    String imageUrl = parsedPhotos.isNotEmpty ? parsedPhotos.first : getPlaceholderUrl(type, id);

    final ratingVal = (venue['rating'] as num?)?.toDouble();
    final double rating = ratingVal != null ? double.parse((ratingVal / 2.0).toStringAsFixed(1)) : 4.0;

    final priceTier = (venue['price'] as num?)?.toInt() ?? 2;
    final priceStr = r'$' * priceTier;

    final popularity = (venue['popularity'] as num?)?.toDouble() ?? 0.8;
    final int reviewsCount = (popularity * 100).toInt().clamp(5, 1000);

    final hoursObj = venue['hours'] as Map<String, dynamic>?;
    final bool? openNow = hoursObj?['open_now'] as bool?;
    final String? displayHours = hoursObj?['display'] as String?;
    final List<String> weekdayText = displayHours != null && displayHours.isNotEmpty ? [displayHours] : [];

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
      'price': priceStr,
      'peopleCount': calculateSimulatedBusyness(id, reviewsCount),
      'type': type,
      'imageUrl': imageUrl,
      'photos': parsedPhotos,
      'isSaved': false,
      'isVisited': false,
      'iconUrl': iconUrl,
      'actionType': getActionTypeForPlaceType(type),
      'isRegistered': false,
      'visitors': <Map<String, dynamic>>[],
      'website': venue['website'] as String?,
      'phone': venue['tel'] as String?,
      'openNow': openNow,
      'weekdayText': weekdayText.isNotEmpty ? weekdayText : null,
    };
  }

  static String mapGoogleTypesToType(List<dynamic> googleTypes) {
    if (googleTypes.isEmpty) return 'Other';
    final List<String> types = googleTypes.map((t) => t.toString().toLowerCase()).toList();

    if (types.contains('cafe') || types.contains('coffee_shop')) {
      return 'Coffee';
    }
    if (types.contains('bakery')) {
      return 'Bakery';
    }
    if (types.contains('restaurant') || types.contains('food') || types.contains('meal_takeaway') || types.contains('meal_delivery')) {
      return 'Restaurant';
    }
    if (types.contains('bar') || types.contains('night_club') || types.contains('liquor_store')) {
      return 'Juices';
    }
    if (types.contains('supermarket') || types.contains('grocery_or_supermarket') || types.contains('convenience_store') || types.contains('shopping_mall')) {
      return 'Supermarket';
    }
    if (types.contains('pharmacy') || types.contains('drugstore')) {
      return 'Pharmacy';
    }
    if (types.contains('lodging') || types.contains('hotel')) {
      return 'Hotels';
    }
    if (types.contains('park') || types.contains('tourist_attraction') || types.contains('amusement_park') || types.contains('campground')) {
      return 'Parks';
    }
    if (types.contains('airport')) {
      return 'Airport';
    }
    if (types.contains('movie_theater') || types.contains('cinema')) {
      return 'Movies';
    }
    if (types.contains('stadium') || types.contains('gym') || types.contains('sports_complex')) {
      return 'Sports';
    }
    if (types.contains('museum') ||
        types.contains('art_gallery') ||
        types.contains('aquarium') ||
        types.contains('zoo') ||
        types.contains('theater')) {
      return 'Concerts';
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
    final address = place['vicinity'] as String? ?? place['formatted_address'] as String? ?? '';
    
    final geometry = place['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final plat = (location?['lat'] as num?)?.toDouble() ?? userLat;
    final plng = (location?['lng'] as num?)?.toDouble() ?? userLng;
    
    final types = place['types'] as List<dynamic>? ?? [];
    final type = mapGoogleTypesToType(types);

    final double meters = Geolocator.distanceBetween(userLat, userLng, plat, plng);
    final double km = meters / 1000;
    final String distanceStr = km < 1 
        ? '${meters.toStringAsFixed(0)} m' 
        : '${km.toStringAsFixed(1)} km';

    final iconUrl = place['icon'] as String?;

    final List<String> parsedPhotos = [];
    final photosList = place['photos'] as List<dynamic>? ?? [];
    int count = 0;
    for (final p in photosList) {
      if (count >= 10) break;
      if (p is Map) {
        final photoRef = p['photo_reference'] as String? ?? '';
        if (photoRef.isNotEmpty) {
          parsedPhotos.add(
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$photoRef&key=$googlePlacesApiKey'
          );
          count++;
        }
      }
    }

    final imageUrl = parsedPhotos.isNotEmpty ? parsedPhotos.first : getPlaceholderUrl(type, id);

    final ratingVal = (place['rating'] as num?)?.toDouble() ?? 4.0;
    final reviewsCount = (place['user_ratings_total'] as num?)?.toInt() ?? 5;

    final priceLevel = (place['price_level'] as num?)?.toInt() ?? 2;
    final priceStr = r'$' * priceLevel;

    final hoursObj = place['opening_hours'] as Map<String, dynamic>?;
    final bool? openNow = hoursObj?['open_now'] as bool?;
    final weekdayText = List<String>.from(hoursObj?['weekday_text'] as List? ?? []);

    return {
      'id': id,
      'name': name,
      'arabicName': name,
      'address': address,
      'latitude': plat,
      'longitude': plng,
      'distance': distanceStr,
      'rating': ratingVal,
      'reviewsCount': reviewsCount,
      'price': priceStr,
      'peopleCount': calculateSimulatedBusyness(id, reviewsCount),
      'type': type,
      'imageUrl': imageUrl,
      'photos': parsedPhotos,
      'isSaved': false,
      'isVisited': false,
      'iconUrl': iconUrl,
      'actionType': getActionTypeForPlaceType(type),
      'isRegistered': false,
      'visitors': <Map<String, dynamic>>[],
      'website': place['website'] as String?,
      'phone': (place['formatted_phone_number'] as String? ?? place['international_phone_number'] as String?),
      'openNow': openNow,
      'weekdayText': weekdayText.isNotEmpty ? weekdayText : null,
    };
  }

  static String? cleanKeywordForGoogle(String? keyword) {
    if (keyword == null || keyword.isEmpty || keyword == 'food|shops|sights') {
      return null;
    }
    return keyword.replaceAll('|', ' ');
  }

  static Future<List<Map<String, dynamic>>> fetchNearbyFoursquarePlaces(
    double lat,
    double lng, {
    double radius = 3000,
    String? keyword,
    bool cacheOnly = false,
    bool markSynced = true,
  }) async {
    final int roundedLat = (lat * 100).round();
    final int roundedLng = (lng * 100).round();
    final String cacheKey = '${roundedLat}_${roundedLng}_${radius.toInt()}_${keyword ?? ''}';

    // 1. Check in-memory Cache
    if (!cacheOnly && _placesCache.containsKey(cacheKey)) {
      _log("ExploreDataService: Returning cached places (in-memory) for key: $cacheKey");
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
    if (isCellSynced && (keyword == null || keyword.isEmpty || keyword == 'food|shops|sights')) {
      _log("ExploreDataService: Cell $cellId already synced. Returning cache. Count: ${cachedPlaces.length}");
      _placesCache[cacheKey] = cachedPlaces;
      return cachedPlaces;
    }

    // 4. Fetch fresh places from Google Places (no Foursquare fallback)
    List<Map<String, dynamic>> places = [];

    if (_isGooglePlacesKeyValid) {
      try {
        final double googleRadius = radius.clamp(10.0, 50000.0);
        String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=$lat,$lng'
            '&radius=${googleRadius.toInt()}'
            '&language=ar'
            '&key=$googlePlacesApiKey';

        final cleanedKeyword = cleanKeywordForGoogle(keyword);
        if (cleanedKeyword != null && cleanedKeyword.isNotEmpty) {
          url += '&keyword=${Uri.encodeComponent(cleanedKeyword)}';
        }

        final response = await _client.get(Uri.parse(url));

        debugPrint("Google Nearby Search API Response Status: ${response.statusCode}, Body length: ${response.body.length}");

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List<dynamic>? ?? [];
          for (final item in results) {
            final place = item as Map<String, dynamic>;
            final parsed = parseGooglePlace(place, lat, lng);
            if (parsed['type'] != 'Airport') {
              places.add(parsed);
            }
          }
          if (markSynced && (keyword == null || keyword.isEmpty || keyword == 'food|shops|sights')) {
            final double gridLat = (lat * 100).round() / 100.0;
            final double gridLng = (lng * 100).round() / 100.0;
            final String cellId = '${gridLat.toStringAsFixed(2)}_${gridLng.toStringAsFixed(2)}';
            ExploreDbCacheService.markCellSynced(cellId);
          }
        } else {
          debugPrint("Google Places Nearby Search API Error: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        debugPrint("Error fetching Google Places nearby places: $e");
      }
    }

    if (places.isNotEmpty) {
      // Save results to SQLite cache asynchronously (background)
      ExploreDbCacheService.savePlaces(places);
      _placesCache[cacheKey] = places;
      return places;
    }

    // Fallback to SQLite cache if API fails and returned no new places
    if (cachedPlaces.isNotEmpty) {
      debugPrint("ExploreDataService API failed: Falling back to local cache. Count: ${cachedPlaces.length}");
      return cachedPlaces;
    }

    return [];
  }



  static Future<List<Map<String, dynamic>>> searchFoursquarePlaces(String query, double lat, double lng) async {
    final List<Map<String, dynamic>> places = [];
    
    final normQuery = query.toLowerCase();
    final hasCityExplicitly = normQuery.contains('رياض') || normQuery.contains('riyadh') ||
                              normQuery.contains('حلوان') || normQuery.contains('helwan') ||
                              normQuery.contains('قاهره') || normQuery.contains('قاهرة') || normQuery.contains('cairo') ||
                              normQuery.contains('جيزه') || normQuery.contains('جيزة') || normQuery.contains('giza') ||
                              normQuery.contains('زقازيق') || normQuery.contains('zagazig');

    final double range = hasCityExplicitly ? 1.5 : 0.08;
    final double latMin = lat - range;
    final double latMax = lat + range;
    final double lngMin = lng - range;
    final double lngMax = lng + range;
    final client = Supabase.instance.client;

    try {
      // 1. Fetch custom venues from Supabase (wrapped in a nested try-catch so database issues don't prevent Google search)
      try {
        final currentUserId = client.auth.currentUser?.id;
        var venuesQuery = client
            .from('custom_venues')
            .select('*')
            .ilike('name', '%$query%')
            .gte('latitude', latMin)
            .lte('latitude', latMax)
            .gte('longitude', lngMin)
            .lte('longitude', lngMax);

        if (currentUserId != null) {
          venuesQuery = venuesQuery.or('is_private.eq.false,created_by.eq.$currentUserId');
        } else {
          venuesQuery = venuesQuery.eq('is_private', false);
        }

        final venuesResponse = await venuesQuery.limit(10);

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
        debugPrint("Error fetching custom venues from Supabase: $e");
      }

      // 2. Fetch fresh places from Google Places (if key is valid, no Foursquare fallback)
      if (_isGooglePlacesKeyValid) {
        try {
          final String googleSearchUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?query=${Uri.encodeComponent(query)}'
              '&location=$lat,$lng'
              '&radius=50000'
              '&language=ar'
              '&key=$googlePlacesApiKey';

          final httpResponse = await _client.get(Uri.parse(googleSearchUrl));

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
          } else {
            debugPrint("Google Places Search API Error: ${httpResponse.statusCode} - ${httpResponse.body}");
          }
        } catch (e) {
          debugPrint("Error performing Google Places search API call: $e");
        }
      }
    } catch (e) {
      debugPrint("Error performing search: $e");
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


  static Future<List<dynamic>> _fetchSupabaseVisitors(String placeId) async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(*)')
          .eq('place_id', placeId)
          .eq('is_private', false)
          .order('created_at', ascending: false)
          .limit(10);
      return res as List<dynamic>? ?? [];
    } catch (e) {
      debugPrint("Error fetching supabase visitors for place: $e");
      return [];
    }
  }

  static List<Map<String, dynamic>> _parseVisitors(List<dynamic> visitorsRes) {
    final List<Map<String, dynamic>> parsedVisitors = [];
    for (final v in visitorsRes) {
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
    return uniqueVisitors;
  }

  static Future<Map<String, dynamic>?> fetchPlaceDetails(
    String placeId,
    String defaultName,
    String? defaultArabicName,
    double defaultLat,
    double defaultLng,
    double userLat,
    double userLng, {
    String defaultType = 'Other',
    bool forceRefresh = false,
  }) async {
    Map<String, dynamic>? placeMap;
    List<dynamic> visitorsRes = [];

    // 1. Check local SQLite cache first (unless forceRefresh is true)
    if (!forceRefresh) {
      try {
        final cached = await ExploreDbCacheService.getPlaceById(placeId);
        if (cached != null) {
          final List<dynamic>? photos = cached['photos'] as List<dynamic>?;
          if (photos != null && photos.isNotEmpty) {
            _log("ExploreDataService: Returning cached place details with photos for: $placeId");
            visitorsRes = await _fetchSupabaseVisitors(placeId);
            cached['visitors'] = _parseVisitors(visitorsRes);
            cached['peopleCount'] = cached['visitors'].length;
            if (cached['visitors'].isNotEmpty) {
              cached['reviewsCount'] = cached['visitors'].length;
            }
            return cached;
          }
        }
      } catch (e) {
        debugPrint("Error reading cached place details: $e");
      }
    }

    final bool isGoogleId = !placeId.startsWith('tapped_') &&
                            !placeId.startsWith('swarm_') &&
                            !placeId.startsWith('checkin_') &&
                            !placeId.startsWith('custom_') &&
                            placeId.length >= 10;
    String? cleanPlaceId;

    if (isGoogleId && !placeId.startsWith('seed_')) {
      cleanPlaceId = placeId;
    } else if (placeId.startsWith('seed_') && _isGooglePlacesKeyValid) {
      // Resolve seed place to a Google Place ID dynamically
      try {
        final String searchUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent(defaultName)}'
            '&location=$defaultLat,$defaultLng'
            '&radius=500'
            '&language=ar'
            '&key=$googlePlacesApiKey';
        final response = await _client.get(Uri.parse(searchUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List<dynamic>? ?? [];
          if (results.isNotEmpty) {
            final venue = results.first as Map<String, dynamic>;
            final foundId = venue['place_id'] as String?;
            if (foundId != null) {
              cleanPlaceId = foundId;
              debugPrint("Resolved seeded place '$defaultName' to Google Place ID: $cleanPlaceId");
            }
          }
        }
      } catch (e) {
        debugPrint("Error resolving seeded place to Google Place ID: $e");
      }
    }

    if (cleanPlaceId != null && _isGooglePlacesKeyValid) {
      final String url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$cleanPlaceId'
          '&fields=place_id,name,formatted_address,geometry,rating,user_ratings_total,price_level,types,website,formatted_phone_number,opening_hours,photos'
          '&language=ar'
          '&key=$googlePlacesApiKey';

      try {
        final results = await Future.wait<dynamic>([
          _client.get(Uri.parse(url)),
          _fetchSupabaseVisitors(placeId),
        ]);

        final httpResponse = results[0] as http.Response;
        visitorsRes = results[1] as List<dynamic>;

        if (httpResponse.statusCode == 200) {
          final data = json.decode(httpResponse.body);
          final result = data['result'] as Map<String, dynamic>?;
          if (result != null) {
            placeMap = parseGooglePlace(result, userLat, userLng);
            // Keep original id so we update database cache correctly
            placeMap['id'] = placeId;
            
            // Preserve original Arabic name if Google returned English but we have Arabic
            if (defaultArabicName != null && defaultArabicName.isNotEmpty) {
              final String parsedAr = placeMap['arabicName']?.toString() ?? '';
              final bool containsAr = RegExp(r'[\u0600-\u06FF]').hasMatch(parsedAr);
              if (!containsAr) {
                placeMap['arabicName'] = defaultArabicName;
              }
            }
          }
        } else {
          debugPrint("Google Places Details API Error: ${httpResponse.statusCode} - ${httpResponse.body}");
        }
      } catch (e) {
        debugPrint("Error performing parallel Google Places details fetch: $e");
      }
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
        'arabicName': defaultArabicName ?? defaultName,
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
        'photos': <String>[],
        'isSaved': false,
        'isVisited': false,
        'iconUrl': null,
        'actionType': getActionTypeForPlaceType(defaultType),
        'isRegistered': false,
        'visitors': <Map<String, dynamic>>[],
        'website': null,
        'phone': null,
      };
      
      visitorsRes = await _fetchSupabaseVisitors(placeId);
    }

    try {
      final uniqueVisitors = _parseVisitors(visitorsRes);
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
      // Note: custom_venues does not have an is_private column — fetch all venues in the area

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
          'place_id': res['place_id'] as String?,
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
