import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewerOwnerBottomBar extends StatelessWidget {
  final String currentStoryId;
  final String currentMediaUrl;
  final List<Map<String, dynamic>> viewers;
  final VoidCallback onActivityTap;
  final VoidCallback onDeleteTap;

  const ViewerOwnerBottomBar({
    super.key,
    required this.currentStoryId,
    required this.currentMediaUrl,
    required this.viewers,
    required this.onActivityTap,
    required this.onDeleteTap,
  });

  Widget _buildOverlappingAvatars(List<Map<String, dynamic>> viewersList) {
    final list = viewersList;
        
    if (list.isEmpty) {
      return const Icon(
        Icons.remove_red_eye_outlined,
        color: Colors.white,
        size: 24,
      );
    }
    
    final displayViewers = list.take(3).toList();
    return SizedBox(
      width: 24.0 + (displayViewers.length - 1) * 12.0,
      height: 24,
      child: Stack(
        children: List.generate(displayViewers.length, (index) {
          final viewer = displayViewers[index]['user'];
          final avatarUrl = viewer != null ? viewer['avatar_url'] as String? : null;
          
          return Positioned(
            left: index * 12.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (avatarUrl.startsWith('http')
                        ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover))
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = viewers;
    final int viewCount = list.length;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Horizontal View Activity indicators
          GestureDetector(
            onTap: onActivityTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOverlappingAvatars(viewers),
                const SizedBox(width: 10),
                Text(
                  "$viewCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Delete button (only red assets/home/icons/delete_03.svg icon, no text)
          GestureDetector(
            onTap: onDeleteTap,
            behavior: HitTestBehavior.opaque,
            child: SvgPicture.asset(
              'assets/home/icons/delete_03.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(Color(0xFFFF453A), BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}
