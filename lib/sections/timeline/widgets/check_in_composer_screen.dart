import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/timeline_post.dart';
import '../gallery_picker_screen.dart';
import 'add_friends_bottom_sheet.dart';
import 'intro_bottom_sheet.dart';
import 'posting_loading_screen.dart';

class CheckInComposerScreen extends StatefulWidget {
  final bool isFirstCheckIn;
  final TimelinePost? editPost;
  const CheckInComposerScreen({
    super.key,
    this.isFirstCheckIn = false,
    this.editPost,
  });

  @override
  State<CheckInComposerScreen> createState() => _CheckInComposerScreenState();
}

class _CheckInComposerScreenState extends State<CheckInComposerScreen> {
  final TextEditingController _captionController = TextEditingController();
  String _locationName = "Helnan Auberge El Fayoum Hotel";
  String _locationAddress = "Muhafazat al Fayyūm, Egypt";
  
  List<String> _selectedImages = [];
  List<Map<String, dynamic>> _taggedFriends = [];
  bool _isPrivate = false;
  int _selectedStickerIndex = -1; // -1 means none selected
  bool _isStickerTrayOpen = false;
  String? _currentUserAvatarUrl;
  bool _isSaving = false;

  GoogleMapController? _mapController;
  double _latitude = 29.378033;
  double _longitude = 30.697478;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    if (widget.editPost != null) {
      final post = widget.editPost!;
      _locationName = post.title;
      _locationAddress = post.locationAddress;
      final match = _locations.firstWhere(
        (loc) => loc['name'] == post.title || loc['address'] == post.locationAddress,
        orElse: () => _locations.first,
      );
      _latitude = match['latitude'] as double;
      _longitude = match['longitude'] as double;
      _captionController.text = post.description;
      _isPrivate = post.isPrivate;
      _selectedStickerIndex = post.stickerIndex;
      _isStickerTrayOpen = post.stickerIndex != -1;
      if (post.imageUrl != null) {
        _selectedImages = [post.imageUrl!];
      }
      _taggedFriends = post.taggedFriends.map((name) => {'name': name}).toList();
    } else if (widget.isFirstCheckIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroBottomSheet();
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final data = await client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && data['avatar_url'] != null && mounted) {
          setState(() {
            _currentUserAvatarUrl = data['avatar_url'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }

  void _showIntroBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return IntroBottomSheet(
          onStartTap: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Sticker assets
  final List<Map<String, dynamic>> _stickers = [
    {
      'type': 'svg',
      'path': 'assets/Timeline/icons/smile_outline.svg',
      'name': 'Smile',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/heart.png',
      'name': 'Heart',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/beer.png',
      'name': 'Beer',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/hands_face.png',
      'name': 'Shy/Clap',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/thumbs_up.png',
      'name': 'Thumbs Up',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/fire.png',
      'name': 'Fire',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/heart_eyes.png',
      'name': 'Heart Eyes',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/images/plus_one.png',
      'name': '+1',
    },
  ];

  void _openGallery() async {
    final List<String>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPickerScreen(previouslySelected: _selectedImages),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedImages = result;
      });
    }
  }

  void _openAddFriends() async {
    final List<Map<String, dynamic>>? result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFriendsBottomSheet(previouslySelected: _taggedFriends),
    );

    if (result != null) {
      setState(() {
        _taggedFriends = result;
      });
    }
  }

  void _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;

    final newPost = TimelinePost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _locationName,
      categoryName: 'Hotel',
      locationAddress: _locationAddress,
      visitorCount: 1,
      postTime: 'Today • Just now',
      description: caption,
      imageUrl: _selectedImages.isNotEmpty ? _selectedImages.first : null,
      likesCount: 0,
      commentsCount: 0,
      categoryIcon: CategoryIconType.building,
      comments: [],
      isPrivate: _isPrivate,
      stickerIndex: _selectedStickerIndex,
      taggedFriends: _taggedFriends.map((f) => f['name'] as String).toList(),
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PostingLoadingScreen(
          newPost: newPost,
          selectedImages: _selectedImages,
          currentUserAvatarUrl: _currentUserAvatarUrl,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _saveChanges() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final client = Supabase.instance.client;
      String? finalImageUrl = _selectedImages.isNotEmpty ? _selectedImages.first : null;

      // If it's a local file path, upload it to storage
      if (finalImageUrl != null && (finalImageUrl.startsWith('/') || finalImageUrl.startsWith('file:'))) {
        final user = client.auth.currentUser;
        if (user != null) {
          final file = File(finalImageUrl);
          final fileName = 'posts/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await client.storage.from('post-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          finalImageUrl = client.storage.from('post-images').getPublicUrl(fileName);
        }
      }

      await client.from('posts').update({
        'description': caption,
        'image_url': finalImageUrl,
        'is_private': _isPrivate,
        'sticker_index': _selectedStickerIndex,
        'tagged_friends': _taggedFriends.map((f) => f['name'] as String).toList(),
      }).eq('id', widget.editPost!.id);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error updating post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save changes: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCaption = _captionController.text.trim().isNotEmpty;
    final int remainingChars = 160 - _captionController.text.length;
    final double topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
        children: [
          // Top Map Header Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Interactive Google Map Background
              SizedBox(
                width: double.infinity,
                height: 220 + topPadding,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_latitude, _longitude),
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                ),
              ),

              // 2. Map pin with user avatar in center
              Positioned(
                top: topPadding + 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/Timeline/icons/location_pin.svg',
                        width: 80,
                        height: 80,
                      ),
                      Positioned(
                        top: 12,
                        child: Container(
                          width: 47,
                          height: 47,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF945CF6), width: 1.5),
                          ),
                          child: ClipOval(
                            child: _currentUserAvatarUrl != null
                                ? Image.network(
                                    _currentUserAvatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, s) => Image.asset(
                                      'assets/Timeline/images/element.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/Timeline/images/element.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Floating Close Button at top-right
              Positioned(
                top: topPadding + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/Timeline/icons/close.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF333333),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Horizontal Stickers Row overlapping the map bottom
              Positioned(
                bottom: -20,
                left: 16,
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Toggle Button (purple circle with white smiley face matching story viewer)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isStickerTrayOpen = !_isStickerTrayOpen;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC), // Solid purple matching story
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE8E8E8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/Timeline/icons/smile.svg',
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    
                    // Sliding Animated Tray containing remaining stickers
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      width: _isStickerTrayOpen
                          ? ((40.0 + 8.0) * (_stickers.length - 1) - 8.0).clamp(
                              0.0,
                              MediaQuery.of(context).size.width - 80.0,
                            )
                          : 0,
                      height: 40,
                      margin: EdgeInsets.only(left: _isStickerTrayOpen ? 8 : 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isStickerTrayOpen ? 1.0 : 0.0,
                          child: Row(
                            children: List.generate(_stickers.length - 1, (index) {
                              final actualIndex = index + 1;
                              final sticker = _stickers[actualIndex];
                              final bool isSelected = _selectedStickerIndex == actualIndex;

                              return Padding(
                                padding: EdgeInsets.only(right: index == _stickers.length - 2 ? 0 : 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStickerIndex = isSelected ? -1 : actualIndex;
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF7C57FC)
                                            : const Color(0xFFE8E8E8),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: sticker['type'] == 'svg'
                                        ? SvgPicture.asset(
                                            sticker['path'],
                                            fit: BoxFit.contain,
                                          )
                                        : Image.asset(
                                            sticker['path'],
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Scrollable Card Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Hotel Info Header
                  Center(
                    child: GestureDetector(
                      onTap: _openChangeLocation,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        children: [
                          Text(
                            _locationName,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF303030),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.editPost != null ? _locationAddress : "Change location",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C57FC).withValues(alpha: 0.85),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text Area Caption Input
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4D4D4)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _captionController,
                          maxLength: 160,
                          maxLines: null,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            color: const Color(0xFF303030),
                          ),
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          decoration: InputDecoration(
                            hintText: "What're you up to?",
                            hintStyle: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              color: const Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                        // Character counter overlay in the bottom right corner
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            '$remainingChars',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional Add Photos dashed button
                  if (_selectedImages.isEmpty) ...[
                    GestureDetector(
                      onTap: _openGallery,
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: const Color(0xFF7C57FC).withValues(alpha: 0.7),
                          borderRadius: 12,
                        ),
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C57FC).withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/Timeline/icons/add_photos.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Add photos (Optional)",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF7C57FC),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Selected Images Previews Grid
                  if (_selectedImages.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ...List.generate(_selectedImages.length, (index) {
                            final imgPath = _selectedImages[index];
                            final isNetwork = imgPath.startsWith('http://') || imgPath.startsWith('https://');
                            final isAsset = !isNetwork && !imgPath.startsWith('/') && !imgPath.startsWith('file:');
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isNetwork
                                        ? Image.network(
                                            imgPath,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          )
                                        : isAsset
                                            ? Image.asset(
                                                imgPath,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(imgPath),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          // Add Photos dashed card
                          GestureDetector(
                            onTap: _openGallery,
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: const Color(0xFF7C57FC).withValues(alpha: 0.7),
                                borderRadius: 12,
                              ),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C57FC).withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  'assets/Timeline/icons/add_photos.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF7C57FC),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Check-in With Friends tag widgets
                  Text(
                    "Check-in with",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF121212),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_taggedFriends.isEmpty)
                    GestureDetector(
                      onTap: _openAddFriends,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE6FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/Timeline/icons/add_friends.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF7C57FC),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Add friends",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7C57FC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _openAddFriends,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEDE6FC)),
                        ),
                        child: Row(
                          children: [
                            // Overlapping Avatars Group
                            SizedBox(
                              height: 44,
                              child: Builder(
                                builder: (context) {
                                  final int total = _taggedFriends.length;
                                  final List<Widget> children = [];
                                  
                                  // Show up to 2 avatars
                                  final int displayAvatars = total > 2 ? 2 : total;
                                  for (int i = 0; i < displayAvatars; i++) {
                                    final friend = _taggedFriends[i];
                                    final avatarUrl = friend['avatar_url'] as String?;
                                    children.add(
                                      Positioned(
                                        left: i * 24.0, // 44px size, overlaps by 20px
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: avatarUrl != null
                                                ? Image.network(
                                                    avatarUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, e, s) => Image.asset(
                                                      'assets/Timeline/images/element.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    'assets/Timeline/images/element.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // Show +X indicator if total > 2
                                  if (total > 2) {
                                    children.add(
                                      Positioned(
                                        left: 2 * 24.0,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDE6FC),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '+${total - 2}',
                                            style: GoogleFonts.ibmPlexSansArabic(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF7C57FC),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final double width = (displayAvatars * 24.0) + (total > 2 ? 44.0 : 20.0);
                                  return SizedBox(
                                    width: width,
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: children,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tagged friends names list text
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final int total = _taggedFriends.length;
                                  String namesText = '';
                                  if (total == 1) {
                                    namesText = _taggedFriends[0]['name'] as String;
                                  } else if (total == 2) {
                                    namesText = '${_taggedFriends[0]['name']}, ${_taggedFriends[1]['name']}';
                                  } else {
                                    namesText = '${_taggedFriends[0]['name']}, ${_taggedFriends[1]['name']} +${total - 2}';
                                  }
                                  return Text(
                                    namesText,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF666666),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Small add friends square button
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE6FC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                'assets/Timeline/icons/add_friends.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Private Check-in Switch Row
                  Row(
                    children: [
                      Text(
                        "Private check-in",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF121212),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/Timeline/icons/info_circle_small.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF82858C),
                          BlendMode.srcIn,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPrivate = !_isPrivate;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 51,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _isPrivate ? const Color(0xFF7C57FC) : const Color(0xFFD1D1D1),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isPrivate ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Info Banner Card (Add caption to continue)
                  if (!hasCaption)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE6FC).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/Timeline/icons/info_circle_large.svg',
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF7C57FC),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Add caption to continue.\nPhotos and friends are optional.",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF7C57FC),
                                fontWeight: FontWeight.normal,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
             ),
            ),
          ),

          // Bottom Action Button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: hasCaption && !_isSaving
                      ? (widget.editPost != null ? _saveChanges : _submitPost)
                      : null,
                  child: Opacity(
                    opacity: hasCaption && !_isSaving ? 1.0 : 0.6,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.editPost != null ? 'Save changes' : 'Continue',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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

  void _openChangeLocation() async {
    final Map<String, dynamic>? selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const _LocationSearchSheet();
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _locationName = selected['name'] as String;
        _locationAddress = selected['address'] as String;
        _latitude = selected['latitude'] as double;
        _longitude = selected['longitude'] as double;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_latitude, _longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

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
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    this.color = const Color(0xFF7C57FC),
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.borderRadius != borderRadius;
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
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
  String? _lastNewApiError;
  String? _lastLegacyApiError;

  @override
  void initState() {
    super.initState();
    _loadInitialPlaces();
  }

  String _getApiKey() {
    return "AIzaSyBjxRXgMKAxdj8WeeI2VYGEhBA8lxTR5Ug";
  }

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {};
    if (Platform.isAndroid) {
      headers['X-Android-Package'] = 'com.example.moor';
      headers['X-Android-Cert'] = '385558994848088be8e80907b01f5fade2913383';
    } else if (Platform.isIOS) {
      headers['X-Ios-Bundle-Identifier'] = 'com.app.more.premium';
    }
    return headers;
  }

  IconData _getIconForTypes(List<dynamic> types) {
    if (types.contains('restaurant') || types.contains('food') || types.contains('cafe') || types.contains('bakery') || types.contains('bar')) {
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
    if (types.contains('store') || types.contains('shopping_mall') || types.contains('clothing_store')) {
      return Icons.shopping_bag;
    }
    if (types.contains('church') || types.contains('mosque') || types.contains('hindu_temple') || types.contains('synagogue') || types.contains('place_of_worship')) {
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
      _lastNewApiError = null;
      _lastLegacyApiError = null;
    });

    bool success = await _fetchNearbyNew(lat, lng);
    if (!success) {
      success = await _fetchNearbyLegacy(lat, lng);
    }
    
    if (!success) {
      _loadFallbackLocations();
      setState(() {
        _apiErrorMessage = "Could not fetch nearby places.\n• Places API (New): ${_lastNewApiError ?? 'Unknown error'}\n• Places API (Legacy): ${_lastLegacyApiError ?? 'Unknown error'}";
      });
    } else {
      setState(() {
        _apiErrorMessage = null;
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _fetchNearbyNew(double lat, double lng) async {
    try {
      final String apiKey = _getApiKey();
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.types',
        ..._getHeaders(),
      };

      final Map<String, dynamic> body = {
        "includedTypes": [
          "restaurant", "cafe", "lodging", "tourist_attraction", 
          "park", "store", "shopping_mall", "establishment", "point_of_interest"
        ],
        "maxResultCount": 20,
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": lat,
              "longitude": lng
            },
            "radius": 3000.0
          }
        }
      };

      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['places'] != null) {
          final List<dynamic> results = data['places'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final displayNameObj = res['displayName'] as Map<String, dynamic>?;
            final name = displayNameObj?['text'] as String? ?? '';
            final address = res['formattedAddress'] as String? ?? '';
            final locationObj = res['location'] as Map<String, dynamic>?;
            final plat = locationObj?['latitude'] as double? ?? 0.0;
            final plng = locationObj?['longitude'] as double? ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            places.add({
              'name': name,
              'address': address,
              'latitude': plat,
              'longitude': plng,
              'distance': distanceStr,
              'icon': _getIconForTypes(types),
            });
          }
          setState(() {
            _nearbyLocations = places;
            _filteredLocations = places;
            _lastNewApiError = null;
          });
          return true;
        } else {
          _lastNewApiError = "Response has no 'places' field.";
          return false;
        }
      } else {
        try {
          final errBody = json.decode(response.body);
          final errorObj = errBody['error'] as Map<String, dynamic>?;
          _lastNewApiError = errorObj?['message'] as String? ?? "HTTP ${response.statusCode}: ${response.body}";
        } catch (_) {
          _lastNewApiError = "HTTP ${response.statusCode}: ${response.body}";
        }
        return false;
      }
    } catch (e) {
      debugPrint("Error in Places API New Nearby: $e");
      _lastNewApiError = "Exception: $e";
      return false;
    }
  }

  Future<bool> _fetchNearbyLegacy(double lat, double lng) async {
    try {
      final String apiKey = _getApiKey();
      final Map<String, String> headers = _getHeaders();

      // Legacy Google Places Nearby Search
      final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=3000'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          final List<dynamic> results = data['results'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final name = res['name'] as String? ?? '';
            final address = res['vicinity'] as String? ?? '';
            final geometry = res['geometry'] as Map<String, dynamic>?;
            final loc = geometry?['location'] as Map<String, dynamic>?;
            final plat = loc?['lat'] as double? ?? 0.0;
            final plng = loc?['lng'] as double? ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(lat, lng, plat, plng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            places.add({
              'name': name,
              'address': address,
              'latitude': plat,
              'longitude': plng,
              'distance': distanceStr,
              'icon': _getIconForTypes(types),
            });
          }
          setState(() {
            _nearbyLocations = places;
            _filteredLocations = places;
            _lastLegacyApiError = null;
          });
          return true;
        } else {
          _lastLegacyApiError = data['error_message'] ?? 'Status: ${data['status']}';
          return false;
        }
      } else {
        _lastLegacyApiError = "HTTP ${response.statusCode}: ${response.body}";
        return false;
      }
    } catch (e) {
      debugPrint("Error fetching nearby places: $e");
      _lastLegacyApiError = "Exception: $e";
      return false;
    }
  }

  void _loadFallbackLocations() {
    final List<Map<String, dynamic>> fallback = [];
    for (final loc in _CheckInComposerScreenState._locations) {
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
        _lastNewApiError = null;
        _lastLegacyApiError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _apiErrorMessage = null;
      _lastNewApiError = null;
      _lastLegacyApiError = null;
    });

    bool success = await _performSearchNew(query);
    if (!success) {
      success = await _performSearchLegacy(query);
    }

    if (!success) {
      setState(() {
        _filteredLocations = [];
        _apiErrorMessage = "Search failed.\n• Places API (New): ${_lastNewApiError ?? 'Unknown error'}\n• Places API (Legacy): ${_lastLegacyApiError ?? 'Unknown error'}";
      });
    } else {
      setState(() {
        _apiErrorMessage = null;
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

  Future<bool> _performSearchNew(String query) async {
    try {
      final String apiKey = _getApiKey();
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.types',
        ..._getHeaders(),
      };

      final Map<String, dynamic> body = {
        "textQuery": query,
        "locationBias": {
          "circle": {
            "center": {
              "latitude": _latitude,
              "longitude": _longitude
            },
            "radius": 50000.0
          }
        }
      };

      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchText'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['places'] != null) {
          final List<dynamic> results = data['places'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final displayNameObj = res['displayName'] as Map<String, dynamic>?;
            final name = displayNameObj?['text'] as String? ?? '';
            final address = res['formattedAddress'] as String? ?? '';
            final locationObj = res['location'] as Map<String, dynamic>?;
            final lat = locationObj?['latitude'] as double? ?? 0.0;
            final lng = locationObj?['longitude'] as double? ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(_latitude, _longitude, lat, lng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            places.add({
              'name': name,
              'address': address,
              'latitude': lat,
              'longitude': lng,
              'distance': distanceStr,
              'icon': _getIconForTypes(types),
            });
          }
          setState(() {
            _filteredLocations = places;
            _lastNewApiError = null;
          });
          return true;
        } else {
          _lastNewApiError = "Response has no 'places' field.";
          return false;
        }
      } else {
        try {
          final errBody = json.decode(response.body);
          final errorObj = errBody['error'] as Map<String, dynamic>?;
          _lastNewApiError = errorObj?['message'] as String? ?? "HTTP ${response.statusCode}: ${response.body}";
        } catch (_) {
          _lastNewApiError = "HTTP ${response.statusCode}: ${response.body}";
        }
        return false;
      }
    } catch (e) {
      debugPrint("Error in Places API New Search: $e");
      _lastNewApiError = "Exception: $e";
      return false;
    }
  }

  Future<bool> _performSearchLegacy(String query) async {
    try {
      final String apiKey = _getApiKey();
      final Map<String, String> headers = _getHeaders();
      
      // Text Search works globally and accepts coordinates to bias results
      final String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&location=$_latitude,$_longitude'
          '&radius=50000'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          final List<dynamic> results = data['results'];
          final List<Map<String, dynamic>> places = [];
          for (final res in results) {
            final name = res['name'] as String? ?? '';
            final address = res['formatted_address'] as String? ?? res['vicinity'] as String? ?? '';
            final geometry = res['geometry'] as Map<String, dynamic>?;
            final loc = geometry?['location'] as Map<String, dynamic>?;
            final lat = loc?['lat'] as double? ?? 0.0;
            final lng = loc?['lng'] as double? ?? 0.0;
            final types = res['types'] as List<dynamic>? ?? [];

            final double meters = Geolocator.distanceBetween(_latitude, _longitude, lat, lng);
            final double km = meters / 1000;
            final String distanceStr = km < 1 
                ? '${meters.toStringAsFixed(0)} m' 
                : '${km.toStringAsFixed(1)} km';

            places.add({
              'name': name,
              'address': address,
              'latitude': lat,
              'longitude': lng,
              'distance': distanceStr,
              'icon': _getIconForTypes(types),
            });
          }
          setState(() {
            _filteredLocations = places;
            _lastLegacyApiError = null;
          });
          return true;
        } else {
          _lastLegacyApiError = data['error_message'] ?? 'Status: ${data['status']}';
          return false;
        }
      } else {
        _lastLegacyApiError = "HTTP ${response.statusCode}: ${response.body}";
        return false;
      }
    } catch (e) {
      debugPrint("Error performing places search legacy: $e");
      _lastLegacyApiError = "Exception: $e";
      return false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header Search Row
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
  
            // Places List or Loading State
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
                                    child: Text(
                                      'No places found',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 16,
                                        color: const Color(0xFF82858C),
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
