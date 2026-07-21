import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../../../../config/secrets.dart';
import '../../../explore/services/explore_data_service.dart';

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

  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _selectedLocationForPreview;

  bool _isLoading = true;
  bool _isSearching = false;
  double _latitude = 29.378033; // Default Fayoum coordinates
  double _longitude = 30.697478;
  List<Map<String, dynamic>> _nearbyLocations = [];
  List<Map<String, dynamic>> _filteredLocations = [];
  String _searchQuery = '';
  Timer? _debounce;
  String? _apiErrorMessage;




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



  Future<void> _fetchNearby(double lat, double lng) async {
    setState(() {
      _isLoading = true;
      _apiErrorMessage = null;
    });

    final List<Map<String, dynamic>> places = [];

    try {
      final initialPlaces = await ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng, radius: 3000);
      for (final p in initialPlaces) {
        places.add({
          'placeId': p['id'],
          'name': p['name'],
          'address': p['address'],
          'latitude': p['latitude'],
          'longitude': p['longitude'],
          'distance': p['distance'],
          'icon': _getIconForTypes([p['type'].toLowerCase()]),
        });
      }
    } catch (e) {
      debugPrint("Error fetching nearby places from ExploreDataService: $e");
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
      final results = await ExploreDataService.searchFoursquarePlaces(query, _latitude, _longitude);
      for (final p in results) {
        places.add({
          'placeId': p['id'],
          'name': p['name'],
          'address': p['address'],
          'latitude': p['latitude'],
          'longitude': p['longitude'],
          'distance': p['distance'],
          'icon': _getIconForTypes([p['type'].toLowerCase()]),
        });
      }
    } catch (e) {
      debugPrint("Error performing search from ExploreDataService: $e");
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


  @override  Widget build(BuildContext context) {
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F242E);
    final Color hintColor = isDark ? Colors.white54 : const Color(0xFF82858C);
    final Color dragHandleColor = isDark ? const Color(0xFF323A4E) : Colors.grey[300]!;
    final Color fieldColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF3F4F6);

    if (_selectedLocationForPreview != null) {
      final name = _selectedLocationForPreview!['name'] as String;
      final lat = _selectedLocationForPreview!['latitude'] as double;
      final lng = _selectedLocationForPreview!['longitude'] as double;
      
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: keyboardPadding),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: dragHandleColor,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLocationForPreview = null;
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF82858C),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Map preview',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF1F242E),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your content will show up here',
                style: GoogleFonts.ibmPlexSansArabic(
                  color: const Color(0xFF82858C),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF1F242E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        _SearchMiniMapPreview(
                          lat: lat,
                          lng: lng,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        ),
                        const Center(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedLocationForPreview);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add',
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: dragHandleColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.near_me,
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Locations',
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Choose a location to tag',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'People you share this content with can see the location you tag and view this content on the map.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: hintColor,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: hintColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            color: hintColor,
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(
                            color: Color(0xFF7C57FC),
                            radius: 12,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Finding nearby places...',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              color: Color(0xFF82858C),
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
                                          color: Color(0xFF82858C),
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
                                      final isSelected = _selectedLocation != null &&
                                          _selectedLocation!['placeId'] == loc['placeId'];
                                      return ListTile(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          setState(() {
                                            _selectedLocation = loc;
                                          });
                                        },
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: fieldColor,
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
                                            color: textColor,
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
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Color(0xFF7C57FC),
                                                size: 20,
                                              )
                                            : const Icon(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedLocation == null
                      ? null
                      : () {
                          setState(() {
                            _selectedLocationForPreview = _selectedLocation;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    disabledBackgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add location',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: _selectedLocation == null ? const Color(0xFF9CA3AF) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMiniMapPreview extends StatefulWidget {
  final double lat;
  final double lng;
  final bool isDark;

  const _SearchMiniMapPreview({
    required this.lat,
    required this.lng,
    required this.isDark,
  });

  @override
  State<_SearchMiniMapPreview> createState() => _SearchMiniMapPreviewState();
}

class _SearchMiniMapPreviewState extends State<_SearchMiniMapPreview> {
  mapbox.MapboxMap? _mapController;
  bool? _lastIsDark;

  @override
  Widget build(BuildContext context) {
    if (_lastIsDark != null && _lastIsDark != widget.isDark) {
      _lastIsDark = widget.isDark;
      if (_mapController != null) {
        final newStyle = widget.isDark
            ? "mapbox://styles/mapbox/navigation-guidance-night-v4"
            : "mapbox://styles/mapbox/streets-v12";
        _mapController!.style.setStyleURI(newStyle);
      }
    } else {
      _lastIsDark = widget.isDark;
    }

    return mapbox.MapWidget(
      key: const ValueKey('location_search_mini_map_key'),
      resourceOptions: mapbox.ResourceOptions(accessToken: const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken)),
      styleUri: widget.isDark
          ? "mapbox://styles/mapbox/navigation-guidance-night-v4"
          : "mapbox://styles/mapbox/streets-v12",
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(widget.lng, widget.lat)).toJson(),
        zoom: 15.0,
      ),
      onMapCreated: (controller) async {
        _mapController = controller;
        await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
        await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
      },
      onStyleLoadedListener: (styleLoaded) async {
        if (_mapController != null) {
          try {
            final layers = await _mapController!.style.getStyleLayers();
            const List<String> hideKeywords = [
              'poi', 'transit', 'rail', 'bus', 'station', 'ferry', 'shield', 'motorway',
              'number', 'crossing', 'traffic', 'landmark', 'symbol', 'monument', 'worship',
              'cemetery', 'lodging', 'hotel', 'restaurant', 'cafe', 'shop', 'food',
              'beverage', 'intersection', 'entrance', 'parking'
            ];
            for (final layerInfo in layers) {
              if (layerInfo != null) {
                final idLower = layerInfo.id.toLowerCase();
                if (idLower.contains('pointannotation') || idLower.contains('annotation')) {
                  continue;
                }
                bool shouldHide = false;
                for (final keyword in hideKeywords) {
                  if (idLower.contains(keyword)) {
                    shouldHide = true;
                    break;
                  }
                }
                if (shouldHide) {
                  await _mapController!.style.setStyleLayerProperty(
                    layerInfo.id,
                    'visibility',
                    'none',
                  );
                }
              }
            }
          } catch (_) {}
        }
      },
    );
  }
}
