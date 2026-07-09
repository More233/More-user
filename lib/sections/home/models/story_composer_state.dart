import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';

class StoryComposerState {
  final bool isFrontCamera;
  final bool isRecording;
  final double recordingProgress;
  final int recordingSeconds;
  final FlashMode flashMode;
  final bool isCameraInitialized;
  final bool isPermissionDenied;
  final double currentZoomLevel;
  final bool showZoomIndicator;
  final AssetEntity? latestAsset;

  StoryComposerState({
    required this.isFrontCamera,
    required this.isRecording,
    required this.recordingProgress,
    required this.recordingSeconds,
    required this.flashMode,
    required this.isCameraInitialized,
    required this.isPermissionDenied,
    required this.currentZoomLevel,
    required this.showZoomIndicator,
    this.latestAsset,
  });

  factory StoryComposerState.initial() {
    return StoryComposerState(
      isFrontCamera: false,
      isRecording: false,
      recordingProgress: 0.0,
      recordingSeconds: 0,
      flashMode: FlashMode.off,
      isCameraInitialized: false,
      isPermissionDenied: false,
      currentZoomLevel: 1.0,
      showZoomIndicator: false,
      latestAsset: null,
    );
  }

  StoryComposerState copyWith({
    bool? isFrontCamera,
    bool? isRecording,
    double? recordingProgress,
    int? recordingSeconds,
    FlashMode? flashMode,
    bool? isCameraInitialized,
    bool? isPermissionDenied,
    double? currentZoomLevel,
    bool? showZoomIndicator,
    AssetEntity? latestAsset,
    bool clearLatestAsset = false,
  }) {
    return StoryComposerState(
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isRecording: isRecording ?? this.isRecording,
      recordingProgress: recordingProgress ?? this.recordingProgress,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      flashMode: flashMode ?? this.flashMode,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
      showZoomIndicator: showZoomIndicator ?? this.showZoomIndicator,
      latestAsset: clearLatestAsset ? null : (latestAsset ?? this.latestAsset),
    );
  }
}
