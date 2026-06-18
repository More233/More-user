import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationSearchSheet extends StatefulWidget {
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

  static const String foursquareClientId = 'VIUPG0BG3P204YTVQM3BEIRZRHIWVOA3SSLFNCV0CWA43GOA';
  static const String foursquareClientSecret = '0G2ZE1O4HWOD2B5IBX4ON4T4JJECCE5KXECWPTZ3QPQ1QLTZ';

  static const List<Map<String, dynamic>> _locations = [
    {
      'name': 'Helnan Auberge El Fayoum Hotel',
      'address': 'Muhafazat al Fayyūm, Egypt',
      'latitude': 29.378033,
      'longitude': 30.697478,
      'distance': '0 km',
      'icon': Icons.business,
    },
    {
      'name': 'منطقة تجنيد وتعبئة الزقازيق',
      'address': 'Al-Sharkia, Egypt',
      'latitude': 30.587681,
      'longitude': 31.482811,
      'distance': '14 km',
      'icon': Icons.check_circle_outline,
    },
    {
      'name': 'الزقازيق',
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
      'name': 'مستشفى الأحرار',
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
      'name': 'كوبرى بردين',
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
      'name': 'مقر الإخوان المسلمين بمدينة بلبيس',
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
      'name': 'جامع سادات قريش',
      'address': 'Belbeis, Al-Sharkia, Egypt',
      'latitude': 30.417234,
      'longitude': 31.566123,
      'distance': '6.1 km',
      'icon': Icons.location_on_outlined,
    },
  ];

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

  IconData _mapFoursquareCategoryToIconData(List<dynamic> categories) {
    if (categories.isEmpty) return Icons.location_on_outlined;
    final primary = categories.first;
    final String name = (primary['name'] as String? ?? '').toLowerCase();

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
      return Icons.restaurant;
    }
    if (name.contains('coffee') ||
        name.contains('cafe') ||
        name.contains('espresso') ||
        name.contains('tea room') ||
        name.contains('coffe')) {
      return Icons.local_cafe;
    }
    if (name.contains('bakery') ||
        name.contains('donut') ||
        name.contains('pastry') ||
        name.contains('dessert') ||
        name.contains('cake') ||
        name.contains('sweet')) {
      return Icons.bakery_dining;
    }
    if (name.contains('bar') ||
        name.contains('pub') ||
        name.contains('nightclub') ||
        name.contains('lounge') ||
        name.contains('brewery') ||
        name.contains('distillery')) {
      return Icons.local_bar;
    }
    if (name.contains('supermarket') ||
        name.contains('grocery') ||
        name.contains('market') ||
        name.contains('convenience') ||
        name.contains('mart')) {
      return Icons.storefront;
    }
    if (name.contains('pharmacy') ||
        name.contains('drugstore') ||
        name.contains('chemist') ||
        name.contains('hospital') ||
        name.contains('clinic')) {
      return Icons.local_pharmacy;
    }
    if (name.contains('hotel') ||
        name.contains('motel') ||
        name.contains('hostel') ||
        name.contains('resort') ||
        name.contains('lodging') ||
        name.contains('inn')) {
      return Icons.hotel;
    }
    if (name.contains('park') ||
        name.contains('garden') ||
        name.contains('playground') ||
        name.contains('nature reserve')) {
      return Icons.park;
    }
    if (name.contains('airport') || name.contains('terminal')) {
      return Icons.local_airport;
    }

    final int id = primary['categoryCode'] as int? ??
        (primary['id'] is int ? primary['id'] as int : 0);

    if (id >= 13000 && id < 14000) {
      return Icons.restaurant;
    }
    if (id >= 16000 && id < 17000) {
      return Icons.park;
    }
    if (id == 19009 || id == 19010) {
      return Icons.local_airport;
    }
    if (id >= 19014 && id <= 19027) {
      return Icons.hotel;
    }
    if (id == 17069 || id == 17070) {
      return Icons.shopping_bag;
    }
    if (id == 11134) {
      return Icons.local_hospital;
    }
    return Icons.location_on_outlined;
  }

  Future<void> _fetchNearby(double lat, double lng) async {
    setState(() {
      _isLoading = true;
      _apiErrorMessage = null;
    });

    try {
      final String url = 'https://api.foursquare.com/v2/venues/explore'
          '?ll=$lat,$lng'
          '&radius=3000'
          '&limit=20'
          '&client_id=$foursquareClientId'
          '&client_secret=$foursquareClientSecret'
          '&v=20231010';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseObj = data['response'] as Map<String, dynamic>?;
        final groups = responseObj?['groups'] as List<dynamic>? ?? [];
        if (groups.isNotEmpty) {
          final firstGroup = groups.first as Map<String, dynamic>;
          final items = firstGroup['items'] as List<dynamic>? ?? [];
          final List<Map<String, dynamic>> places = [];
          for (final item in items) {
            final venue = item['venue'] as Map<String, dynamic>?;
            if (venue == null) continue;

            final id = venue['id'] as String? ?? '';
            final name = venue['name'] as String? ?? '';
            final location = venue['location'] as Map<String, dynamic>?;
            final address = location?['address'] as String? ??
                (location?['formattedAddress'] as List<dynamic>?)?.join(', ') ?? '';
            final plat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
            final plng = (location?['lng'] as num?)?.toDouble() ?? 0.0;
            final categories = venue['categories'] as List<dynamic>? ?? [];

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
              'icon': _mapFoursquareCategoryToIconData(categories),
            });
          }
          setState(() {
            _nearbyLocations = places;
            _filteredLocations = places;
          });
        } else {
          _apiErrorMessage = "Could not parse Foursquare places.";
          _loadFallbackLocations();
        }
      } else {
        _apiErrorMessage = "Foursquare API failed with status ${response.statusCode}";
        _loadFallbackLocations();
      }
    } catch (e) {
      debugPrint("Error fetching nearby Foursquare places: $e");
      _apiErrorMessage = "Error: $e";
      _loadFallbackLocations();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _loadFallbackLocations() {
    final List<Map<String, dynamic>> fallback = [];
    for (final loc in _locations) {
      final plat = loc['latitude'] as double;
      final plng = loc['longitude'] as double;
      final double meters = Geolocator.distanceBetween(_latitude, _longitude, plat, plng);
      final double km = meters / 1000;
      final String distanceStr = km < 1
          ? '${meters.toStringAsFixed(0)} m'
          : '${km.toStringAsFixed(1)} km';

      fallback.add({
        'name': loc['name'],
        'address': loc['address'],
        'latitude': plat,
        'longitude': plng,
        'distance': distanceStr,
        'icon': loc['icon'],
      });
    }
    setState(() {
      _nearbyLocations = fallback;
      _filteredLocations = fallback;
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

    try {
      final String url = 'https://api.foursquare.com/v2/venues/explore'
          '?query=${Uri.encodeComponent(query)}'
          '&ll=$_latitude,$_longitude'
          '&radius=50000'
          '&limit=20'
          '&client_id=$foursquareClientId'
          '&client_secret=$foursquareClientSecret'
          '&v=20231010';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseObj = data['response'] as Map<String, dynamic>?;
        final groups = responseObj?['groups'] as List<dynamic>? ?? [];
        if (groups.isNotEmpty) {
          final firstGroup = groups.first as Map<String, dynamic>;
          final items = firstGroup['items'] as List<dynamic>? ?? [];
          final List<Map<String, dynamic>> places = [];
          for (final item in items) {
            final venue = item['venue'] as Map<String, dynamic>?;
            if (venue == null) continue;

            final id = venue['id'] as String? ?? '';
            final name = venue['name'] as String? ?? '';
            final location = venue['location'] as Map<String, dynamic>?;
            final address = location?['address'] as String? ??
                (location?['formattedAddress'] as List<dynamic>?)?.join(', ') ?? '';
            final plat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
            final plng = (location?['lng'] as num?)?.toDouble() ?? 0.0;
            final categories = venue['categories'] as List<dynamic>? ?? [];

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
              'icon': _mapFoursquareCategoryToIconData(categories),
            });
          }
          setState(() {
            _filteredLocations = places;
          });
        }
      } else {
        setState(() {
          _filteredLocations = [];
          _apiErrorMessage = "Search failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      debugPrint("Error performing Foursquare search: $e");
      setState(() {
        _filteredLocations = [];
        _apiErrorMessage = "Error: $e";
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _showAddCustomPlaceDialog() {
    final TextEditingController nameController = TextEditingController();
    String selectedCategory = 'Restaurant';
    final categories = ['Restaurant', 'Coffee', 'Hotel', 'Park', 'Supermarket', 'Bakery', 'Other'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'إضافة مكان مخصص',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.right,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'اسم المكان',
                      hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          selectedCategory = val;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'التصنيف',
                      labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    try {
                      final client = Supabase.instance.client;
                      final response = await client.from('custom_venues').insert({
                        'name': name,
                        'address': 'موقع مخصص',
                        'latitude': _latitude,
                        'longitude': _longitude,
                        'category_name': selectedCategory,
                        'created_by': client.auth.currentUser?.id,
                      }).select().single();

                      final loc = {
                        'placeId': response['id'] as String,
                        'name': response['name'] as String,
                        'address': response['address'] as String,
                        'latitude': (response['latitude'] as num).toDouble(),
                        'longitude': (response['longitude'] as num).toDouble(),
                        'distance': '0 m',
                        'icon': _getIconForTypes([selectedCategory.toLowerCase()]),
                      };

                      if (dialogContext.mounted && mounted) {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context, loc); // Return selected place to composer
                      }
                    } catch (e) {
                      debugPrint("Error creating custom venue: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to save custom place: $e")),
                        );
                      }
                    }
                  },
                  child: Text(
                    'حفظ',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                                ? ListView(
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          _showAddCustomPlaceDialog();
                                        },
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEDE6FC),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Color(0xFF7C57FC),
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          'أضف مكاناً مخصصاً...',
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF7C57FC),
                                          ),
                                        ),
                                        subtitle: Text(
                                          'إذا لم تجد المكان في نتائج البحث',
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontSize: 14,
                                            color: const Color(0xFF82858C),
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                      Center(
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
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    itemCount: _filteredLocations.length + 1,
                                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    separatorBuilder: (context, index) => const Divider(
                                      height: 1,
                                      indent: 64,
                                      color: Color(0xFFF3F4F6),
                                    ),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return ListTile(
                                          onTap: () {
                                            _showAddCustomPlaceDialog();
                                          },
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEDE6FC),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Color(0xFF7C57FC),
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            'أضف مكاناً مخصصاً...',
                                            style: GoogleFonts.ibmPlexSansArabic(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF7C57FC),
                                            ),
                                          ),
                                          subtitle: Text(
                                            'إذا لم تجد المكان في نتائج البحث',
                                            style: GoogleFonts.ibmPlexSansArabic(
                                              fontSize: 14,
                                              color: const Color(0xFF82858C),
                                            ),
                                          ),
                                        );
                                      }
                                      final loc = _filteredLocations[index - 1];
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
