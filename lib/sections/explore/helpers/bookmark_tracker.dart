import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarkTracker {
  static final BookmarkTracker _instance = BookmarkTracker._internal();
  factory BookmarkTracker() => _instance;
  BookmarkTracker._internal();

  Map<String, Map<String, dynamic>> _bookmarkedPlaces = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // 1. Load from local cache first
    try {
      final file = await _getTrackerFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        _bookmarkedPlaces = map.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
        // Clean up any previous corrupted/invalid keys
        _bookmarkedPlaces.remove("");
        _bookmarkedPlaces.remove("null");
      }
    } catch (e) {
      debugPrint("Error loading bookmarked places from local file: $e");
    }

    // 2. Load from Supabase and merge/override if logged in
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final response = await client
            .from('saved_places')
            .select('place_id, place_data')
            .eq('user_id', user.id);
        
        final List<dynamic> list = response as List<dynamic>;
        for (final item in list) {
          final String placeId = item['place_id']?.toString() ?? '';
          if (placeId.isEmpty || placeId == "null") continue;
          final Map<String, dynamic> placeData = Map<String, dynamic>.from(item['place_data'] as Map);
          // Ensure the UI knows it's saved
          placeData['isSaved'] = true;
          _bookmarkedPlaces[placeId] = placeData;
        }
        // Sync back to local file so local cache stays up to date
        final file = await _getTrackerFile();
        await file.writeAsString(jsonEncode(_bookmarkedPlaces));
      }
    } catch (e) {
      debugPrint("Error loading bookmarked places from Supabase: $e");
    }

    _initialized = true;
  }

  Future<File> _getTrackerFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/bookmarked_places.json');
  }

  bool isBookmarked(String placeId) {
    if (placeId == "null" || placeId.trim().isEmpty) return false;
    return _bookmarkedPlaces.containsKey(placeId);
  }

  List<Map<String, dynamic>> getBookmarkedPlaces() {
    return _bookmarkedPlaces.values.toList();
  }

  Future<void> setBookmarked(Map<String, dynamic> place, bool isSaved) async {
    await init();
    final String placeId = place['id']?.toString() ?? '';
    if (placeId.isEmpty || placeId == "null") {
      debugPrint("Warning: Trying to bookmark a place with invalid ID: $placeId");
      return;
    }
    
    if (isSaved) {
      final placeCopy = Map<String, dynamic>.from(place);
      placeCopy['isSaved'] = true; // Ensure isSaved is true
      _bookmarkedPlaces[placeId] = placeCopy;
    } else {
      _bookmarkedPlaces.remove(placeId);
    }

    // 1. Save to local file
    try {
      final file = await _getTrackerFile();
      await file.writeAsString(jsonEncode(_bookmarkedPlaces));
    } catch (e) {
      debugPrint("Error saving bookmarked places to local file: $e");
    }

    // 2. Save to Supabase if logged in
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        if (isSaved) {
          await client.from('saved_places').upsert(
            {
              'user_id': user.id,
              'place_id': placeId,
              'place_data': place,
            },
            onConflict: 'user_id,place_id',
          );
        } else {
          await client
              .from('saved_places')
              .delete()
              .eq('user_id', user.id)
              .eq('place_id', placeId);
        }
      }
    } catch (e) {
      debugPrint("Error updating bookmarked place in Supabase: $e");
    }
  }
}
