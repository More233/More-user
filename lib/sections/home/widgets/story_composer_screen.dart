import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'story_editor_screen.dart';

class StoryComposerScreen extends StatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  State<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends State<StoryComposerScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  bool _isFrontCamera = false;
  AssetEntity? _latestAsset;

  // Video recording state variables
  bool _isRecording = false;
  double _recordingProgress = 0.0;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  FlashMode _flashMode = FlashMode.off;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;

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

    if (mounted) {
      setState(() {
        _isPermissionDenied = !cameraStatus.isGranted;
      });
    }

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

      final hasMicPermission = await Permission.microphone.isGranted;
      
      CameraController controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: hasMicPermission,
      );

      await _cameraController?.dispose();
      _cameraController = controller;

      try {
        await controller.initialize();
      } catch (e) {
        debugPrint("Failed to initialize camera with audio: $e. Retrying without audio.");
        controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        _cameraController = controller;
        await controller.initialize();
      }

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
      _flashMode = FlashMode.off;
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditorScreen(
              imagePath: image.path,
              isReels: false,
            ),
          ),
        );
      } catch (e) {
        debugPrint("Error capturing photo from live camera: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'الكاميرا غير متوفرة'
                : 'Camera is not available',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    }
  }

  void _startRecordingVideo() async {
    if (_isRecording) return;
    final int maxSeconds = 30; // 30s limit for story video
    
    if (_isCameraInitialized && _cameraController != null) {
      try {
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
    } else {
      // Simulate video recording on simulator
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
    }
  }

  void _stopRecordingVideo() async {
    if (!_isRecording) return;
    
    _recordingTimer?.cancel();
    _recordingTimer = null;
    
    if (_isCameraInitialized && _cameraController != null) {
      try {
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        
        setState(() {
          _isRecording = false;
          _recordingProgress = 0.0;
        });
        
        if (_flashMode == FlashMode.torch) {
          await _cameraController!.setFlashMode(FlashMode.off);
        }
        
        if (_recordingSeconds < 1) {
          debugPrint("Video recording was too short");
          return;
        }
        
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditorScreen(
              imagePath: videoFile.path,
              isReels: false,
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
    } else {
      // Simulate stop recording on simulator: copy mock file and proceed
      setState(() {
        _isRecording = false;
        _recordingProgress = 0.0;
      });
      
      if (_recordingSeconds < 1) {
        debugPrint("Simulated video recording was too short");
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Directionality.of(context) == TextDirection.rtl
                ? 'الكاميرا غير متوفرة'
                : 'Camera is not available',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
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
            isReels: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error picking story image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            height: topPadding,
            color: Colors.black,
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
                      child: _isPermissionDenied
                          ? Container(
                              color: const Color(0xFF1E1E1E),
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.videocam_off_outlined,
                                      color: Color(0xFF7C57FC),
                                      size: 64,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    Directionality.of(context) == TextDirection.rtl
                                        ? 'مطلوب إذن الكاميرا'
                                        : 'Camera Access Required',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    Directionality.of(context) == TextDirection.rtl
                                        ? 'يرجى تمكين إذن الكاميرا من إعدادات الهاتف لالتقاط ونشر القصص.'
                                        : 'Please enable camera access in your device settings to capture and post stories.',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7C57FC),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: () => openAppSettings(),
                                      child: Text(
                                        Directionality.of(context) == TextDirection.rtl
                                            ? 'فتح الإعدادات'
                                            : 'Open Settings',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (_isCameraInitialized && _cameraController != null
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
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF7C57FC),
                                    ),
                                  ),
                                )),
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
                              color: Colors.black,
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                            child: SvgPicture.asset(
                              'assets/home/icons/cancel_01.svg',
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
                                  color: Colors.black,
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
          
          SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
        ],
      ),
    );
  }
}
