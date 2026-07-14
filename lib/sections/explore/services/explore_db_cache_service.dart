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
      version: 3,
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute("DROP TABLE IF EXISTS cached_places");
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
        }
      },
    );
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

      for (final item in list) {
        final place = Map<String, dynamic>.from(item as Map);
        batch.insert('cached_places', {
          ...place,
          'cachedAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await batch.commit(noResult: true);
      debugPrint("ExploreDbCacheService: Successfully seeded database with ${list.length} global places.");
    } catch (e) {
      debugPrint("ExploreDbCacheService Error seeding database: $e");
    }
  }

  // Check if database needs to be seeded and run it if count is less than 9702
  static Future<void> _checkAndSeedIfNeeded(Database db) async {
    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM cached_places WHERE id LIKE 'seed_%'"
      );
      final int count = Sqflite.firstIntValue(result) ?? 0;
      if (count < 9702) {
        debugPrint("ExploreDbCacheService: Database needs seeding (count: $count < 9702). Seeding now...");
        await db.delete('cached_places', where: "id LIKE 'seed_%'");
        await seedDatabase(db);
      }
    } catch (e) {
      debugPrint("ExploreDbCacheService Error checking seed count: $e");
    }
  }
}
