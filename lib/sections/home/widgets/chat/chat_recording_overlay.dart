import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/chat_svgs.dart';
import '../../view_models/conversation_view_model.dart';

class ChatRecordingOverlay extends ConsumerWidget {
  final String threadId;

  const ChatRecordingOverlay({
    super.key,
    required this.threadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationViewModelProvider(threadId));
    final viewModel = ref.read(conversationViewModelProvider(threadId).notifier);

    final recordingSeconds = state.recordingSeconds;
    final isPaused = state.isPaused;
    final recordingWaveforms = state.recordingWaveforms;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: SvgPicture.string(
              ChatSvgs.deleteIcon,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
            ),
            tooltip: 'Discard',
            onPressed: viewModel.cancelRecording,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  '${recordingSeconds ~/ 60}:${(recordingSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF737373),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(recordingWaveforms.length, (idx) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 2.5,
                        height: isPaused ? 4 : recordingWaveforms[idx],
                        decoration: BoxDecoration(
                          color: isPaused ? const Color(0xFFC1C1C1) : const Color(0xFF7C57FC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          GestureDetector(
            onTap: viewModel.toggleRecordingPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              ),
              padding: const EdgeInsets.all(8),
              child: SvgPicture.string(
                isPaused ? ChatSvgs.playIcon : ChatSvgs.pauseIcon,
                colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              try {
                await viewModel.stopAndSendRecording();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF7C57FC),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: SvgPicture.string(
                ChatSvgs.sendIcon,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
