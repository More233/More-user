import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewerHeader extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final bool isOwner;
  final DateTime? createdTime;
  final VoidCallback onClose;

  const ViewerHeader({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.isOwner,
    required this.createdTime,
    required this.onClose,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey[800],
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!) as ImageProvider
              : const AssetImage('assets/home/images/avatar_placeholder.png'),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  isOwner ? "Your Story" : username,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      const Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (createdTime != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeAgo(createdTime!),
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: const Color(0xFFE1E1E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        const Shadow(
                          blurRadius: 4,
                          color: Colors.black45,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
      ],
    );
  }
}
