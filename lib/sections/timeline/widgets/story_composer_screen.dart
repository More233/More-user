import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../gallery_picker_screen.dart';
import 'check_in_composer_screen.dart';
import 'story_editor_screen.dart';

class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  bool _isStoryMode = true; // true = Story, false = Post
  bool _isFrontCamera = false;
  AssetEntity? _latestAsset;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInitCamera();
    _loadLatestAsset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndInitCamera();
    }
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    final cameraStatus = await Permission.camera.request();
    await Permission.microphone.request();

    if (cameraStatus.isGranted) {
      await _initializeCamera();
    } else {
      debugPrint("Camera permission was denied");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint("No cameras available");
        return;
      }

      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController?.dispose();
      _cameraController = controller;

      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _toggleCamera() async {
    if (_cameras.isEmpty) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
    });
    await _initializeCamera();
  }

  Future<void> _loadLatestAsset() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.common,
        );
        if (albums.isNotEmpty) {
          final int count = await albums[0].assetCountAsync;
          if (count > 0) {
            List<AssetEntity> assets = await albums[0].getAssetListRange(start: 0, end: 1);
            if (assets.isNotEmpty && mounted) {
              setState(() {
                _latestAsset = assets[0];
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading latest asset for story composer: $e");
    }
  }

  void _onShutterTap() async {
    if (_isCameraInitialized && _cameraController != null) {
      try {
        final XFile image = await _cameraController!.takePicture();
        if (!mounted) return;

        if (_isStoryMode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryEditorScreen(imagePath: image.path),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckInComposerScreen(),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error capturing photo from live camera: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to capture image: $e")),
        );
      }
    } else {
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryEditorScreen(imagePath: image.path),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckInComposerScreen(),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error launching camera fallback: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to launch camera: $e")),
        );
      }
    }
  }

  void _onGalleryTap() async {
    if (_isStoryMode) {
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
      final List<String>? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GalleryPickerScreen(previouslySelected: []),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: topPadding,
            color: Colors.white,
          ),
          // Viewfinder Card (rounded corners, expands to fill space, touching left/right screen edges)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Viewfinder background / camera preview
                    Positioned.fill(
                      child: _isCameraInitialized && _cameraController != null
                          ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize?.height ?? 1080,
                                height: _cameraController!.value.previewSize?.width ?? 1920,
                                child: CameraPreview(_cameraController!),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Dotted arrow SVG
                                    Opacity(
                                      opacity: 0.15,
                                      child: SvgPicture.asset(
                                        'assets/Timeline/icons/dotted_arrow.svg',
                                        width: 120,
                                        height: 120,
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "TAP TO CAPTURE",
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    
                    // Close / Cancel Button (Top Right, simple 'X' icon with no circular background)
                    Positioned(
                      top: 16,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(8), // touch target enhancement
                          child: SvgPicture.asset(
                            'assets/Timeline/icons/cancel_01.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    
                    // Bottom Controls Layer
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Gallery Thumbnail Button
                          GestureDetector(
                            onTap: _onGalleryTap,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _latestAsset != null
                                    ? AssetEntityImage(
                                        _latestAsset!,
                                        isOriginal: false,
                                        thumbnailSize: const ThumbnailSize(80, 80),
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.white10,
                                        padding: const EdgeInsets.all(8),
                                        child: SvgPicture.asset(
                                          'assets/Timeline/icons/google_photos.svg',
                                          width: 20,
                                          height: 20,
                                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          // Shutter Button
                          GestureDetector(
                            onTap: _onShutterTap,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 4),
                              ),
                              child: Center(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Flip Camera Button
                          GestureDetector(
                            onTap: _toggleCamera,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
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
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mode selector (Post vs. Story)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isStoryMode = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Post",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: !_isStoryMode ? Colors.black : const Color(0xFF9D9D9D),
                        fontWeight: !_isStoryMode ? FontWeight.bold : FontWeight.normal,
                        fontSize: !_isStoryMode ? 18 : 14,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isStoryMode = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Story",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: _isStoryMode ? Colors.black : const Color(0xFF9D9D9D),
                        fontWeight: _isStoryMode ? FontWeight.bold : FontWeight.normal,
                        fontSize: _isStoryMode ? 18 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
        ],
      ),
    );
  }
}
