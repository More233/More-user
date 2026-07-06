import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/chat_svgs.dart';
import '../../view_models/conversation_view_model.dart';

class ChatMessageBubble extends ConsumerWidget {
  final String threadId;
  final Map<String, dynamic> msg;
  final String currentUserId;
  final Map<String, dynamic> otherProfile;

  const ChatMessageBubble({
    super.key,
    required this.threadId,
    required this.msg,
    required this.currentUserId,
    required this.otherProfile,
  });

  ImageProvider _getAvatarProvider(String username, String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return NetworkImage(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    switch (username.toLowerCase()) {
      case 'mayat':
        return const AssetImage('assets/home/images/profile_image_1.png');
      case 'jordanmarco':
        return const AssetImage('assets/home/images/profile_image2.png');
      case 'avaj':
        return const AssetImage('assets/home/images/avatar.png');
      case 'karennne':
        return const AssetImage('assets/home/images/element.png');
      default:
        return const AssetImage('assets/home/images/element.png');
    }
  }

  void _showDeleteMessageSheet(BuildContext context, WidgetRef ref) {
    final isMyMessage = msg['sender_id'] == currentUserId;
    final viewModel = ref.read(conversationViewModelProvider(threadId).notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1C1C1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Delete Message',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: SvgPicture.string(
                  ChatSvgs.deleteIcon,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
                ),
                title: Text(
                  'Delete for me',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF303030),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await viewModel.deleteMessageForMe(msg);
                },
              ),
              if (isMyMessage)
                ListTile(
                  leading: SvgPicture.string(
                    ChatSvgs.deleteIcon,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
                  ),
                  title: Text(
                    'Delete for everyone',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF303030),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await viewModel.deleteMessageForEveryone(msg);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioWaveform(BuildContext context, WidgetRef ref, bool isSent) {
    final msgId = msg['id'] as String;
    final url = msg['content'] as String;
    final duration = msg['media_duration'] as int? ?? 0;

    final state = ref.watch(conversationViewModelProvider(threadId));
    final viewModel = ref.read(conversationViewModelProvider(threadId).notifier);

    final isCurrentPlaying = state.activeAudioId == msgId;
    final List<double> barHeights = [
      11.8, 19.7, 25.0, 25.0, 9.2, 14.5, 22.3, 9.2, 9.2, 3.9, 3.9, 27.6, 19.7, 25.0, 19.7, 9.2, 14.0
    ];
    final activeColor = isSent ? Colors.white : const Color(0xFF101010);
    final inactiveColor = isSent ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF878787);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => viewModel.toggleAudioPlay(msgId, url, duration),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSent ? Colors.white : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: isCurrentPlaying
                ? SvgPicture.string(
                    ChatSvgs.pauseIcon,
                    colorFilter: ColorFilter.mode(
                      isSent ? const Color(0xFF7C57FC) : Colors.black,
                      BlendMode.srcIn,
                    ),
                  )
                : SvgPicture.string(
                    ChatSvgs.playIcon,
                    colorFilter: ColorFilter.mode(
                      isSent ? const Color(0xFF7C57FC) : Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          height: 30,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(barHeights.length, (idx) {
                  final progressLimit = idx / barHeights.length;
                  final isActive = isCurrentPlaying && state.playbackProgress >= progressLimit;

                  return Container(
                    width: 3.5,
                    height: barHeights[idx],
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              if (isCurrentPlaying)
                Positioned(
                  left: state.playbackProgress * 160,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: isSent ? Colors.white : const Color(0xFF7C57FC),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isCurrentPlaying
                  ? '${(duration * state.playbackProgress).toInt()}s'
                  : '${duration}s',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 11,
                color: isSent ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: isSent ? 1.0 : 0.0,
              child: Icon(
                msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                size: 13,
                color: isSent
                    ? (msg['is_read'] == true ? Colors.white : Colors.white.withValues(alpha: 0.6))
                    : Colors.transparent,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: isCurrentPlaying ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isCurrentPlaying,
                child: GestureDetector(
                  onTap: viewModel.togglePlaybackSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSent ? Colors.white : const Color(0xFF7C57FC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${state.playbackSpeed.toStringAsFixed(1).replaceAll('.0', '')}x',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 9,
                        color: isSent ? const Color(0xFF7C57FC) : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSent = msg['sender_id'] == currentUserId;
    final type = msg['message_type'] ?? 'text';
    final content = msg['content'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: _getAvatarProvider(
                otherProfile['username'] ?? '',
                otherProfile['avatar_url'] as String?,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showDeleteMessageSheet(context, ref),
              child: Container(
                padding: type == 'text'
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    : type == 'image'
                        ? const EdgeInsets.all(2)
                        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSent
                      ? const Color(0xFF7C57FC)
                      : const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                ),
                child: type == 'text'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              content,
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: isSent ? Colors.white : const Color(0xFF303030),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (isSent) ...[
                            const SizedBox(width: 6),
                            Icon(
                              msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 14,
                              color: msg['is_read'] == true ? Colors.white : Colors.white.withValues(alpha: 0.6),
                            ),
                          ],
                        ],
                      )
                    : type == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 300,
                                    maxWidth: 250,
                                  ),
                                  child: Image.network(
                                    content,
                                    width: 250,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 250,
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                if (isSent)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : _buildAudioWaveform(context, ref, isSent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
