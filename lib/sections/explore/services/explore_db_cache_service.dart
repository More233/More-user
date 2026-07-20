import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ExploreDbCacheService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    await _checkAndSeedIfNeeded(_database!);
    return _database!;
  }

  static Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'explore_places_cache.db');

    return await openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_places (
            id TEXT PRIMARY KEY,
            name TEXT,
            arabicName TEXT,
            address TEXT,
            latitude REAL,
            longitude REAL,
            rating REAL,
            reviewsCount INTEGER,
            price TEXT,
            peopleCount INTEGER,
            type TEXT,
            imageUrl TEXT,
            photos TEXT,
            isSaved INTEGER,
            isVisited INTEGER,
            actionType TEXT,
            isRegistered INTEGER,
            googleReviews TEXT,
            openNow INTEGER,
            weekdayText TEXT,
            cachedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_cached_places_coords 
          ON cached_places (latitude, longitude)
        ''');
        await db.execute('''
          CREATE TABLE sync_grid_cells (
            cell_id TEXT PRIMARY KEY,
            synced_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 9) {
          await db.execute("DROP TABLE IF EXISTS cached_places");
          await db.execute("DROP TABLE IF EXISTS sync_grid_cells");
          await db.execute('''
            CREATE TABLE cached_places (
              id TEXT PRIMARY KEY,
              name TEXT,
              arabicName TEXT,
              address TEXT,
              latitude REAL,
              longitude REAL,
              rating REAL,
              reviewsCount INTEGER,
              price TEXT,
              peopleCount INTEGER,
              type TEXT,
              imageUrl TEXT,
              photos TEXT,
              isSaved INTEGER,
              isVisited INTEGER,
              actionType TEXT,
              isRegistered INTEGER,
              googleReviews TEXT,
              openNow INTEGER,
              weekdayText TEXT,
              cachedAt INTEGER
            )
          ''');
          await db.execute('''
            CREATE INDEX idx_cached_places_coords 
            ON cached_places (latitude, longitude)
          ''');
          await db.execute('''
            CREATE TABLE sync_grid_cells (
              cell_id TEXT PRIMARY KEY,
              synced_at INTEGER
            )
          ''');
        }
      },
    );
  }

  // Check if a grid cell has been synced with API in last 3 days
  static Future<bool> isCellSynced(String cellId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'sync_grid_cells',
        where: 'cell_id = ?',
        whereArgs: [cellId],
      );
      if (maps.isEmpty) return false;
      
      final int syncedAt = maps.first['synced_at'] as int? ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      // 3 days = 3 * 24 * 60 * 60 * 1000 ms
      return (now - syncedAt < 3 * 24 * 60 * 60 * 1000);
    } catch (e) {
      debugPrint("ExploreDbCacheService Error checking cell sync: $e");
      return false;
    }
  }

  // Mark a grid cell as synced with the current timestamp
  static Future<void> markCellSynced(String cellId) async {
    try {
      final db = await database;
      final int now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'sync_grid_cells',
        {
          'cell_id': cellId,
          'synced_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("ExploreDbCacheService: Marked cell $cellId as synced.");
    } catch (e) {
      debugPrint("ExploreDbCacheService Error marking cell synced: $e");
    }
  }

  // Mark a range of grid cells as synced
  static Future<void> markRegionSynced(double centerLat, double centerLng, double radiusInMeters) async {
    try {
      final db = await database;
      final int now = DateTime.now().millisecondsSinceEpoch;
      
      final batch = db.batch();
      // Round to 2 decimal places (grid cell coordinates)
      final int centerGridLat = (centerLat * 100).round();
      final int centerGridLng = (centerLng * 100).round();
      
      // Limit to 5x5 grid around the center (approx 5.5km area) to keep database writes fast and lightweight
      for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
          final double gridLat = (centerGridLat + i) / 100.0;
          final double gridLng = (centerGridLng + j) / 100.0;
          final String cellId = '${gridLat.toStringAsFixed(2)}_${gridLng.toStringAsFixed(2)}';
          
          batch.insert(
            'sync_grid_cells',
            {
              'cell_id': cellId,
              'synced_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
      debugPrint("ExploreDbCacheService: Marked 5x5 grid cells around ($centerLat, $centerLng) as synced.");
    } catch (e) {
      debugPrint("ExploreDbCacheService Error marking region synced: $e");
    }
  }

  // Save a list of parsed places to database
  static Future<void> savePlaces(List<Map<String, dynamic>> places) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final place in places) {
        final String id = place['id'] as String? ?? '';
        if (id.isEmpty) continue;

        final List<dynamic> photosList = place['photos'] as List<dynamic>? ?? [];
        final List<dynamic> reviewsList = place['googleReviews'] as List<dynamic>? ?? [];
        final List<dynamic> weekdayTextList = place['weekdayText'] as List<dynamic>? ?? [];

        final int isSaved = (place['isSaved'] as bool? ?? false) ? 1 : 0;
        final int isVisited = (place['isVisited'] as bool? ?? false) ? 1 : 0;
        final int isRegistered = (place['isRegistered'] as bool? ?? false) ? 1 : 0;
        
        final bool? openNowBool = place['openNow'] as bool?;
        final int? openNow = openNowBool == null ? null : (openNowBool ? 1 : 0);

        batch.insert(
          'cached_places',
          {
            'id': id,
            'name': place['name'] as String? ?? '',
            'arabicName': place['arabicName'] as String? ?? '',
            'address': place['address'] as String? ?? '',
            'latitude': (place['latitude'] as num? ?? 0.0).toDouble(),
            'longitude': (place['longitude'] as num? ?? 0.0).toDouble(),
            'rating': (place['rating'] as num? ?? 4.0).toDouble(),
            'reviewsCount': (place['reviewsCount'] as num? ?? 0).toInt(),
            'price': place['price'] as String? ?? r'$$',
            'peopleCount': (place['peopleCount'] as num? ?? 0).toInt(),
            'type': place['type'] as String? ?? 'Other',
            'imageUrl': place['imageUrl'] as String? ?? '',
            'photos': json.encode(photosList),
            'isSaved': isSaved,
            'isVisited': isVisited,
            'actionType': place['actionType'] as String? ?? 'visit',
            'isRegistered': isRegistered,
            'googleReviews': json.encode(reviewsList),
            'openNow': openNow,
            'weekdayText': json.encode(weekdayTextList),
            'cachedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      debugPrint("ExploreDbCacheService: Successfully cached ${places.length} places in local SQLite database.");
    } catch (e) {
      debugPrint("ExploreDbCacheService Error saving places: $e");
    }
  }

  // Query places within a bounding box
  static Future<List<Map<String, dynamic>>> getPlacesInBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'cached_places',
        where: 'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?',
        whereArgs: [minLat, maxLat, minLng, maxLng],
      );

      if (maps.length > 100) {
        return await compute(_parseDbRows, maps);
      } else {
        return _parseDbRows(maps);
      }
    } catch (e) {
      debugPrint("ExploreDbCacheService Error querying places in bounding box: $e");
      return [];
    }
  }

  // Clear expired places (older than the given duration)
  static Future<void> clearExpiredPlaces(Duration age) async {
    try {
      final db = await database;
      final expirationTime = DateTime.now().subtract(age).millisecondsSinceEpoch;
      final count = await db.delete(
        'cached_places',
        where: 'cachedAt < ? AND id NOT LIKE ?',
        whereArgs: [expirationTime, 'seed_%'],
      );
      if (count > 0) {
        debugPrint("ExploreDbCacheService: Cleared $count expired places from local SQLite database.");
      }
    } catch (e) {
      debugPrint("ExploreDbCacheService Error clearing expired places: $e");
    }
  }

  // Seed database with pre-populated JSON places
  static Future<void> seedDatabase(Database db) async {
    try {
      final String jsonStr = await rootBundle.loadString('assets/explore/seeded_places.json');
      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      final batch = db.batch();
      
      final now = DateTime.now().millisecondsSinceEpoch;

      // Unconditionally add premium global landmarks from user screenshots
      final List<Map<String, dynamic>> premiumLandmarks = [
        {
          "id": "seed_cairo_knoll_coffee",
          "name": "Knoll Coffee Roasters",
          "arabicName": "محمصة ومقهى نول",
          "address": "Knoll Coffee Roasters, Cairo, Egypt",
          "latitude": 30.0444,
          "longitude": 31.2357,
          "rating": 4.8,
          "reviewsCount": 250,
          "price": "\$\$",
          "peopleCount": 15,
          "type": "Coffee",
          "imageUrl": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 1,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_riyadh_mado",
          "name": "Mado",
          "arabicName": "مادو",
          "address": "Mado, Riyadh, Saudi Arabia",
          "latitude": 24.7136,
          "longitude": 46.6753,
          "rating": 4.5,
          "reviewsCount": 890,
          "price": "\$\$\$",
          "peopleCount": 42,
          "type": "Coffee",
          "imageUrl": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 1,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_zanzibar_kendwa_beach",
          "name": "Kendwa Beach",
          "arabicName": "شاطئ كيندوا",
          "address": "Kendwa Beach, Zanzibar, Tanzania",
          "latitude": -5.7417,
          "longitude": 39.2942,
          "rating": 4.7,
          "reviewsCount": 1200,
          "price": "\$\$",
          "peopleCount": 80,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_namibia_etosha",
          "name": "Etosha National Park",
          "arabicName": "محمية إيتوشا الوطنية",
          "address": "Etosha National Park, Namibia",
          "latitude": -18.8556,
          "longitude": 16.3292,
          "rating": 4.9,
          "reviewsCount": 3400,
          "price": "\$\$\$",
          "peopleCount": 120,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1516426122078-c23e76319801?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_cape_town_kirstenbosch",
          "name": "Kirstenbosch Botanical Gardens",
          "arabicName": "حدائق كيرستنبوش النباتية",
          "address": "Kirstenbosch Botanical Gardens, Cape Town, South Africa",
          "latitude": -33.9903,
          "longitude": 18.4323,
          "rating": 4.8,
          "reviewsCount": 5600,
          "price": "\$\$",
          "peopleCount": 210,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_jhb_yfm",
          "name": "YFM",
          "arabicName": "محطة واي إف إم",
          "address": "YFM Radio Station, Johannesburg, South Africa",
          "latitude": -26.1367,
          "longitude": 28.0531,
          "rating": 4.2,
          "reviewsCount": 85,
          "price": "\$",
          "peopleCount": 4,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_lagos_banana_island",
          "name": "Banana Island",
          "arabicName": "جزيرة الموز",
          "address": "Banana Island, Lagos, Nigeria",
          "latitude": 6.4590,
          "longitude": 3.4866,
          "rating": 4.5,
          "reviewsCount": 450,
          "price": "\$\$\$\$",
          "peopleCount": 35,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_london_heathrow",
          "name": "Heathrow Airport",
          "arabicName": "مطار هيثرو",
          "address": "Heathrow Airport, London, United Kingdom",
          "latitude": 51.4700,
          "longitude": -0.4543,
          "rating": 4.4,
          "reviewsCount": 9800,
          "price": "\$\$\$",
          "peopleCount": 450,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        },
        {
          "id": "seed_istanbul_taksim",
          "name": "Taksim Square",
          "arabicName": "ميدان تقسيم",
          "address": "Taksim Square, Istanbul, Turkey",
          "latitude": 41.0370,
          "longitude": 28.9850,
          "rating": 4.6,
          "reviewsCount": 15400,
          "price": "\$",
          "peopleCount": 850,
          "type": "Other",
          "imageUrl": "https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=500",
          "photos": "[]",
          "isSaved": 0,
          "isVisited": 0,
          "actionType": "check-in",
          "isRegistered": 0,
          "googleReviews": "[]",
          "openNow": 1,
          "weekdayText": "[]"
        }
      ];

      for (final place in premiumLandmarks) {
        batch.insert('cached_places', {
          ...place,
          'cachedAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final item in list) {
        final place = Map<String, dynamic>.from(item as Map);
        batch.insert('cached_places', {
          ...place,
          'cachedAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await batch.commit(noResult: true);
      debugPrint("ExploreDbCacheService: Successfully seeded database with ${list.length + premiumLandmarks.length} global places.");
    } catch (e) {
      debugPrint("ExploreDbCacheService Error seeding database: $e");
    }
  }

  // Check if database needs to be seeded - enabled to ensure rich visual density globally
  static Future<void> _checkAndSeedIfNeeded(Database db) async {
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT COUNT(*) as count FROM cached_places WHERE id LIKE 'seed_%'"
      );
      final int count = maps.first['count'] as int? ?? 0;
      if (count == 0) {
        debugPrint("ExploreDbCacheService: No seeded places found. Seeding database in background...");
        await seedDatabase(db);
      } else {
        debugPrint("ExploreDbCacheService: Already seeded with $count places.");
      }
    } catch (e) {
      debugPrint("ExploreDbCacheService Error checking/seeding database: $e");
    }
  }

  static Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('cached_places');
      await db.delete('sync_grid_cells');
      debugPrint("ExploreDbCacheService: All local place caches and sync grid cells cleared successfully.");
    } catch (e) {
      debugPrint("ExploreDbCacheService Error clearing cache: $e");
    }
  }
}

// Top-level function for background isolate parsing of DB rows
List<Map<String, dynamic>> _parseDbRows(List<Map<String, dynamic>> maps) {
  final List<Map<String, dynamic>> results = [];
  for (final map in maps) {
    List<dynamic> photos = [];
    try {
      if (map['photos'] != null) {
        photos = json.decode(map['photos'] as String) as List<dynamic>;
      }
    } catch (_) {}

    List<dynamic> googleReviews = [];
    try {
      if (map['googleReviews'] != null) {
        googleReviews = json.decode(map['googleReviews'] as String) as List<dynamic>;
      }
    } catch (_) {}

    List<dynamic> weekdayText = [];
    try {
      if (map['weekdayText'] != null) {
        weekdayText = json.decode(map['weekdayText'] as String) as List<dynamic>;
      }
    } catch (_) {}

    final int? openNowInt = map['openNow'] as int?;
    final bool? openNow = openNowInt == null ? null : (openNowInt == 1);

    results.add({
      'id': map['id'],
      'name': map['name'],
      'arabicName': map['arabicName'],
      'address': map['address'],
      'latitude': map['latitude'],
      'longitude': map['longitude'],
      'rating': map['rating'],
      'reviewsCount': map['reviewsCount'],
      'price': map['price'],
      'peopleCount': map['peopleCount'],
      'type': map['type'],
      'imageUrl': map['imageUrl'],
      'photos': List<String>.from(photos),
      'isSaved': map['isSaved'] == 1,
      'isVisited': map['isVisited'] == 1,
      'actionType': map['actionType'],
      'isRegistered': map['isRegistered'] == 1,
      'googleReviews': List<Map<String, dynamic>>.from(
        googleReviews.map((r) => Map<String, dynamic>.from(r as Map)),
      ),
      'openNow': openNow,
      'weekdayText': weekdayText.isNotEmpty ? List<String>.from(weekdayText) : null,
      'cachedAt': map['cachedAt'],
    });
  }
  return results;
}
