import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../gallery_picker_screen.dart';
import 'check_in_composer_screen.dart';
import 'story_editor_screen.dart';

class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isStoryMode = true; // true = Story, false = Post
  bool _isFrontCamera = false;

  void _onShutterTap() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;

      if (_isStoryMode) {
        // Route to Story Editor Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditorScreen(imagePath: image.path),
          ),
        );
      } else {
        // Route to Post Composer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckInComposerScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error launching camera: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to launch camera: $e")),
      );
    }
  }

  void _onGalleryTap() async {
    if (_isStoryMode) {
      // Pick single image from gallery and open Story Editor
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image == null) return;
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditorScreen(imagePath: image.path),
          ),
        );
      } catch (e) {
        debugPrint("Error picking story image: $e");
      }
    } else {
      // Pick images via GalleryPickerScreen
      final List<String>? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GalleryPickerScreen(previouslySelected: []),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        // Route to Post Composer with selected images
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckInComposerScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Simulated Viewfinder background (Dark overlay / pattern to look premium)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder Crosshairs / Grid
                  Opacity(
                    opacity: 0.15,
                    child: SvgPicture.asset(
                      'assets/Timeline/icons/dotted_arrow.svg', // Simulated icon
                      width: 120,
                      height: 120,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                  // Centered lens graphic
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 2),
                    ),
                  ),
                  Positioned(
                    child: Text(
                      "TAP TO CAPTURE",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Top Header Controls
          Positioned(
            top: topPadding + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
                Text(
                  _isStoryMode ? "Story Mode" : "Post Mode",
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFrontCamera = !_isFrontCamera;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/Timeline/icons/change_camera.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom controls panel (Shutter, Gallery, Mode Selector)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding > 0 ? bottomPadding + 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Controls Row: Gallery, Shutter, Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: _onGalleryTap,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/Timeline/icons/google_photos.svg',
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      // Large capture shutter button
                      GestureDetector(
                        onTap: _onShutterTap,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Camera icon indicator
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/Timeline/icons/camera.svg',
                          width: 26,
                          height: 26,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Mode Tab Switcher: Story vs. Post
                  Container(
                    height: 40,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Stack(
                      children: [
                        // Sliding Indicator
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          alignment: _isStoryMode ? Alignment.centerLeft : Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Label Row
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isStoryMode = true;
                                  });
                                },
                                child: Center(
                                  child: Text(
                                    "Story",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: _isStoryMode ? Colors.black : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isStoryMode = false;
                                  });
                                },
                                child: Center(
                                  child: Text(
                                    "Post",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: !_isStoryMode ? Colors.black : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}
