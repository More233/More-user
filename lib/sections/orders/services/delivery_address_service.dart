import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/secrets.dart';
import '../models/delivery_address_model.dart';

class DeliveryAddressService {
  static final DeliveryAddressService instance = DeliveryAddressService._internal();
  DeliveryAddressService._internal();

  static const String _storageKey = 'saved_delivery_address';
  final ValueNotifier<DeliveryAddressModel?> currentAddress = ValueNotifier<DeliveryAddressModel?>(null);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        currentAddress.value = DeliveryAddressModel.fromJson(jsonStr);
      }
    } catch (e) {
      debugPrint('Error loading saved delivery address: $e');
    }
  }

  Future<void> saveAddress(DeliveryAddressModel address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, address.toJson());
      currentAddress.value = address;
    } catch (e) {
      debugPrint('Error saving delivery address: $e');
    }
  }

  Future<void> clearAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      currentAddress.value = null;
    } catch (e) {
      debugPrint('Error clearing delivery address: $e');
    }
  }

  /// Determines whether coordinates fall within service coverage (e.g. Saudi Arabia)
  bool isLocationCovered(double lat, double lng, {String? countryCode, String? fullAddress}) {
    if (countryCode != null && countryCode.toLowerCase() == 'sa') return true;
    if (fullAddress != null && (fullAddress.contains('السعودية') || fullAddress.contains('Saudi'))) {
      return true;
    }
    // Check Saudi Arabia bounding box coordinates
    if (lat >= 16.0 && lat <= 32.5 && lng >= 34.5 && lng <= 55.5) {
      // Exclude Egypt / Red Sea west of lng 34.8
      if (lng < 35.0 && lat < 28.0) return false;
      return true;
    }
    return false;
  }

  /// Reverse geocodes coordinates to get primary title and full address in Arabic
  Future<({String title, String fullAddress, bool isCovered})> reverseGeocode(double lat, double lng) async {
    final token = Secrets.mapboxAccessToken;
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$token&language=ar&limit=1',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          final first = features[0] as Map<String, dynamic>;
          final text = first['text'] as String? ?? '';
          final placeName = first['place_name'] as String? ?? '';
          final context = first['context'] as List<dynamic>? ?? [];

          String? countryCode;
          for (final item in context) {
            final id = item['id'] as String? ?? '';
            if (id.startsWith('country')) {
              countryCode = item['short_code'] as String?;
            }
          }

          final covered = isLocationCovered(lat, lng, countryCode: countryCode, fullAddress: placeName);
          final title = text.isNotEmpty ? text : (placeName.split(',').first.trim());
          return (
            title: title.isNotEmpty ? title : 'الموقع المحدد',
            fullAddress: placeName.isNotEmpty ? placeName : 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
            isCovered: covered,
          );
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding with Mapbox: $e');
    }

    // Fallback to OpenStreetMap Nominatim in Arabic
    try {
      final fallbackUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ar',
      );
      final response = await http.get(fallbackUrl, headers: {'User-Agent': 'MoreApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String? ?? '';
        final addressMap = data['address'] as Map<String, dynamic>? ?? {};
        final countryCode = addressMap['country_code'] as String?;
        final suburb = addressMap['suburb'] ?? addressMap['neighbourhood'] ?? addressMap['road'] ?? addressMap['city'];

        final covered = isLocationCovered(lat, lng, countryCode: countryCode, fullAddress: displayName);
        return (
          title: (suburb as String?)?.isNotEmpty == true ? suburb! : (displayName.split(',').first.trim()),
          fullAddress: displayName,
          isCovered: covered,
        );
      }
    } catch (e) {
      debugPrint('Fallback reverse geocoding error: $e');
    }

    final covered = isLocationCovered(lat, lng);
    return (
      title: 'الموقع المحدد',
      fullAddress: 'الإحداثيات: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      isCovered: covered,
    );
  }

  /// Searches for places matching a query in Arabic
  Future<List<Map<String, dynamic>>> searchPlaces(String query, {double? userLat, double? userLng}) async {
    if (query.trim().isEmpty) return [];

    final token = Secrets.mapboxAccessToken;
    final encoded = Uri.encodeComponent(query.trim());
    final proximity = (userLat != null && userLng != null) ? '&proximity=$userLng,$userLat' : '';
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json?access_token=$token&language=ar&limit=10$proximity',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];
        return features.map((f) {
          final text = f['text'] as String? ?? '';
          final placeName = f['place_name'] as String? ?? '';
          final center = f['center'] as List<dynamic>? ?? [0, 0];
          final lng = (center[0] as num).toDouble();
          final lat = (center[1] as num).toDouble();

          return {
            'title': text.isNotEmpty ? text : placeName.split(',').first.trim(),
            'fullAddress': placeName,
            'latitude': lat,
            'longitude': lng,
            'isCovered': isLocationCovered(lat, lng, fullAddress: placeName),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    }

    return [];
  }
}
