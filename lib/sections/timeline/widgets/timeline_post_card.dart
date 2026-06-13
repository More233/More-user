import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timeline_post.dart';

class TimelinePostCard extends StatelessWidget {
  final TimelinePost post;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool isLastInSection;

  const TimelinePostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onBookmark,
    this.onComment,
    this.onShare,
    this.isLastInSection = false,
  });

  String _getCategoryIconPath() {
    switch (post.categoryIcon) {
      case CategoryIconType.coffee:
        return 'assets/Timeline/Personal Timeline  Default State/icon/coffee-02.svg';
      case CategoryIconType.building:
        return 'assets/Timeline/Personal Timeline  Default State/icon/building-05.svg';
      case CategoryIconType.camera:
        return 'assets/Timeline/Personal Timeline  Default State/icon/camera-01.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: icon + vertical line
          _buildTimelineIndicator(),
          const SizedBox(width: 16),
          // Right side: post content
          Expanded(child: _buildPostContent()),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return SizedBox(
      width: 34,
      child: Column(
        children: [
          // Category icon in circle
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF2EEFC),
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
                color: const Color(0xFFE0E0E0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFC8C8C8),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post card header
          _buildPostHeader(),
          const SizedBox(height: 8),
          // Details row
          _buildDetailsRow(),
          const SizedBox(height: 4),
          // Time row
          _buildTimeRow(),
          // Optional image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            _buildImage(),
          ],
          // Optional caption
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.description,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3B3C4F),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Engagement row
          _buildEngagementRow(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            post.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        SvgPicture.asset(
          'assets/Timeline/Personal Timeline  Default State/icon/Post Options.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFF3B3C4F),
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow() {
    return Row(
      children: [
        Text(
          post.categoryName,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
          ),
        ),
        const _DotSeparator(),
        Flexible(
          child: Text(
            post.locationAddress,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (post.visitorCount > 0) ...[
          const SizedBox(width: 8),
          _buildVisitorCount(),
        ],
      ],
    );
  }

  Widget _buildVisitorCount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/Timeline/Personal Timeline  Default State/image/image 156.png',
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 2),
        Text(
          '+${post.visitorCount}',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Text(
          post.postTime,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    final path = post.imageUrl!;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          path,
          width: 264,
          height: 172,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 264,
            height: 172,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    final isAsset = !path.startsWith('/') && !path.startsWith('file:');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isAsset
          ? Image.asset(
              path,
              width: 264,
              height: 172,
              fit: BoxFit.cover,
            )
          : Image.file(
              File(path),
              width: 264,
              height: 172,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildEngagementRow() {
    return Row(
      children: [
        _EngagementButton(
          iconPath:
              'assets/Timeline/Personal Timeline  Default State/icon/Like Icon.svg',
          count: post.likesCount,
          active: post.isLiked,
          onTap: onLike,
        ),
        const SizedBox(width: 16),
        _EngagementButton(
          iconPath:
              'assets/Timeline/Personal Timeline  Default State/icon/Comment Icon.svg',
          count: post.commentsCount,
          active: false,
          onTap: onComment,
        ),
        const SizedBox(width: 16),
        _EngagementButton(
          iconPath:
              'assets/Timeline/Personal Timeline  Default State/icon/Share Icon.svg',
          count: 0,
          active: false,
          onTap: onShare,
        ),
        const Spacer(),
        GestureDetector(
          onTap: onBookmark,
          child: SvgPicture.asset(
            'assets/Timeline/Personal Timeline  Default State/icon/Bookmark Icon.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              post.isBookmarked ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _EngagementButton extends StatelessWidget {
  final String iconPath;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  const _EngagementButton({
    required this.iconPath,
    required this.count,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              active ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
              BlendMode.srcIn,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF3B3C4F).withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
