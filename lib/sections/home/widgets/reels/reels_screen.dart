
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/timeline_post.dart';
import '../../../../data/repositories/post_repository_impl.dart';
import 'reels_item_widget.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBackToTimeline;
  const ReelsScreen({super.key, required this.onBackToTimeline});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  List<TimelinePost> _videoPosts = [];
  bool _isLoading = true;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVideoPosts();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  void _loadVideoPosts() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final posts = await ref.read(postRepositoryProvider).fetchPosts(currentUser?.id);
      
      final filtered = posts.where((post) {
        return post.imageUrls.any((url) => _isVideoFile(url));
      }).toList();

      if (mounted) {
        setState(() {
          _videoPosts = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching reels: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_videoPosts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    color: Colors.white30,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "لا يوجد أي ريلز حالياً",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              child: GestureDetector(
                onTap: widget.onBackToTimeline,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videoPosts.length,
            onPageChanged: (index) {
              setState(() {
                _focusedIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final post = _videoPosts[index];
              final videoUrl = post.imageUrls.firstWhere((url) => _isVideoFile(url));
              return ReelsItemWidget(
                post: post,
                videoUrl: videoUrl,
                isSelected: index == _focusedIndex,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            child: GestureDetector(
              onTap: widget.onBackToTimeline,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


