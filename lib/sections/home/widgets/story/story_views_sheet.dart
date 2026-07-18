import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/story_view_state.dart';

class StoryViewsSheet extends StatelessWidget {
  final StoryViewState storyState;
  final String currentStoryId;
  final VoidCallback onDeletePressed;

  const StoryViewsSheet({
    super.key,
    required this.storyState,
    required this.currentStoryId,
    required this.onDeletePressed,
  });

  Widget _buildAvatarWithBadge(Map<String, dynamic> viewer) {
    final user = viewer['user'];
    final avatarUrl = user != null ? user['avatar_url'] as String? : null;
    final badge = viewer['badge'] as String?;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? (avatarUrl.startsWith('http')
                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                    : Image.asset(avatarUrl, fit: BoxFit.cover))
                : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Center(
                child: badge == 'heart'
                    ? Image.asset('assets/home/images/heart.png', fit: BoxFit.contain)
                    : Image.asset('assets/home/images/fire.png', fit: BoxFit.contain),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = storyState.viewers;
    final displayViewsCount = storyState.viewsCount;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/home/icons/user_multiple.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$displayViewsCount",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onDeletePressed();
                },
                child: SvgPicture.asset(
                  'assets/home/icons/delete_03.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFFFF453A), BlendMode.srcIn),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, thickness: 1),
          const SizedBox(height: 10),
          // Viewers list
          if (listToShow.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  "No views yet",
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white54),
                ),
              ),
            ),
          ] else ...[
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listToShow.length,
                itemBuilder: (context, index) {
                  final item = listToShow[index];
                  final viewer = item['user'];
                  if (viewer == null) return const SizedBox.shrink();
                  
                  final username = viewer['username'] as String? ?? 'unknown';
                  final fullName = '${viewer['first_name'] ?? ''} ${viewer['last_name'] ?? ''}'.trim();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        _buildAvatarWithBadge(item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (fullName.isNotEmpty)
                                Text(
                                  fullName,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF8E8E93)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Options for @$username")),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
