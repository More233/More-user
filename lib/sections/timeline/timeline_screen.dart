import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/timeline_post.dart';
import 'widgets/timeline_tab_bar.dart';
import 'widgets/timeline_post_card.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/share_bottom_sheet.dart';
import 'widgets/check_in_composer_screen.dart';
import 'widgets/fab_coachmark_overlay.dart';
import 'widgets/posting_loading_screen.dart';
import 'widgets/reward_dialog.dart';
import 'timeline_search_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _selectedTabIndex = 0;
  int _selectedNavIndex = 0;

  // Onboarding states
  bool _isFirstCheckIn = true;
  bool _showCoachmark = false;
  int _userCoins = 0;

  // Stateful list of timeline posts
  final List<TimelinePost> _posts = [];

  // Toggle Like state
  void _toggleLike(String postId) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        post.isLiked = !post.isLiked;
        post.likesCount += post.isLiked ? 1 : -1;
      }
    });
  }

  // Toggle Bookmark state
  void _toggleBookmark(String postId) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        post.isBookmarked = !post.isBookmarked;
      }
    });
  }

  // Open Comments Bottom Sheet
  void _openComments(TimelinePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          post: post,
          onCommentAdded: (comment) {
            setState(() {
              post.comments.add(comment);
              post.commentsCount = post.comments.length;
            });
          },
        );
      },
    );
  }

  // Open Share Bottom Sheet
  void _openShare(TimelinePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const ShareBottomSheet();
      },
    );
  }

  // Dismiss onboarding overlay and start the check-in composer
  void _startOnboardingFlow() {
    setState(() {
      _showCoachmark = false;
    });
    _openCheckInComposer(isFirstCheckIn: true);
  }

  // Open Check-in Composer
  void _openCheckInComposer({bool isFirstCheckIn = false}) async {
    final newPost = await Navigator.push<TimelinePost>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(isFirstCheckIn: isFirstCheckIn),
      ),
    );

    if (newPost != null) {
      _handlePostSubmission(newPost);
    }
  }

  // Handle post creation with loading overlay & reward claim popup
  void _handlePostSubmission(TimelinePost newPost) {
    // 1. Show posting loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PostingLoadingScreen(),
    );

    // 2. Wait 1.5 seconds, then dismiss loading and show reward popup
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading spinner

      // Show First Check-in Reward dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RewardDialog(
          locationName: newPost.title,
          onClaimTap: () {
            Navigator.pop(context); // Dismiss reward popup
            setState(() {
              _posts.insert(0, newPost);
              _isFirstCheckIn = false;
              _userCoins = 300;
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main Content Layout
            Column(
              children: [
                // Profile header with dynamic coin balance and page routes
                _buildHeader(),
                // Tab bar
                const SizedBox(height: 4),
                TimelineTabBar(
                  selectedIndex: _selectedTabIndex,
                  onTabChanged: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                ),
                const SizedBox(height: 20),
                // Feed list
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildTimelineFeed()
                      : _buildSocialFeed(),
                ),
              ],
            ),
            // Bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                selectedIndex: _selectedNavIndex,
                onItemTapped: (index) {
                  setState(() => _selectedNavIndex = index);
                },
              ),
            ),
            // FAB button
            Positioned(
              right: 16,
              bottom: 130,
              child: _buildFAB(),
            ),
            // Onboarding Coachmark Overlay
            if (_isFirstCheckIn && _showCoachmark)
              FabCoachmarkOverlay(
                onTap: _startOnboardingFlow,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userPosts: _posts),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(
                'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/image/Element.png',
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Coin badge showing live user coin state
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE9E9E9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/image/image 156.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_userCoins',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF464646),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Search button
          _buildActionButton(
            iconPath: 'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/icon/search-01.svg',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelineSearchScreen(
                    posts: _posts,
                    onLikeToggle: _toggleLike,
                    onBookmarkToggle: _toggleBookmark,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Notification button
          _buildActionButton(
            iconPath: 'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/icon/notification-02.svg',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String iconPath, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE9E9E9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFF464646),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineFeed() {
    if (_posts.isEmpty) {
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
      itemCount: _posts.length + 1, // +1 for the Today section title
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
        final post = _posts[postIndex];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TimelinePostCard(
            post: post,
            onLike: () => _toggleLike(post.id),
            onBookmark: () => _toggleBookmark(post.id),
            onComment: () => _openComments(post),
            onShare: () => _openShare(post),
            isLastInSection: postIndex == _posts.length - 1,
          ),
        );
      },
    );
  }

  Widget _buildSocialFeed() {
    return Center(
      child: Text(
        'Social feed coming soon',
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF82858C),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        if (_isFirstCheckIn) {
          setState(() {
            _showCoachmark = true;
          });
        } else {
          _openCheckInComposer();
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF7C57FC),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C57FC).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
