import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/timeline_post.dart';
import 'post_image_slider.dart';
import 'engagement_button.dart';
import 'dot_separator.dart';

class TimelinePostCard extends StatelessWidget {
  final TimelinePost post;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isLastInSection;

  const TimelinePostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onBookmark,
    this.onComment,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.isLastInSection = false,
  });

  String _getCategoryIconPath() {
    switch (post.categoryIcon) {
      case CategoryIconType.coffee:
        return 'assets/home/icons/coffee_02.svg';
      case CategoryIconType.building:
        return 'assets/home/icons/building_05.svg';
      case CategoryIconType.camera:
        return 'assets/home/icons/camera_01_1.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: icon + vertical line
          _buildTimelineIndicator(isDark),
          const SizedBox(width: 16),
          // Right side: post content
          Expanded(child: _buildPostContent(context, isDark)),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator(bool isDark) {
    return SizedBox(
      width: 34,
      child: Column(
        children: [
          // Category icon in circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2541) : const Color(0xFFF2EEFC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                _getCategoryIconPath(),
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF7C57FC),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          // Vertical line (if not last)
          if (!isLastInSection)
            Expanded(
              child: Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, bool isDark) {
    // Subtle text color adapted to dark/light
    final subtleColor = isDark
        ? Colors.white54
        : const Color(0xFF3B3C4F).withValues(alpha: 0.75);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post card header
          _buildPostHeader(isDark),
          const SizedBox(height: 4),
          // Details row
          _buildDetailsRow(subtleColor),
          const SizedBox(height: 4),
          // Time row
          _buildTimeRow(subtleColor),
          // Optional image
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            PostImageSlider(
              imageUrls: post.imageUrls,
              height: 172,
              width: 264,
            ),
          ],
          // Optional caption
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.description,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF3B3C4F),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Engagement row
          _buildEngagementRow(isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPostHeader(bool isDark) {
    return Container(
      height: 32,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
        Expanded(
          child: Text(
            post.shortTitle,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 141),
          color: const Color(0x99131116), // Dark semi-transparent (rgba(19, 17, 22, 0.6))
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit?.call();
            } else if (value == 'delete') {
              onDelete?.call();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'edit',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/home/icons/edit_02.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/home/icons/delete_03_1.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFDF0000),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: const Color(0xFFDF0000),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: SvgPicture.asset(
              'assets/home/icons/post_options.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isDark ? Colors.white54 : const Color(0xFF3B3C4F),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildDetailsRow(Color subtleColor) {
    return Row(
      children: [
        Text(
          post.categoryName,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subtleColor,
          ),
        ),
        const DotSeparator(),
        Flexible(
          child: Text(
            // Show place name as primary label; fall back to street address
            post.title.isNotEmpty ? post.shortTitle : post.shortLocationAddress,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: subtleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(Color subtleColor) {
    return Row(
      children: [
        Text(
          post.postTime,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subtleColor,
          ),
        ),
      ],
    );
  }


  Widget _buildEngagementRow(bool isDark) {
    return Row(
      children: [
        EngagementButton(
          iconPath:
              'assets/home/icons/like_icon.svg',
          count: post.likesCount,
          active: post.isLiked,
          onTap: onLike,
        ),
        const SizedBox(width: 16),
        EngagementButton(
          iconPath:
              'assets/home/icons/comment_icon.svg',
          count: post.commentsCount,
          active: false,
          onTap: onComment,
        ),
        const SizedBox(width: 16),
        EngagementButton(
          iconPath:
              'assets/home/icons/share_icon_1.svg',
          count: 0,
          active: false,
          onTap: onShare,
        ),
        const Spacer(),
        GestureDetector(
          onTap: onBookmark,
          child: SvgPicture.asset(
            'assets/home/icons/bookmark_icon.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              post.isBookmarked
                  ? const Color(0xFF7C57FC)
                  : (isDark ? Colors.white54 : const Color(0xFF5A5D67)),
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}


