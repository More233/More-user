import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../../../view_models/story_composer_view_model.dart';

class ComposerCameraPreview extends ConsumerWidget {
  final CameraController? cameraController;
  final VoidCallback onGrantPermission;

  const ComposerCameraPreview({
    super.key,
    required this.cameraController,
    required this.onGrantPermission,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyComposerViewModelProvider);

    if (state.isPermissionDenied) {
      return Container(
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
                  : 'Please enable camera permission in your phone settings to capture and post stories.',
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onGrantPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                Directionality.of(context) == TextDirection.rtl ? 'منح الإذن' : 'Grant Permission',
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (cameraController == null || !state.isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C57FC)),
        ),
      );
    }

    return CameraPreview(cameraController!);
  }
}
