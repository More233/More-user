import 'dart:async';
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

enum CameraMode { post, story, reels }

class _StoryComposerScreenState extends State<StoryComposerScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  CameraMode _currentMode = CameraMode.story;
  bool _isFrontCamera = false;
  AssetEntity? _latestAsset;

  // Video recording state variables
  bool _isRecording = false;
  double _recordingProgress = 0.0;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final List<int> _reelsDurations = [15, 30, 45, 60, 90];
  int _selectedDurationIndex = 1; // Default 30s
  bool _showDurationSelector = false;
  FlashMode _flashMode = FlashMode.off;

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
    _recordingTimer?.cancel();
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
        enableAudio: true,
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
          type: RequestType.image,
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
    if (_isRecording) {
      _stopRecordingVideo();
      return;
    }
    if (_isCameraInitialized && _cameraController != null) {
      try {
        final XFile image = await _cameraController!.takePicture();
        if (!mounted) return;

        if (_currentMode == CameraMode.story || _currentMode == CameraMode.reels) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryEditorScreen(
                imagePath: image.path,
                isReels: _currentMode == CameraMode.reels,
              ),
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

        if (_currentMode == CameraMode.story || _currentMode == CameraMode.reels) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryEditorScreen(
                imagePath: image.path,
                isReels: _currentMode == CameraMode.reels,
              ),
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

  void _startRecordingVideo() async {
    if (!_isCameraInitialized || _cameraController == null || _isRecording) return;
    
    try {
      final int maxSeconds = _currentMode == CameraMode.reels
          ? _reelsDurations[_selectedDurationIndex]
          : 15; // default 15s for story
          
      // Flash torch on during video if desired
      if (_flashMode == FlashMode.torch) {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }

      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingProgress = 0.0;
        _recordingSeconds = 0;
      });
      
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        final elapsedMs = timer.tick * 100;
        final totalMs = maxSeconds * 1000;
        
        if (elapsedMs >= totalMs) {
          _stopRecordingVideo();
        } else {
          setState(() {
            _recordingProgress = elapsedMs / totalMs;
            _recordingSeconds = elapsedMs ~/ 1000;
          });
        }
      });
    } catch (e) {
      debugPrint("Error starting video recording: $e");
    }
  }

  void _stopRecordingVideo() async {
    if (!_isRecording || _cameraController == null) return;
    
    _recordingTimer?.cancel();
    _recordingTimer = null;
    
    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _recordingProgress = 0.0;
      });
      
      // Reset flash torch if it was on
      if (_flashMode == FlashMode.torch) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
      
      // If video duration is too short (less than 1s), delete/ignore it
      if (_recordingSeconds < 1) {
        debugPrint("Video recording was too short");
        return;
      }
      
      if (!mounted) return;
      
      // Navigate to Editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryEditorScreen(
            imagePath: videoFile.path,
            isReels: _currentMode == CameraMode.reels,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error stopping video recording: $e");
      setState(() {
        _isRecording = false;
        _recordingProgress = 0.0;
      });
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.torch;
        await _cameraController!.setFlashMode(FlashMode.torch);
      } else {
        _flashMode = FlashMode.off;
        await _cameraController!.setFlashMode(FlashMode.off);
      }
      setState(() {});
    } catch (e) {
      debugPrint("Error toggling flash: $e");
    }
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  void _onGalleryTap() async {
    if (_currentMode == CameraMode.story || _currentMode == CameraMode.reels) {
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
            builder: (context) => StoryEditorScreen(
              imagePath: image.path,
              isReels: _currentMode == CameraMode.reels,
            ),
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
                              color: Colors.black,
                            ),
                    ),
                    
                    // Flash Toggle Button (Top Left)
                    if (!_isRecording)
                      Positioned(
                        top: 16,
                        left: 20,
                        child: GestureDetector(
                          onTap: _toggleFlash,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                            ),
                            child: Icon(
                              _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                    // Top Center Timer chip during recording
                    if (_isRecording)
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDuration(_recordingSeconds),
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Close / Cancel Button (Top Right)
                    if (!_isRecording)
                      Positioned(
                        top: 16,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/home/icons/cancel_01.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    
                    // Left Control Sidebar (Timer)
                    if (!_isRecording && _currentMode == CameraMode.reels)
                      Positioned(
                        left: 20,
                        top: 100,
                        child: Column(
                          children: [
                            // Timer/Duration Selector Button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showDurationSelector = !_showDurationSelector;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black38,
                                ),
                                child: SvgPicture.asset(
                                  'assets/home/icons/time_04.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Translucent Duration Selector overlay
                    if (_showDurationSelector && _currentMode == CameraMode.reels && !_isRecording)
                      Positioned(
                        left: 76,
                        top: 140,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_reelsDurations.length, (idx) {
                              final duration = _reelsDurations[idx];
                              final isSelected = idx == _selectedDurationIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDurationIndex = idx;
                                    _showDurationSelector = false;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.white60,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$duration',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }),
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
                          if (!_isRecording)
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
                                            'assets/home/icons/google_photos.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                          ),
                                        ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44),
                          
                          // Shutter Button (Tap for photo, Long-press for video)
                          GestureDetector(
                            onTap: _onShutterTap,
                            onLongPressStart: (_) => _startRecordingVideo(),
                            onLongPressEnd: (_) => _stopRecordingVideo(),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Ring
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.25),
                                    border: Border.all(
                                      color: _isRecording ? Colors.red : Colors.white.withValues(alpha: 0.6),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                // Recording Progress Indicator
                                if (_isRecording)
                                  SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: CircularProgressIndicator(
                                      value: _recordingProgress,
                                      color: Colors.red,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                // Inner solid button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _isRecording ? 40 : 58,
                                  height: _isRecording ? 40 : 58,
                                  decoration: BoxDecoration(
                                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                                    borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                                    color: _isRecording ? Colors.red : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Flip Camera Button
                          if (!_isRecording)
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
                                  'assets/home/icons/change_camera.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mode selector (Post vs. Story vs. Reels)
          if (!_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMode = CameraMode.post;
                        _showDurationSelector = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "Post",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: _currentMode == CameraMode.post ? Colors.black : const Color(0xFF9D9D9D),
                          fontWeight: _currentMode == CameraMode.post ? FontWeight.bold : FontWeight.normal,
                          fontSize: _currentMode == CameraMode.post ? 18 : 14,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMode = CameraMode.story;
                        _showDurationSelector = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "Story",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: _currentMode == CameraMode.story ? Colors.black : const Color(0xFF9D9D9D),
                          fontWeight: _currentMode == CameraMode.story ? FontWeight.bold : FontWeight.normal,
                          fontSize: _currentMode == CameraMode.story ? 18 : 14,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMode = CameraMode.reels;
                        _showDurationSelector = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "Reels",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: _currentMode == CameraMode.reels ? Colors.black : const Color(0xFF9D9D9D),
                          fontWeight: _currentMode == CameraMode.reels ? FontWeight.bold : FontWeight.normal,
                          fontSize: _currentMode == CameraMode.reels ? 18 : 14,
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
