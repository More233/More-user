import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/secrets.dart';
import '../models/delivery_address_model.dart';
import '../models/delivery_region_model.dart';
import '../models/delivery_banner_model.dart';

class DeliveryAddressService {
  static final DeliveryAddressService instance = DeliveryAddressService._internal();
  DeliveryAddressService._internal();

  static const String _storageKey = 'saved_delivery_address';
  static const String _savedListKey = 'saved_delivery_addresses_list';
  final ValueNotifier<DeliveryAddressModel?> currentAddress = ValueNotifier<DeliveryAddressModel?>(null);
  final ValueNotifier<List<DeliveryAddressModel>> savedAddresses = ValueNotifier<List<DeliveryAddressModel>>([]);
  final ValueNotifier<List<DeliveryRegionModel>> activeRegions = ValueNotifier<List<DeliveryRegionModel>>([]);
  final ValueNotifier<List<DeliveryBannerModel>> currentBanners = ValueNotifier<List<DeliveryBannerModel>>([]);
  final ValueNotifier<bool> isLoadingBanners = ValueNotifier<bool>(false);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        currentAddress.value = DeliveryAddressModel.fromJson(jsonStr);
      }
      final listJson = prefs.getStringList(_savedListKey);
      if (listJson != null && listJson.isNotEmpty) {
        savedAddresses.value = listJson
            .map((s) => DeliveryAddressModel.fromJson(s))
            .toList();
      } else if (currentAddress.value != null) {
        savedAddresses.value = [currentAddress.value!];
      }
    } catch (e) {
      debugPrint('Error loading saved delivery address: $e');
    }

    // Fetch regions from Supabase and check current coverage
    await fetchActiveRegions();

    if (currentAddress.value != null) {
      final addr = currentAddress.value!;
      final region = findCoveredRegion(addr.latitude, addr.longitude);
      final isNowCovered = region != null;

      if (isNowCovered != addr.isCovered || region?.id != addr.regionId) {
        final updated = DeliveryAddressModel(
          title: addr.title,
          fullAddress: addr.fullAddress,
          details: addr.details,
          latitude: addr.latitude,
          longitude: addr.longitude,
          isCovered: isNowCovered,
          regionId: region?.id,
          regionName: region?.name,
        );
        saveAddress(updated);
      }

      await loadBannersForRegion(region?.id);
    } else {
      // Load default banners for first available active region
      if (activeRegions.value.isNotEmpty) {
        await loadBannersForRegion(activeRegions.value.first.id);
      }
    }
  }

  /// Fetches all active delivery regions registered in Supabase Dashboard
  Future<List<DeliveryRegionModel>> fetchActiveRegions() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('delivery_regions')
          .select()
          .eq('is_active', true)
          .order('name');

      final list = (res as List)
          .map((m) => DeliveryRegionModel.fromMap(m as Map<String, dynamic>))
          .toList();

      activeRegions.value = list;
      return list;
    } catch (e) {
      debugPrint('Error fetching delivery regions: $e');
      return [];
    }
  }

  /// Calculates Haversine distance in kilometers between two lat/lng coordinates
  static double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Checks if given coordinates fall inside any registered active region
  DeliveryRegionModel? findCoveredRegion(double lat, double lng) {
    final regions = activeRegions.value;
    for (final reg in regions) {
      final dist = calculateDistanceInKm(lat, lng, reg.latitude, reg.longitude);
      if (dist <= reg.radiusKm) {
        return reg;
      }
    }
    return null;
  }

  /// Loads promotional banners for a specific region from Supabase
  Future<void> loadBannersForRegion(String? regionId) async {
    isLoadingBanners.value = true;
    try {
      final client = Supabase.instance.client;
      var query = client.from('delivery_banners').select().eq('is_active', true);
      if (regionId != null && regionId.isNotEmpty) {
        query = query.eq('region_id', regionId);
      }
      final res = await query.order('sort_order', ascending: true);

      final list = (res as List)
          .map((m) => DeliveryBannerModel.fromMap(m as Map<String, dynamic>))
          .toList();

      currentBanners.value = list;
    } catch (e) {
      debugPrint('Error loading banners from Supabase: $e');
    } finally {
      isLoadingBanners.value = false;
    }
  }

  Future<void> saveAddress(DeliveryAddressModel address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, address.toJson());
      currentAddress.value = address;

      // Update saved list (avoid duplicates by lat/lng or fullAddress)
      final list = List<DeliveryAddressModel>.from(savedAddresses.value);
      final existingIndex = list.indexWhere((a) =>
          (a.latitude - address.latitude).abs() < 0.0001 &&
          (a.longitude - address.longitude).abs() < 0.0001);
      if (existingIndex >= 0) {
        list[existingIndex] = address;
      } else {
        list.insert(0, address);
      }
      savedAddresses.value = list;
      await prefs.setStringList(
        _savedListKey,
        list.map((a) => a.toJson()).toList(),
      );

      if (address.regionId != null) {
        loadBannersForRegion(address.regionId);
      }
    } catch (e) {
      debugPrint('Error saving delivery address: $e');
    }
  }

  Future<void> removeSavedAddress(int index) async {
    try {
      final list = List<DeliveryAddressModel>.from(savedAddresses.value);
      if (index >= 0 && index < list.length) {
        final removed = list.removeAt(index);
        savedAddresses.value = list;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _savedListKey,
          list.map((a) => a.toJson()).toList(),
        );
        if (currentAddress.value?.fullAddress == removed.fullAddress) {
          if (list.isNotEmpty) {
            await saveAddress(list.first);
          } else {
            await clearAddress();
          }
        }
      }
    } catch (e) {
      debugPrint('Error removing saved address: $e');
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

  /// Reverse geocodes coordinates to get primary title, full address, and coverage status
  Future<({String title, String fullAddress, bool isCovered, DeliveryRegionModel? region})> reverseGeocode(
      double lat, double lng) async {
    // 1. Dynamic coverage check against regions from Supabase
    if (activeRegions.value.isEmpty) {
      await fetchActiveRegions();
    }
    final matchedRegion = findCoveredRegion(lat, lng);
    final isCovered = matchedRegion != null;

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

          final title = text.isNotEmpty ? text : (placeName.split(',').first.trim());
          return (
            title: title.isNotEmpty ? title : (matchedRegion?.name ?? 'الموقع المحدد'),
            fullAddress: placeName.isNotEmpty ? placeName : 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
            isCovered: isCovered,
            region: matchedRegion,
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
        final suburb = addressMap['suburb'] ?? addressMap['neighbourhood'] ?? addressMap['road'] ?? addressMap['city'];

        return (
          title: (suburb as String?)?.isNotEmpty == true
              ? suburb!
              : (matchedRegion?.name ?? displayName.split(',').first.trim()),
          fullAddress: displayName,
          isCovered: isCovered,
          region: matchedRegion,
        );
      }
    } catch (e) {
      debugPrint('Fallback reverse geocoding error: $e');
    }

    return (
      title: matchedRegion?.name ?? 'الموقع المحدد',
      fullAddress: 'الإحداثيات: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      isCovered: isCovered,
      region: matchedRegion,
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
          final center = f['center'] as List<dynamic>? ?? [0.0, 0.0];
          final lng = (center[0] as num).toDouble();
          final lat = (center[1] as num).toDouble();
          final reg = findCoveredRegion(lat, lng);

          return {
            'title': text.isNotEmpty ? text : placeName,
            'fullAddress': placeName,
            'latitude': lat,
            'longitude': lng,
            'isCovered': reg != null,
            'region': reg,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error searching places with Mapbox: $e');
    }
    return [];
  }
}
