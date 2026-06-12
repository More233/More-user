import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timeline_post.dart';

class CommentsBottomSheet extends StatefulWidget {
  final TimelinePost post;
  final Function(TimelineComment) onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.post,
    required this.onCommentAdded,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final comment = TimelineComment(
      authorName: 'sally.samer.3',
      authorAvatar: 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
      commentText: text,
      timeAgo: 'Just now',
    );

    widget.onCommentAdded(comment);
    _commentController.clear();
    setState(() {}); // refresh the sheet view
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen height and push sheet upwards when keyboard is open
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle slider
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFC8C8C8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Comments (${widget.post.comments.length})',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // List of comments
          Expanded(
            child: widget.post.comments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.post.comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Bottom Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No comments yet.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF82858C),
            ),
          ),
          Text(
            'Be the first to share your thoughts!',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              color: const Color(0xFF82858C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(TimelineComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(
              'assets/Timeline/Personal Timeline  Default State/image/Element.png',
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: const Color(0xFF82858C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.commentText,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF3B3C4F),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // reply action mock
                  },
                  child: Text(
                    'Reply',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Heart icon
          GestureDetector(
            onTap: () {
              setState(() {
                comment.isLiked = !comment.isLiked;
                if (comment.isLiked) {
                  comment.likesCount += 1;
                } else {
                  comment.likesCount -= 1;
                }
              });
            },
            child: Column(
              children: [
                Icon(
                  comment.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: comment.isLiked ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
                ),
                if (comment.likesCount > 0)
                  Text(
                    '${comment.likesCount}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 10,
                      color: const Color(0xFF5A5D67),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile avatar
          const CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage(
              'assets/Timeline/Personal Timeline  Default State/image/Element.png',
            ),
          ),
          const SizedBox(width: 12),
          // TextField
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Emoji button icon (placeholder)
                  Icon(
                    Icons.sentiment_satisfied_alt_outlined,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: _submitComment,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF7C57FC),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.send,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
