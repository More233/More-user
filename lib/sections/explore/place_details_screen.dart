import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/place_details_state.dart';
import 'view_models/place_details_view_model.dart';
import 'widgets/place_details/place_details_photos_section.dart';
import 'widgets/place_details/place_details_check_in_section.dart';
import 'widgets/place_details/place_details_rating_section.dart';
import 'widgets/place_details/place_details_tips_section.dart';
import 'widgets/place_details/place_details_similar_places_section.dart';
import 'widgets/place_details/place_details_header.dart';
import 'widgets/place_details/place_details_info.dart';
import 'widgets/place_details/place_details_actions.dart';
import 'widgets/place_details/place_details_more_info_sheet.dart';
import '../home/widgets/feed/check_in_composer_screen.dart';
import 'services/explore_data_service.dart';
import 'view_models/explore_view_model.dart';
import '../home/view_models/timeline_view_model.dart';
import '../home/view_models/social_feed_view_model.dart';

class PlaceDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback onActionTriggered;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.onActionTriggered,
  });

  @override
  ConsumerState<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends ConsumerState<PlaceDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _submitReview(int ratingIndex) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    String status = "";
    int ratingVal = 1;
    if (ratingIndex == 0) {
      status = "Sad/Bad";
      ratingVal = 1;
    }
    if (ratingIndex == 1) {
      status = "Okay";
      ratingVal = 2;
    }
    if (ratingIndex == 2) {
      status = "Happy/Great";
      ratingVal = 3;
    }

    try {
      await client.from('feedbacks').insert({
        'user_id': user.id,
        'category': 'place_review',
        'content': 'Place feedback: $status',
        'rating': ratingVal,
        'place_id': widget.place['id']?.toString(),
      });
    } catch (e) {
      debugPrint("Error submitting review: $e");
    }

    if (mounted) {
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
  }

  void _sharePlace() {
    final String shareUrl = "https://more.app/places/${widget.place['id']}";
    Clipboard.setData(ClipboardData(text: shareUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم نسخ رابط المكان لمشاركته!",
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  void _performCheckIn(PlaceDetailsState state, PlaceDetailsViewModel viewModel) async {
    if (state.hasCheckedIn) return;

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
      // 1. Clear Supabase cache so new check-in shows up
      ExploreDataService.clearSupabaseCache();

      // 2. Reload home timeline and social feeds
      ref.read(timelineViewModelProvider.notifier).loadPosts();
      ref.read(timelineViewModelProvider.notifier).completeFirstCheckIn();
      ref.read(socialFeedViewModelProvider.notifier).refreshFeed();

      // 3. Re-fetch explore places
      final exploreState = ref.read(exploreViewModelProvider);
      final lat = exploreState.userLocation?.latitude ?? 24.7136;
      final lng = exploreState.userLocation?.longitude ?? 46.6753;
      ref.read(exploreViewModelProvider.notifier).fetchNearbyPlaces(lat, lng);

      // 4. Close the details screen to go back to home screen
      Navigator.of(context).pop();

      // 5. Direct user to home timeline index
      ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(0);

      // 6. Show snackbar on target screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "تم تسجيل تواجدك في المكان بنجاح!",
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          backgroundColor: const Color(0xFF7C57FC),
        ),
      );
    }
  }

  void _showMoreInfoBottomSheet(Map<String, dynamic> place) {
    final double lat = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
    final double lng = (place['longitude'] as num?)?.toDouble() ?? 30.697478;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PlaceDetailsMoreInfoSheet(
          place: place,
          lat: lat,
          lng: lng,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeDetailsViewModelProvider(widget.place));
    final viewModel = ref.read(placeDetailsViewModelProvider(widget.place).notifier);

    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final place = state.place;
    
    final ratingVal = place['rating'] as num? ?? 7.9;
    final reviewsCount = place['reviewsCount'] as int? ?? 36;
    final distanceStr = place['distance']?.toString() ?? '1.1 km';
    final double lat = (place['latitude'] as num?)?.toDouble() ?? 29.378033;
    final double lng = (place['longitude'] as num?)?.toDouble() ?? 30.697478;
    final bool hasPhotos = state.images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Swipable Hero Header Image Stack OR Placeholder
          PlaceDetailsHeader(
            topPadding: topPadding,
            hasPhotos: hasPhotos,
            images: state.images,
            currentPage: state.currentPage,
            onPageChanged: (index) {
              viewModel.updatePage(index);
            },
            onBackTap: () => Navigator.pop(context),
          ),

          // 2. Details Content Scroll View
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlaceDetailsInfo(
                    place: place,
                    ratingVal: ratingVal,
                    reviewsCount: reviewsCount,
                    distanceStr: distanceStr,
                    lat: lat,
                    lng: lng,
                    onAddHoursTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "تم فتح شاشة تعديل أوقات العمل",
                            style: GoogleFonts.ibmPlexSansArabic(),
                          ),
                        ),
                      );
                    },
                    onSuggestEditTap: () {},
                    onSeeMoreInfoTap: () => _showMoreInfoBottomSheet(place),
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),
                  
                  PlacePhotosSection(images: state.images, peopleImages: state.peopleImages),
                  const SizedBox(height: 24),

                  PlaceDetailsCheckInSection(
                    visitors: state.visitors,
                    hasCheckedIn: state.hasCheckedIn,
                    onCheckInTap: () => _performCheckIn(state, viewModel),
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),

                  PlaceRatingSection(
                    ratingVal: "$ratingVal",
                    reviewsCount: "$reviewsCount",
                    onRatingSubmitted: (ratingIndex) {
                      viewModel.submitRating(ratingIndex);
                      _submitReview(ratingIndex);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Real Place Posts Section
                  PlaceTipsSection(placePosts: state.placePosts),
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
                                "${state.visitors.length}",
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
                                "${state.placePosts.length}",
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
                    similarPlaces: state.similarPlaces,
                    onActionTriggered: widget.onActionTriggered,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Floating persistent Bottom Actions Bar
          PlaceDetailsActions(
            bottomPadding: bottomPadding,
            hasCheckedIn: state.hasCheckedIn,
            isSaved: state.isSaved,
            onCheckInTap: () => _performCheckIn(state, viewModel),
            onSaveTap: () {
              viewModel.toggleBookmark();
            },
            onShareTap: _sharePlace,
          ),
        ],
      ),
    );
  }
}


