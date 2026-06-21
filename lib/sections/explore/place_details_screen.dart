import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/explore_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/place_details_photos_section.dart';

import 'widgets/place_details_check_in_section.dart';
import 'widgets/place_details_rating_section.dart';
import 'widgets/place_details_tips_section.dart';
import 'widgets/place_details_similar_places_section.dart';
import '../timeline/widgets/check_in_composer_screen.dart';
import 'helpers/bookmark_tracker.dart';





class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback onActionTriggered;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.onActionTriggered,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late bool _isSaved;
  late List<String> _images;
  int _currentPage = 0;
  late List<Map<String, dynamic>> _visitors;
  bool _hasCheckedIn = false;
  int? _selectedRatingIndex; // 0: Sad, 1: Okay, 2: Happy
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _placePosts = [];
  List<String> _peopleImages = [];
  List<Map<String, dynamic>> _similarPlaces = [];

  @override
  void initState() {
    super.initState();
    _isSaved = widget.place['isSaved'] as bool? ?? false;
    _images = _getPlaceImages(
      widget.place['type']?.toString() ?? 'Other',
      widget.place['id']?.toString() ?? '',
    );
    final rawVisitors = widget.place['visitors'] as List?;
    _visitors = rawVisitors != null ? List<Map<String, dynamic>>.from(rawVisitors.map((v) => Map<String, dynamic>.from(v as Map))) : [];

    _loadPlacePosts();
    _loadSimilarPlaces();
  }

  Future<void> _loadPlacePosts() async {
    try {
      final client = Supabase.instance.client;
      final postsRes = await client
          .from('posts')
          .select('*, author:profiles(*)')
          .eq('place_id', widget.place['id'].toString())
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> postsList = List<Map<String, dynamic>>.from(postsRes as List);
      
      // Extract people images
      final List<String> imageUrls = [];
      for (final p in postsList) {
        final url = p['image_url'] as String?;
        if (url != null && url.isNotEmpty) {
          imageUrls.add(url);
        }
      }

      if (mounted) {
        setState(() {
          _placePosts = postsList;
          _peopleImages = imageUrls;
        });
      }
    } catch (e) {
      debugPrint("Error loading place posts: $e");
    }
  }

  Future<void> _loadSimilarPlaces() async {
    try {
      final double lat = (widget.place['latitude'] as num?)?.toDouble() ?? 29.378033;
      final double lng = (widget.place['longitude'] as num?)?.toDouble() ?? 30.697478;
      final String category = widget.place['type']?.toString() ?? '';

      final results = await ExploreDataService.fetchNearbyFoursquarePlaces(lat, lng);
      
      // Filter similar places by category (excluding current place and places without valid images)
      final List<Map<String, dynamic>> filtered = [];
      for (final p in results) {
        if (p['id'] == widget.place['id']) continue;

        final String rawUrl = p['imageUrl'] as String? ?? '';
        final bool hasRealImage = rawUrl.isNotEmpty && !rawUrl.contains('unsplash.com/photo-');
        if (!hasRealImage) continue;

        if (category.isNotEmpty && p['type'] == category) {
          filtered.add(p);
        }
      }

      // If we don't have enough similar places of the same category, add other nearby places with valid images
      if (filtered.length < 5) {
        for (final p in results) {
          if (p['id'] == widget.place['id']) continue;

          final String rawUrl = p['imageUrl'] as String? ?? '';
          final bool hasRealImage = rawUrl.isNotEmpty && !rawUrl.contains('unsplash.com/photo-');
          if (!hasRealImage) continue;

          if (!filtered.any((item) => item['id'] == p['id'])) {
            filtered.add(p);
          }
        }
      }

      if (mounted) {
        setState(() {
          _similarPlaces = filtered;
        });
      }
    } catch (e) {
      debugPrint("Error loading similar places: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getPlaceImages(String type, String id) {
    final List<dynamic>? placePhotos = widget.place['photos'] as List<dynamic>?;
    if (placePhotos != null && placePhotos.isNotEmpty) {
      return List<String>.from(placePhotos.where((img) => img != null && !img.toString().contains('unsplash.com/photo-')));
    }

    final String? defaultImg = widget.place['imageUrl']?.toString();
    if (defaultImg != null && defaultImg.isNotEmpty) {
      if (defaultImg.contains('googleapis.com') || (defaultImg.contains('unsplash.com') && !defaultImg.contains('unsplash.com/photo-') && !defaultImg.contains('placeholder_for_'))) {
        return [defaultImg];
      }
    }

    return [];
  }



  void _submitReview() {
    if (_selectedRatingIndex == null) return;
    String status = "";
    if (_selectedRatingIndex == 0) status = "Sad/Bad";
    if (_selectedRatingIndex == 1) status = "Okay";
    if (_selectedRatingIndex == 2) status = "Happy/Great";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم إرسال تقييمك ($status) بنجاح!",
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        backgroundColor: const Color(0xFF7C57FC),
      ),
    );
  }



  void _sharePlace() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم نسخ رابط المكان لمشاركته!",
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  void _performCheckIn() async {
    if (_hasCheckedIn) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(
          isFirstCheckIn: false,
          editPost: null,
          prefilledPlace: widget.place,
        ),
      ),
    );

    if (result == true && mounted) {
      String myName = "أنت";
      String? myAvatarUrl;
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          final profile = await client.from('profiles').select().eq('id', user.id).maybeSingle();
          if (profile != null) {
            final firstName = profile['first_name'] as String? ?? '';
            final lastName = profile['last_name'] as String? ?? '';
            myName = '$firstName $lastName'.trim();
            if (myName.isEmpty) myName = "أنت";
            myAvatarUrl = profile['avatar_url'] as String?;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user profile for check-in: $e");
      }

      setState(() {
        _hasCheckedIn = true;
        _visitors.insert(0, {
          'name': myName,
          'avatarUrl': myAvatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
        });
        
        final placeVisitors = widget.place['visitors'] as List?;
        if (placeVisitors != null) {
          widget.place['visitors'] = [
            {
              'name': myName,
              'avatarUrl': myAvatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
            },
            ...placeVisitors,
          ];
        } else {
          widget.place['visitors'] = [
            {
              'name': myName,
              'avatarUrl': myAvatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
            }
          ];
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "تم تسجيل تواجدك في المكان بنجاح!",
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          backgroundColor: const Color(0xFF7C57FC),
        ),
      );

      _loadPlacePosts();
      widget.onActionTriggered();
    }
  }

  void _showMoreInfoBottomSheet() {
    final place = widget.place;
    final double lat = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
    final double lng = (place['longitude'] as num?)?.toDouble() ?? 30.697478;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1C1C1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "More information",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F242E),
                ),
              ),
              const SizedBox(height: 20),
              _buildModalDetailRow(Icons.storefront_outlined, "Name", place['name']?.toString() ?? 'N/A'),
              const Divider(height: 24, color: Color(0xFFE8E8E8)),
              _buildModalDetailRow(Icons.category_outlined, "Category", place['type']?.toString() ?? 'Other'),
              const Divider(height: 24, color: Color(0xFFE8E8E8)),
              _buildModalDetailRow(Icons.location_on_outlined, "Address", place['address']?.toString() ?? 'Zagazig'),
              const Divider(height: 24, color: Color(0xFFE8E8E8)),
              _buildModalDetailRow(Icons.pin_drop_outlined, "Coordinates", "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}"),
              if (place['phone'] != null && place['phone'].toString().isNotEmpty) ...[
                const Divider(height: 24, color: Color(0xFFE8E8E8)),
                _buildModalDetailRow(Icons.phone_outlined, "Phone", place['phone'].toString()),
              ],
              if (place['website'] != null && place['website'].toString().isNotEmpty) ...[
                const Divider(height: 24, color: Color(0xFFE8E8E8)),
                _buildModalDetailRow(Icons.language_outlined, "Website", place['website'].toString(), isLink: true),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7C57FC), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: const Color(0xFF82858C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              isLink
                  ? GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(value);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        value,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF7C57FC),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: const Color(0xFF1F242E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF82858C),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildGreyPillButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F242E),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final place = widget.place;
    
    final ratingVal = place['rating'] as num? ?? 7.9;
    final reviewsCount = place['reviewsCount'] as int? ?? 36;
    final distanceStr = place['distance']?.toString() ?? '1.1 km';
    final double lat = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
    final double lng = (place['longitude'] as num?)?.toDouble() ?? 30.697478;
    final bool hasPhotos = _images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Swipable Hero Header Image Stack OR Placeholder
          Stack(
            children: [
              if (hasPhotos)
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    itemCount: _images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        _images[index],
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                )
              else
                // Premium header placeholder
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_camera_back_outlined,
                        color: Color(0xFF82858C),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No images available for this place",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                ),

              // Back button (dark circular card)
              Positioned(
                top: topPadding + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Three-dot action button (dark circular card)
              Positioned(
                top: topPadding + 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Image index indicator e.g. "1/18"
              if (hasPhotos)
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      "${_currentPage + 1}/${_images.length}",
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 2. Details Content Scroll View
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    place['name']?.toString() ?? 'Maxim Pizza & Restaurant',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Metadata Subtitle
                  Text(
                    "${place['type'] ?? 'Pizzeria'} • ${place['address'] ?? 'Zagazig, Eastern'} • ${place['price'] ?? '\$\$'} • $distanceStr",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF82858C),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Overall Rating Row
                  Row(
                    children: [
                      const Icon(
                        Icons.sentiment_satisfied_alt,
                        color: Color(0xFF1F242E),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$ratingVal",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F242E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "($reviewsCount)",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Photos Section
                  PlacePhotosSection(images: _images, peopleImages: _peopleImages),
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    "About",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // About Items List
                  _buildInfoRow(
                    icon: Icons.access_time,
                    child: Row(
                      children: [
                        _buildGreyPillButton("Add hours", () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "تم فتح شاشة تعديل أوقات العمل",
                                style: GoogleFonts.ibmPlexSansArabic(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (place['phone'] != null && place['phone'].toString().isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.phone,
                      child: Text(
                        place['phone'].toString(),
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          color: const Color(0xFF1F242E),
                        ),
                      ),
                    ),
                  if (place['website'] != null && place['website'].toString().isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.language,
                      child: GestureDetector(
                        onTap: () async {
                          final url = place['website'].toString();
                          final uri = Uri.tryParse(url);
                          if (uri != null) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          place['website'].toString(),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            color: const Color(0xFF7C57FC),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['address']?.toString().isNotEmpty == true
                              ? place['address'].toString()
                              : (place['name']?.toString() ?? 'Zagazig'),
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            color: const Color(0xFF1F242E),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Real Google Maps Preview Container
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(lat, lng),
                                zoom: 15.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('place_location_marker'),
                                  position: LatLng(lat, lng),
                                ),
                              },
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Suggest edit
                        Row(
                          children: [
                            const Icon(Icons.edit, color: Color(0xFF82858C), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Suggest an edit",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF1F242E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // See more info
                  GestureDetector(
                    onTap: _showMoreInfoBottomSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "See more information",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F242E),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF82858C)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),
                  PlaceDetailsCheckInSection(
                    visitors: _visitors,
                    hasCheckedIn: _hasCheckedIn,
                    onCheckInTap: _performCheckIn,
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),

                  PlaceRatingSection(
                    ratingVal: "$ratingVal",
                    reviewsCount: "$reviewsCount",
                    onRatingSubmitted: (ratingIndex) {
                      setState(() {
                        _selectedRatingIndex = ratingIndex;
                      });
                      _submitReview();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Real Place Posts Section
                  PlaceTipsSection(placePosts: _placePosts),
                  const SizedBox(height: 24),

                  // Insights section
                  Text(
                    "Insights",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F242E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Insights Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Check-ins",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 12,
                                  color: const Color(0xFF82858C),
                                ),
                              ),
                              Text(
                                "${_visitors.length}",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F242E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tips",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 12,
                                  color: const Color(0xFF82858C),
                                ),
                              ),
                              Text(
                                "${_placePosts.length}",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F242E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Real Similar Places Section
                  PlaceSimilarPlacesSection(
                    similarPlaces: _similarPlaces,
                    onActionTriggered: widget.onActionTriggered,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Floating persistent Bottom Actions Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding > 0 ? bottomPadding + 6 : 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE8E8E8), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Check In button
                GestureDetector(
                  onTap: _performCheckIn,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _hasCheckedIn ? const Color(0xFFEDE6FC) : const Color(0xFF7C57FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _hasCheckedIn ? const Color(0xFF7C57FC) : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasCheckedIn ? "Checked In" : "Check In",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasCheckedIn ? const Color(0xFF7C57FC) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Row 2: Save and Share side-by-side
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSaved = !_isSaved;
                            place['isSaved'] = _isSaved;
                          });
                          BookmarkTracker().setBookmarked(widget.place, _isSaved);
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isSaved ? const Color(0xFFEDE6FC) : const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: _isSaved ? const Color(0xFF7C57FC) : const Color(0xFF1F242E),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Save",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isSaved ? const Color(0xFF7C57FC) : const Color(0xFF1F242E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _sharePlace,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.share,
                                color: Color(0xFF1F242E),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Share",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F242E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


