import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _submitReview(int ratingIndex) {
    String status = "";
    if (ratingIndex == 0) status = "Sad/Bad";
    if (ratingIndex == 1) status = "Okay";
    if (ratingIndex == 2) status = "Happy/Great";

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

      viewModel.addCheckInVisitor(myName, myAvatarUrl);

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

      viewModel.loadPlacePosts();
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
    final place = widget.place;
    
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
                    onSeeMoreInfoTap: _showMoreInfoBottomSheet,
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


