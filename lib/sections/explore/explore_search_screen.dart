import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/explore_filter_sheet.dart';
import 'services/explore_data_service.dart';

class ExploreSearchScreen extends StatefulWidget {
  final double userLat;
  final double userLng;
  final List<Map<String, dynamic>> recentPlaces;
  final ValueChanged<Map<String, dynamic>> onRecentPlaceAdded;
  final Map<String, dynamic> filterState;
  final ValueChanged<Map<String, dynamic>> onFilterStateChanged;

  const ExploreSearchScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.recentPlaces,
    required this.onRecentPlaceAdded,
    required this.filterState,
    required this.onFilterStateChanged,
  });

  @override
  State<ExploreSearchScreen> createState() => _ExploreSearchScreenState();
}

class _ExploreSearchScreenState extends State<ExploreSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _isLoadingNearby = true;
  late Map<String, dynamic> _localFilterState;

  @override
  void initState() {
    super.initState();
    _localFilterState = Map<String, dynamic>.from(widget.filterState);
    _loadNearbyPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoadingNearby = true;
    });
    try {
      final places = await ExploreDataService.fetchNearbyFoursquarePlaces(
        widget.userLat,
        widget.userLng,
      );
      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNearby = false;
        });
      }
    }
  }

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ExploreDataService.searchFoursquarePlaces(
        query,
        widget.userLat,
        widget.userLng,
      );
      if (mounted && _searchQuery == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && _searchQuery == query) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // We need to map our localFilterState to ExploreFilterState or use dynamic representation
        // Let's import explore_filter_sheet to see how it's used
        return ExploreFilterSheet(
          initialState: FilterState(
            visited: _localFilterState['visited'] as bool? ?? false,
            saved: _localFilterState['saved'] as bool? ?? false,
            priceRange: _localFilterState['priceLevel'] == 'Any' ? null : _localFilterState['priceLevel'] as String?,
            minRating: (_localFilterState['ratingMin'] as num?)?.toDouble() ?? 0.0,
            openNow: _localFilterState['openNow'] as bool? ?? false,
          ),
          onApply: (newState) {
            final updated = {
              'visited': newState.visited,
              'saved': newState.saved,
              'priceLevel': newState.priceRange ?? 'Any',
              'ratingMin': newState.minRating ?? 0.0,
              'openNow': newState.openNow,
            };
            setState(() {
              _localFilterState = updated;
            });
            widget.onFilterStateChanged(updated);
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, String type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, {
          'type': 'category',
          'category': type,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF7C57FC)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceItem(Map<String, dynamic> place) {
    final String name = place['name'] as String? ?? '';
    final String distance = place['distance'] as String? ?? '';
    final String address = place['address'] as String? ?? '';
    
    // Parse area/city from address if possible, otherwise use address
    String subtitle = distance;
    if (address.isNotEmpty) {
      final parts = address.split(',');
      final area = parts.isNotEmpty ? parts.first.trim() : address;
      subtitle = "$distance • $area";
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.location_on,
          color: Color(0xFF7C57FC),
          size: 20,
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF82858C),
        ),
      ),
      onTap: () {
        widget.onRecentPlaceAdded(place);
        Navigator.pop(context, {
          'type': 'place',
          'place': place,
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header search area
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 12,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Search Bar
                Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF1A1A2E),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search input field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          autofocus: true,
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: "Find a place",
                            hintStyle: GoogleFonts.ibmPlexSansArabic(
                              color: const Color(0x9A1A1A2E),
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF82858C),
                              size: 20,
                            ),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF7C57FC),
                                        ),
                                      ),
                                    ),
                                  )
                                : (_searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          _onSearchChanged("");
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Color(0xFF82858C),
                                          size: 18,
                                        ),
                                      )
                                    : null),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter button
                    GestureDetector(
                      onTap: _openFilterBottomSheet,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.tune,
                          color: Color(0xFF82858C),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 12),
                  // Current Location button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, {
                        'type': 'current_location',
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.my_location,
                            color: Color(0xFF7C57FC),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Current Location",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Search content area
          Expanded(
            child: _searchQuery.isNotEmpty
                ? (_isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                        ),
                      )
                    : (_searchResults.isEmpty
                        ? Center(
                            child: Text(
                              "No places found",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return _buildPlaceItem(_searchResults[index]);
                            },
                          )))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Categories horizontal list
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildCategoryChip("Restaurant", Icons.restaurant, "Restaurant"),
                              _buildCategoryChip("Coffee", Icons.local_cafe, "Coffee"),
                              _buildCategoryChip("Bakery", Icons.breakfast_dining, "Bakery"),
                              _buildCategoryChip("Bars", Icons.local_bar, "Bars"),
                              _buildCategoryChip("Desserts", Icons.icecream, "Desserts"),
                            ],
                          ),
                        ),

                        // Nearby section
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Nearby",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingNearby)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                              ),
                            ),
                          )
                        else if (_nearbyPlaces.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No nearby places found",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _nearbyPlaces.length > 5 ? 5 : _nearbyPlaces.length,
                            itemBuilder: (context, index) {
                              return _buildPlaceItem(_nearbyPlaces[index]);
                            },
                          ),

                        // Recent section
                        if (widget.recentPlaces.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Recent",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: widget.recentPlaces.length,
                            itemBuilder: (context, index) {
                              return _buildPlaceItem(widget.recentPlaces[index]);
                            },
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
