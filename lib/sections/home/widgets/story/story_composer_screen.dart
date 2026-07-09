import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story_editor_screen.dart';
import '../../view_models/story_composer_view_model.dart';

// Modular UI Components
import 'components/composer_camera_preview.dart';
import 'components/composer_top_controls.dart';
import 'components/composer_bottom_controls.dart';

class StoryComposerScreen extends ConsumerStatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  ConsumerState<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends ConsumerState<StoryComposerScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  // Local camera helper values for zoom
  double _baseZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check permission and initialize camera
    _checkPermissionsAndInitCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    final notifier = ref.read(storyComposerViewModelProvider.notifier);

    if (lifecycleState == AppLifecycleState.inactive) {
      cameraController.dispose();
      notifier.setCameraInitialized(false);
    } else if (lifecycleState == AppLifecycleState.resumed) {
      _checkPermissionsAndInitCamera();
    }
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    final cameraStatus = await Permission.camera.request();
    await Permission.microphone.request();

    final notifier = ref.read(storyComposerViewModelProvider.notifier);
    notifier.setPermissionDenied(!cameraStatus.isGranted);

    if (cameraStatus.isGranted) {
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final state = ref.read(storyComposerViewModelProvider);
    final notifier = ref.read(storyComposerViewModelProvider.notifier);

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint("No cameras available");
        return;
      }

      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == (state.isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
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

      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = await controller.getMaxZoomLevel();

      if (mounted) {
        notifier.setCameraInitialized(true);
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  void _toggleCamera() async {
    if (_cameras.isEmpty) return;
    final notifier = ref.read(storyComposerViewModelProvider.notifier);
    
    notifier.toggleCameraDirection();
    notifier.setCameraInitialized(false);
    notifier.setFlashMode(FlashMode.off);
    
    await _initializeCamera();
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;
    final state = ref.read(storyComposerViewModelProvider);
    final notifier = ref.read(storyComposerViewModelProvider.notifier);

    try {
      if (state.flashMode == FlashMode.off) {
        notifier.setFlashMode(FlashMode.torch);
        await _cameraController!.setFlashMode(FlashMode.torch);
      } else {
        notifier.setFlashMode(FlashMode.off);
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint("Error toggling flash: $e");
    }
  }

  void _onShutterTap() async {
    final state = ref.read(storyComposerViewModelProvider);
    if (state.isRecording) {
      _stopRecordingVideo();
      return;
    }

    if (state.isCameraInitialized && _cameraController != null) {
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
    final state = ref.read(storyComposerViewModelProvider);
    final notifier = ref.read(storyComposerViewModelProvider.notifier);

    if (state.isRecording) return;
    
    if (state.isCameraInitialized && _cameraController != null) {
      try {
        if (state.flashMode == FlashMode.torch) {
          await _cameraController!.setFlashMode(FlashMode.torch);
        }
        await _cameraController!.startVideoRecording();
        notifier.startRecordingProgress();
      } catch (e) {
        debugPrint("Error starting video recording: $e");
      }
    } else {
      // Simulator fallback: start recording progress
      notifier.startRecordingProgress();
    }
  }

  void _stopRecordingVideo() async {
    final state = ref.read(storyComposerViewModelProvider);
    final notifier = ref.read(storyComposerViewModelProvider.notifier);

    if (!state.isRecording) return;
    
    notifier.stopRecordingTimer();
    
    if (state.isCameraInitialized && _cameraController != null) {
      try {
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        
        if (state.flashMode == FlashMode.torch) {
          await _cameraController!.setFlashMode(FlashMode.off);
        }
        
        if (state.recordingSeconds < 1) {
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
      }
    } else {
      if (state.recordingSeconds < 1) {
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

  void _onGalleryTap() async {
    try {
      final XFile? media = await _picker.pickMedia(
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (media == null) return;
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryEditorScreen(
            imagePath: media.path,
            isReels: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error picking story media: $e");
    }
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyComposerViewModelProvider);
    final notifier = ref.read(storyComposerViewModelProvider.notifier);

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
          
          // Viewfinder Card
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Camera preview
                  Positioned.fill(
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _baseZoomLevel = state.currentZoomLevel;
                        notifier.updateZoomLevel(_baseZoomLevel);
                      },
                      onScaleUpdate: (details) async {
                        if (_cameraController == null || !state.isCameraInitialized) return;
                        double newZoom = (_baseZoomLevel * details.scale).clamp(_minZoomLevel, _maxZoomLevel);
                        if (newZoom != state.currentZoomLevel) {
                          await _cameraController!.setZoomLevel(newZoom);
                          notifier.updateZoomLevel(newZoom);
                        }
                      },
                      child: ComposerCameraPreview(
                        cameraController: _cameraController,
                        onGrantPermission: _checkPermissionsAndInitCamera,
                      ),
                    ),
                  ),

                  // Top Centered Timer pill during recording
                  if (state.isRecording)
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
                                _formatDuration(state.recordingSeconds),
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

                  // Zoom level Indicator Pill
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IgnorePointer(
                        ignoring: !state.showZoomIndicator,
                        child: AnimatedOpacity(
                          opacity: state.showZoomIndicator ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              "${state.currentZoomLevel.toStringAsFixed(1)}x",
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top actions controls
                  if (!state.isRecording)
                    ComposerTopControls(
                      onClose: () => Navigator.pop(context),
                      onToggleFlash: _toggleFlash,
                      onToggleCamera: _toggleCamera,
                    ),

                  // Bottom actions controls
                  ComposerBottomControls(
                    onGalleryTap: _onGalleryTap,
                    onShutterTap: _onShutterTap,
                    onLongPressStart: (_) => _startRecordingVideo(),
                    onLongPressEnd: (_) => _stopRecordingVideo(),
                    onLongPressCancel: _stopRecordingVideo,
                    onToggleCamera: _toggleCamera,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
        ],
      ),
    );
  }
}
