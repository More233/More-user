import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ViewerOwnerBottomBar extends StatelessWidget {
  final String currentStoryId;
  final String currentMediaUrl;
  final List<Map<String, dynamic>> viewers;
  final ValueNotifier<bool> simulateViewsNotifier;
  final VoidCallback onActivityTap;
  final VoidCallback onHighlightTap;
  final VoidCallback onSendTap;
  final VoidCallback onMentionTap;
  final VoidCallback onMoreTap;
  final List<Map<String, dynamic>> Function() getMockViewers;

  const ViewerOwnerBottomBar({
    super.key,
    required this.currentStoryId,
    required this.currentMediaUrl,
    required this.viewers,
    required this.simulateViewsNotifier,
    required this.onActivityTap,
    required this.onHighlightTap,
    required this.onSendTap,
    required this.onMentionTap,
    required this.onMoreTap,
    required this.getMockViewers,
  });

  Widget _buildOverlappingAvatars(List<Map<String, dynamic>> viewersList) {
    final list = simulateViewsNotifier.value || viewersList.isNotEmpty 
        ? (viewersList.isNotEmpty ? viewersList : getMockViewers()) 
        : <Map<String, dynamic>>[];
        
    if (list.isEmpty) {
      return SvgPicture.asset(
        'assets/home/icons/user_multiple.svg',
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                        ? Image.network(avatarUrl, fit: BoxFit.cover)
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBarItem({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            child: Center(
              child: icon,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItem(
            icon: ValueListenableBuilder<bool>(
              valueListenable: simulateViewsNotifier,
              builder: (context, val, child) => _buildOverlappingAvatars(viewers),
            ),
            label: "Activity",
            onTap: onActivityTap,
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/like_icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: "Highlight",
            onTap: onHighlightTap,
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/sent.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: "Send",
            onTap: onSendTap,
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/at.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: "Mention",
            onTap: onMentionTap,
          ),
          _buildBottomBarItem(
            icon: SvgPicture.string(
              '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M4 7H20M4 12H20M4 17H20" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round"/>
              </svg>''',
              width: 24,
              height: 24,
            ),
            label: "More",
            onTap: onMoreTap,
          ),
        ],
      ),
    );
  }
}
