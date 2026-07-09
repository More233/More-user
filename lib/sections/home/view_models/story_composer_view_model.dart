import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/story_composer_state.dart';

final storyComposerViewModelProvider = StateNotifierProvider.autoDispose<StoryComposerViewModel, StoryComposerState>((ref) {
  return StoryComposerViewModel();
});

class StoryComposerViewModel extends StateNotifier<StoryComposerState> {
  Timer? _recordingTimer;
  Timer? _zoomIndicatorTimer;

  StoryComposerViewModel() : super(StoryComposerState.initial()) {
    loadLatestAsset();
  }

  Future<void> loadLatestAsset() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) return;

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );

      if (paths.isNotEmpty) {
        final List<AssetEntity> assets = await paths.first.getAssetListRange(
          start: 0,
          end: 1,
        );
        if (assets.isNotEmpty) {
          state = state.copyWith(latestAsset: assets.first);
        }
      }
    } catch (e) {
      debugPrint("Error loading latest asset: $e");
    }
  }

  void setCameraInitialized(bool initialized) {
    state = state.copyWith(isCameraInitialized: initialized);
  }

  void setPermissionDenied(bool denied) {
    state = state.copyWith(isPermissionDenied: denied);
  }

  void toggleCameraDirection() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  void setFlashMode(FlashMode mode) {
    state = state.copyWith(flashMode: mode);
  }

  void updateZoomLevel(double zoom) {
    state = state.copyWith(currentZoomLevel: zoom, showZoomIndicator: true);
    _zoomIndicatorTimer?.cancel();
    _zoomIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      state = state.copyWith(showZoomIndicator: false);
    });
  }

  void startRecordingProgress() {
    state = state.copyWith(isRecording: true, recordingSeconds: 0, recordingProgress: 0.0);
    _recordingTimer?.cancel();
    
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final currentTick = timer.tick;
      final progress = (currentTick / 150.0).clamp(0.0, 1.0); // max 15 seconds (150 * 100ms)
      final seconds = currentTick ~/ 10;
      
      state = state.copyWith(
        recordingProgress: progress,
        recordingSeconds: seconds,
      );

      if (progress >= 1.0) {
        stopRecordingTimer();
      }
    });
  }

  void stopRecordingTimer() {
    _recordingTimer?.cancel();
    state = state.copyWith(isRecording: false);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _zoomIndicatorTimer?.cancel();
    super.dispose();
  }
}
