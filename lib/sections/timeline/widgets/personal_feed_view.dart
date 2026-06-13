import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timeline_post.dart';
import 'timeline_post_card.dart';

class PersonalFeedView extends StatelessWidget {
  final List<TimelinePost> posts;
  final Function(TimelinePost) onLike;
  final Function(TimelinePost) onBookmark;
  final Function(TimelinePost) onComment;
  final Function(TimelinePost) onShare;
  final Function(TimelinePost) onEdit;
  final Function(TimelinePost) onDelete;

  const PersonalFeedView({
    super.key,
    required this.posts,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 180),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 48,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No check-ins yet.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF82858C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the add button below to check in.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: const Color(0xFF82858C),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 160),
      itemCount: posts.length + 1, // +1 for the Today section title
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Today',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          );
        }

        final postIndex = index - 1;
        final post = posts[postIndex];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TimelinePostCard(
            post: post,
            onLike: () => onLike(post),
            onBookmark: () => onBookmark(post),
            onComment: () => onComment(post),
            onShare: () => onShare(post),
            onEdit: () => onEdit(post),
            onDelete: () => onDelete(post),
            isLastInSection: postIndex == posts.length - 1,
          ),
        );
      },
    );
  }
}
