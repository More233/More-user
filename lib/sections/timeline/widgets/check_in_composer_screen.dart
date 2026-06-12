import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/timeline_post.dart';
import '../gallery_picker_screen.dart';
import 'add_friends_bottom_sheet.dart';
import 'intro_bottom_sheet.dart';

class CheckInComposerScreen extends StatefulWidget {
  final bool isFirstCheckIn;
  const CheckInComposerScreen({super.key, this.isFirstCheckIn = false});

  @override
  State<CheckInComposerScreen> createState() => _CheckInComposerScreenState();
}

class _CheckInComposerScreenState extends State<CheckInComposerScreen> {
  final TextEditingController _captionController = TextEditingController();
  final String _locationName = "Helnan Auberge El Fayoum Hotel";
  
  List<String> _selectedImages = [];
  List<String> _taggedFriends = [];
  bool _isPrivate = false;
  int _selectedStickerIndex = -1; // -1 means none selected

  @override
  void initState() {
    super.initState();
    if (widget.isFirstCheckIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntroBottomSheet();
      });
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
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/smile_outline.svg',
      'name': 'Smile',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/heart.png',
      'name': 'Heart',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/beer.png',
      'name': 'Beer',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/hands_face.png',
      'name': 'Shy/Clap',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/thumbs_up.png',
      'name': 'Thumbs Up',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/fire.png',
      'name': 'Fire',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/heart_eyes.png',
      'name': 'Heart Eyes',
    },
    {
      'type': 'image',
      'path': 'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/plus_one.png',
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
    final List<String>? result = await showModalBottomSheet<List<String>>(
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

  void _submitPost() {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;

    final newPost = TimelinePost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _locationName,
      categoryName: 'Hotel',
      locationAddress: 'El Fayoum, Egypt',
      visitorCount: 1,
      postTime: 'Today • Just now',
      description: caption,
      imageUrl: _selectedImages.isNotEmpty ? _selectedImages.first : null,
      likesCount: 0,
      commentsCount: 0,
      categoryIcon: CategoryIconType.building,
      comments: [],
    );

    Navigator.pop(context, newPost);
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

    return Scaffold(
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
                  'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/image/map_background.png',
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
                        'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/location_pin.svg',
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
                            child: Image.asset(
                              'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/image/Element.png',
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
                      'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/close.svg',
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
                          "Change location",
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
                  const SizedBox(height: 16),

                  // Optional Add Photos dashed button
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
                              'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/add_photos.svg',
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
                  const SizedBox(height: 16),

                  // Selected Images Previews Horizontal Tray
                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          final imgPath = _selectedImages[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    imgPath,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Tag button
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
                                'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/add_friends.svg',
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
                      ),
                      // Tagged friends chips
                      ..._taggedFriends.map((friend) {
                        return Chip(
                          avatar: const CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/image/Element.png',
                            ),
                          ),
                          label: Text(
                            friend,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF7C57FC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: const Color(0xFFF2EEFC),
                          deleteIconColor: const Color(0xFF7C57FC),
                          onDeleted: () {
                            setState(() {
                              _taggedFriends.remove(friend);
                            });
                          },
                        );
                      }),
                    ],
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
                        'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/info_circle_small.svg',
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
                            'assets/Timeline Phase need to rename/Timeline Section  Check-in Composer  First Check/icon/info_circle_large.svg',
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
          Padding(
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
                onPressed: hasCaption ? _submitPost : null,
                child: Opacity(
                  opacity: hasCaption ? 1.0 : 0.6,
                  child: Text(
                    'Continue',
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
        ],
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
