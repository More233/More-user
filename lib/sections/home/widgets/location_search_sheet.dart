import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationSearchSheet extends StatefulWidget {
  static const List<Map<String, dynamic>> locations = [
    {
      'name': 'Helnan Auberge El Fayoum Hotel',
      'address': 'Muhafazat al Fayyūm, Egypt',
      'latitude': 29.378033,
      'longitude': 30.697478,
      'distance': '0 km',
      'icon': Icons.business,
    },
    {
      'name': 'Zagazig Recruitment and Mobilization Area',
      'address': 'Al-Sharkia, Egypt',
      'latitude': 30.587681,
      'longitude': 31.482811,
      'distance': '14 km',
      'icon': Icons.check_circle_outline,
    },
    {
      'name': 'Zagazig',
      'address': 'Al-Sharkia, Egypt',
      'latitude': 30.587123,
      'longitude': 31.502025,
      'distance': '14 km',
      'icon': Icons.location_on_outlined,
    },
    {
      'name': 'El Sharqia Governorate',
      'address': 'Al-Sharkia, Egypt',
      'latitude': 30.732664,
      'longitude': 31.714418,
      'distance': '15 km',
      'icon': Icons.business_outlined,
    },
    {
      'name': 'Al-Ahrar Hospital',
      'address': 'Zagazig, Al-Sharkia, Egypt',
      'latitude': 30.573215,
      'longitude': 31.481235,
      'distance': '13 km',
      'icon': Icons.add_box_outlined,
    },
    {
      'name': 'El Sharqia Traffic Authority',
      'address': 'Zagazig, Al-Sharkia, Egypt',
      'latitude': 30.582312,
      'longitude': 31.492145,
      'distance': '15 km',
      'icon': Icons.business_outlined,
    },
    {
      'name': 'Belbeis Air Base',
      'address': 'Zagazig Cairo Road, Belbeis, Egypt',
      'latitude': 30.380252,
      'longitude': 31.579482,
      'distance': '6.9 km',
      'icon': Icons.business_outlined,
    },
    {
      'name': 'Belbeis Toll Booth',
      'address': 'Belbeis, Al-Sharkia, Egypt',
      'latitude': 30.410145,
      'longitude': 31.564571,
      'distance': '11 km',
      'icon': Icons.location_on_outlined,
    },
    {
      'name': 'Bordein Bridge',
      'address': 'Bordein, Al-Sharkia, Egypt',
      'latitude': 30.498124,
      'longitude': 31.512345,
      'distance': '6.9 km',
      'icon': Icons.location_on_outlined,
    },
    {
      'name': 'Oraby Sq',
      'address': 'Zagazig, Al-Sharkia, Egypt',
      'latitude': 30.587123,
      'longitude': 31.501234,
      'distance': '15 km',
      'icon': Icons.location_on_outlined,
    },
    {
      'name': 'Muslim Brotherhood Headquarters in Belbeis',
      'address': 'Belbeis, Al-Sharkia, Egypt',
      'latitude': 30.418234,
      'longitude': 31.567123,
      'distance': '5.8 km',
      'icon': Icons.location_on_outlined,
    },
    {
      'name': 'Burden Bridge',
      'address': 'Bordein, Al-Sharkia, Egypt',
      'latitude': 30.498567,
      'longitude': 31.512987,
      'distance': '6.3 km',
      'icon': Icons.location_on_outlined,
    },
    {
      'name': 'Sadat Quraish Mosque',
      'address': 'Belbeis, Al-Sharkia, Egypt',
      'latitude': 30.417234,
      'longitude': 31.566123,
      'distance': '6.1 km',
      'icon': Icons.location_on_outlined,
    },
  ];

  const LocationSearchSheet({super.key});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  double _latitude = 29.378033; // Default Fayoum coordinates
  double _longitude = 30.697478;
  List<Map<String, dynamic>> _nearbyLocations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  String _searchQuery = '';
  Timer? _debounce;
  String? _apiErrorMessage;

  static const String googlePlacesApiKey = 'AIzaSyBjxRXgMKAxdj8WeeI2VYGEhBA8lxTR5Ug';

  @override
  void initState() {
    super.initState();
    _loadInitialPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  IconData _getIconForTypes(List<dynamic> types) {
    if (types.contains('restaurant') ||
        types.contains('food') ||
        types.contains('cafe') ||
        types.contains('bakery') ||
        types.contains('bar')) {
      return Icons.restaurant;
    }
    if (types.contains('lodging') || types.contains('hotel')) {
      return Icons.hotel;
    }
    if (types.contains('airport')) {
      return Icons.local_airport;
    }
    if (types.contains('hospital') || types.contains('doctor') || types.contains('health')) {
      return Icons.local_hospital;
    }
    if (types.contains('park') || types.contains('tourist_attraction')) {
      return Icons.park;
    }
    if (types.contains('store') ||
        types.contains('shopping_mall') ||
        types.contains('clothing_store')) {
      return Icons.shopping_bag;
    }
    if (types.contains('church') ||
        types.contains('mosque') ||
        types.contains('hindu_temple') ||
        types.contains('synagogue') ||
        types.contains('place_of_worship')) {
      return Icons.place_outlined;
    }
    return Icons.location_on_outlined;
  }

  Future<void> _loadInitialPlaces() async {
    setState(() {
      _isLoading = true;
    });

    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      debugPrint("Error getting user location: $e");
    }

    final double lat = position?.latitude ?? 29.378033;
    final double lng = position?.longitude ?? 30.697478;

    _latitude = lat;
    _longitude = lng;

    await _fetchNearby(lat, lng);
  }


  IconData _mapGooglePlaceTypesToIconData(List<dynamic> types) {
    if (types.isEmpty) return Icons.location_on_outlined;
    final typesLower = types.map((t) => (t as String).toLowerCase()).toList();

    if (typesLower.contains('cafe') || typesLower.contains('coffee') || typesLower.contains('tea_room')) {
      return Icons.local_cafe;
    }
    if (typesLower.contains('bakery') || typesLower.contains('patisserie') || typesLower.contains('dessert_shop') || typesLower.contains('cake_shop')) {
      return Icons.bakery_dining;
    }
    if (typesLower.contains('bar') || typesLower.contains('night_club') || typesLower.contains('pub') || typesLower.contains('brewery')) {
      return Icons.local_bar;
    }
    if (typesLower.contains('restaurant') || typesLower.contains('meal_takeaway') || typesLower.contains('meal_delivery') || typesLower.contains('food')) {
      return Icons.restaurant;
    }
    if (typesLower.contains('supermarket') || typesLower.contains('grocery_or_supermarket') || typesLower.contains('convenience_store') || typesLower.contains('department_store')) {
      return Icons.storefront;
    }
    if (typesLower.contains('pharmacy') || typesLower.contains('drugstore') || typesLower.contains('hospital') || typesLower.contains('doctor') || typesLower.contains('dentist')) {
      return Icons.local_pharmacy;
    }
    if (typesLower.contains('lodging') || typesLower.contains('hotel') || typesLower.contains('resort')) {
      return Icons.hotel;
    }
    if (typesLower.contains('park') || typesLower.contains('tourist_attraction') || typesLower.contains('museum') || typesLower.contains('zoo') || typesLower.contains('amusement_park')) {
      return Icons.park;
    }
    if (typesLower.contains('airport') || typesLower.contains('transit_station') || typesLower.contains('subway_station') || typesLower.contains('train_station') || typesLower.contains('bus_station')) {
      return Icons.local_airport;
    }
    return Icons.location_on_outlined;
  }

  Future<void> _fetchNearby(double lat, double lng) async {
    setState(() {
      _isLoading = true;
      _apiErrorMessage = null;
    });

    final List<Map<String, dynamic>> places = [];

    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=3000'
          '&language=en'
          '&key=$googlePlacesApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        for (final item in results) {
          final place = item as Map<String, dynamic>;
          final id = place['place_id'] as String? ?? '';
          final name = place['name'] as String? ?? '';
          final geometry = place['geometry'] as Map<String, dynamic>?;
          final locationObj = geometry?['location'] as Map<String, dynamic>?;
          final plat = (locationObj?['lat'] as num?)?.toDouble() ?? 0.0;
          final plng = (locationObj?['lng'] as num?)?.toDouble() ?? 0.0;
          final address = place['vicinity'] as String? ?? place['formatted_address'] as String? ?? '';
          final types = place['types'] as List<dynamic>? ?? [];

          final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
          final double km = meters / 1000;
          final String distanceStr = km < 1
              ? '${meters.toStringAsFixed(0)} m'
              : '${km.toStringAsFixed(1)} km';

          places.add({
            'placeId': id,
            'name': name,
            'address': address,
            'latitude': plat,
            'longitude': plng,
            'distance': distanceStr,
            'icon': _mapGooglePlaceTypesToIconData(types),
          });
        }
      } else {
        _apiErrorMessage = "Google Places API failed with status ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Error fetching nearby Google places: $e");
      _apiErrorMessage = "Error: $e";
    }

    // Load custom venues from Supabase
    try {
      final client = Supabase.instance.client;
      final double latMin = lat - 0.5;
      final double latMax = lat + 0.5;
      final double lngMin = lng - 0.5;
      final double lngMax = lng + 0.5;

      final venuesResponse = await client
          .from('custom_venues')
          .select('*')
          .gte('latitude', latMin)
          .lte('latitude', latMax)
          .gte('longitude', lngMin)
          .lte('longitude', lngMax);

      final venueResults = List<Map<String, dynamic>>.from(venuesResponse as List);
      for (final res in venueResults) {
        final id = res['id'] as String;
        if (places.any((p) => p['placeId'] == id)) continue;

        final plat = (res['latitude'] as num).toDouble();
        final plng = (res['longitude'] as num).toDouble();
        final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        places.add({
          'placeId': id,
          'name': res['name'] as String,
          'address': res['address'] as String,
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'icon': _getIconForTypes([(res['category_name'] as String? ?? 'Other').toLowerCase()]),
        });
      }
    } catch (e) {
      debugPrint("Error loading nearby custom venues: $e");
    }

    // If places is still empty, load hardcoded fallback locations
    if (places.isEmpty) {
      for (final loc in LocationSearchSheet.locations) {
        final plat = loc['latitude'] as double;
        final plng = loc['longitude'] as double;
        final double meters = Geolocator.distanceBetween(_latitude, _longitude, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1
            ? '${meters.toStringAsFixed(0)} m'
            : '${km.toStringAsFixed(1)} km';

        places.add({
          'placeId': 'tapped_${loc['name'].hashCode}',
          'name': loc['name'],
          'address': loc['address'],
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'icon': loc['icon'] as IconData,
        });
      }
    }

    setState(() {
      _nearbyLocations = places;
      _filteredLocations = places;
      _isLoading = false;
    });
  }



  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredLocations = _nearbyLocations;
        _apiErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _apiErrorMessage = null;
    });

    final List<Map<String, dynamic>> places = [];

    try {
      final String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&location=$_latitude,$_longitude'
          '&radius=50000'
          '&language=en'
          '&key=$googlePlacesApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        for (final item in results) {
          final place = item as Map<String, dynamic>;
          final id = place['place_id'] as String? ?? '';
          final name = place['name'] as String? ?? '';
          final geometry = place['geometry'] as Map<String, dynamic>?;
          final locationObj = geometry?['location'] as Map<String, dynamic>?;
          final plat = (locationObj?['lat'] as num?)?.toDouble() ?? 0.0;
          final plng = (locationObj?['lng'] as num?)?.toDouble() ?? 0.0;
          final address = place['formatted_address'] as String? ?? place['vicinity'] as String? ?? '';
          final types = place['types'] as List<dynamic>? ?? [];

          final double meters = Geolocator.distanceBetween(_latitude, _longitude, plat, plng);
          final double km = meters / 1000;
          final String distanceStr = km < 1
              ? '${meters.toStringAsFixed(0)} m'
              : '${km.toStringAsFixed(1)} km';

          places.add({
            'placeId': id,
            'name': name,
            'address': address,
            'latitude': plat,
            'longitude': plng,
            'distance': distanceStr,
            'icon': _mapGooglePlaceTypesToIconData(types),
          });
        }
      } else {
        _apiErrorMessage = "Google Places API failed with status ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Error performing Google search: $e");
      _apiErrorMessage = "Error: $e";
    }

    // Add Supabase custom venues matching search
    try {
      final client = Supabase.instance.client;
      final venuesResponse = await client
          .from('custom_venues')
          .select('*')
          .ilike('name', '%$query%')
          .limit(10);

      final venueResults = List<Map<String, dynamic>>.from(venuesResponse as List);
      for (final res in venueResults) {
        final id = res['id'] as String;
        if (places.any((p) => p['placeId'] == id)) continue;

        final plat = (res['latitude'] as num).toDouble();
        final plng = (res['longitude'] as num).toDouble();
        final double meters = Geolocator.distanceBetween(_latitude, _longitude, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        places.add({
          'placeId': id,
          'name': res['name'] as String,
          'address': res['address'] as String,
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'icon': _getIconForTypes([(res['category_name'] as String? ?? 'Other').toLowerCase()]),
        });
      }
    } catch (e) {
      debugPrint("Error searching custom venues in database: $e");
    }

    // Add local fallback locations matching search
    final lowerQuery = query.toLowerCase();
    for (final loc in LocationSearchSheet.locations) {
      final name = loc['name'] as String;
      final address = loc['address'] as String;
      if (name.toLowerCase().contains(lowerQuery) || address.toLowerCase().contains(lowerQuery)) {
        if (places.any((p) => p['name'] == name)) continue;

        final plat = loc['latitude'] as double;
        final plng = loc['longitude'] as double;
        final double meters = Geolocator.distanceBetween(_latitude, _longitude, plat, plng);
        final double km = meters / 1000;
        final String distanceStr = km < 1 
            ? '${meters.toStringAsFixed(0)} m' 
            : '${km.toStringAsFixed(1)} km';

        places.add({
          'placeId': 'tapped_${name.hashCode}',
          'name': name,
          'address': address,
          'latitude': plat,
          'longitude': plng,
          'distance': distanceStr,
          'icon': loc['icon'] as IconData,
        });
      }
    }

    setState(() {
      _filteredLocations = places;
      _isSearching = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Color(0xFF82858C),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                color: const Color(0xFF1F242E),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search for places',
                                hintStyle: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 15,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF82858C),
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: const Color(0xFF7C57FC),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF7C57FC),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Finding nearby places...',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              color: const Color(0xFF82858C),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        if (_apiErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _apiErrorMessage!,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        color: Colors.red[900],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_isSearching)
                          const LinearProgressIndicator(
                            color: Color(0xFF7C57FC),
                            backgroundColor: Color(0xFFF3F4F6),
                            minHeight: 2,
                          ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                            },
                            child: _filteredLocations.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        'No places found',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 16,
                                          color: const Color(0xFF82858C),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _filteredLocations.length,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    separatorBuilder: (context, index) => const Divider(
                                      height: 1,
                                      indent: 64,
                                      color: Color(0xFFF3F4F6),
                                    ),
                                    itemBuilder: (context, index) {
                                      final loc = _filteredLocations[index];
                                      return ListTile(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          Navigator.pop(context, loc);
                                        },
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF3F4F6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            loc['icon'] as IconData,
                                            color: const Color(0xFF7C57FC),
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          loc['name'] as String,
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F242E),
                                          ),
                                        ),
                                        subtitle: Text(
                                          loc['distance'] != '0 km' && loc['distance'] != '0 m'
                                              ? '${loc['distance']} • ${loc['address']}'
                                              : loc['address'] as String,
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontSize: 14,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.info_outline,
                                          color: Color(0xFF9CA3AF),
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
