import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../models/timeline_post.dart';
import '../../../../data/repositories/post_repository_impl.dart';
import '../bottom_sheets/comments_bottom_sheet.dart';

class ReelsItemWidget extends ConsumerStatefulWidget {
  final TimelinePost post;
  final String videoUrl;
  final bool isSelected;

  const ReelsItemWidget({
    super.key,
    required this.post,
    required this.videoUrl,
    required this.isSelected,
  });

  @override
  ConsumerState<ReelsItemWidget> createState() => _ReelsItemWidgetState();
}

class _ReelsItemWidgetState extends ConsumerState<ReelsItemWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showPlayIcon = false;
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _initController();
  }

  void _initController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isSelected) {
          _controller!.play();
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading reel video: $e");
    }
  }

  @override
  void didUpdateWidget(covariant ReelsItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _isInitialized) {
      if (widget.isSelected && !oldWidget.isSelected) {
        _controller!.play();
        setState(() {
          _isPlaying = true;
        });
      } else if (!widget.isSelected && oldWidget.isSelected) {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isPlaying = false;
        _showPlayIcon = true;
      } else {
        _controller!.play();
        _isPlaying = true;
        _showPlayIcon = false;
      }
    });
  }

  void _handleLike() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    
    final newLiked = !_isLiked;
    setState(() {
      _isLiked = newLiked;
      _likesCount += newLiked ? 1 : -1;
    });

    try {
      await ref.read(postRepositoryProvider).toggleLike(
        postId: widget.post.id,
        userId: currentUser.id,
        isLiked: _isLiked,
      );
    } catch (e) {
      debugPrint("Error toggling like for reel: $e");
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          post: widget.post,
          onCommentAdded: (comment) {
            setState(() {
              widget.post.comments.add(comment);
              widget.post.commentsCount = widget.post.comments.length;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          if (_showPlayIcon)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

          // Right actions sidebar
          Positioned(
            bottom: 60,
            right: 16,
            child: Column(
              children: [
                // Heart icon
                GestureDetector(
                  onTap: _handleLike,
                  child: Column(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_likesCount',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Comment icon
                GestureDetector(
                  onTap: _openComments,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.post.commentsCount}',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Share icon
                GestureDetector(
                  onTap: () {
                    // share placeholder
                  },
                  child: Column(
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom-left info details
          Positioned(
            bottom: 40,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.post.authorAvatar != null
                          ? NetworkImage(widget.post.authorAvatar!)
                          : null,
                      child: widget.post.authorAvatar == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.authorName ?? 'Anonymous',
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.post.description,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.post.categoryName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.post.categoryName,
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.post.locationAddress.isNotEmpty) ...[
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.post.shortLocationAddress,
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
