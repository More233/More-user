import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String? _currentUserAvatarUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    if (widget.editPost != null) {
      final post = widget.editPost!;
      _locationName = post.title;
      _locationAddress = post.locationAddress;
      _captionController.text = post.description;
      _isPrivate = post.isPrivate;
      _selectedStickerIndex = post.stickerIndex;
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
      'path': 'assets/Timeline/Check-in Composer  First Check/icon/smile_outline.svg',
      'name': 'Smile',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/heart.png',
      'name': 'Heart',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/beer.png',
      'name': 'Beer',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/hands_face.png',
      'name': 'Shy/Clap',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/thumbs_up.png',
      'name': 'Thumbs Up',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/fire.png',
      'name': 'Fire',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/heart_eyes.png',
      'name': 'Heart Eyes',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline/Check-in Composer  First Check/image/plus_one.png',
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
              // 1. Map Image Background
              SizedBox(
                width: double.infinity,
                height: 220 + topPadding,
                child: Image.asset(
                  'assets/Timeline/Check-in Composer  First Check/image/map_background.png',
                  fit: BoxFit.cover,
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
                        'assets/Timeline/Check-in Composer  First Check/icon/location_pin.svg',
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
                                      'assets/Timeline/Personal Timeline  Default State/image/Element.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/Timeline/Personal Timeline  Default State/image/Element.png',
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
                      'assets/Timeline/Check-in Composer  First Check/icon/close.svg',
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
                left: 0,
                right: 0,
                height: 48,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_stickers.length, (index) {
                        final sticker = _stickers[index];
                        final bool isSelected = _selectedStickerIndex == index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStickerIndex = isSelected ? -1 : index;
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
          const SizedBox(height: 36),

          // Scrollable Card Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel Info Header
                  Center(
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
                                'assets/Timeline/Check-in Composer  First Check/icon/add_photos.svg',
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
                                  'assets/Timeline/Check-in Composer  First Check/icon/add_photos.svg',
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
                              'assets/Timeline/Check-in Composer  First Check/icon/add_friends.svg',
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
                                                      'assets/Timeline/Personal Timeline  Default State/image/Element.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    'assets/Timeline/Personal Timeline  Default State/image/Element.png',
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
                                'assets/Timeline/Check-in Composer  First Check/icon/add_friends.svg',
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
                        'assets/Timeline/Check-in Composer  First Check/icon/info_circle_small.svg',
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
                            'assets/Timeline/Check-in Composer  First Check/icon/info_circle_large.svg',
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
