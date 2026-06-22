import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../explore/explore_screen.dart';
import 'models/timeline_post.dart';
import 'models/timeline_state.dart';
import 'view_models/timeline_view_model.dart';
import 'view_models/collections_view_model.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/check_in_composer_screen.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/fab_coachmark_overlay.dart';
import 'widgets/follow_friends_bottom_sheet.dart';
import 'widgets/messages_screen.dart';
import 'widgets/save_to_list_bottom_sheet.dart';
import 'widgets/share_bottom_sheet.dart';
import 'widgets/social_feed_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timelineViewModelProvider.notifier).init();
      ref.read(collectionsViewModelProvider.notifier).init();
    });
  }

  void _onAvatarTapped(List<TimelinePost> posts) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userPosts: posts,
          onPostUpdated: () {
            ref.read(timelineViewModelProvider.notifier).refreshAll();
          },
        ),
      ),
    );
  }

  void _openSaveToList(TimelinePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SaveToListBottomSheet(
          post: post,
          onSavedStateChanged: (isSaved) {
            ref.read(timelineViewModelProvider.notifier).updateBookmarkState(post.id, isSaved);
          },
        );
      },
    );
  }

  Future<void> _handleBookmarkTap(TimelinePost post) async {
    final notifier = ref.read(collectionsViewModelProvider.notifier);
    final colState = ref.read(collectionsViewModelProvider);

    if (post.isBookmarked) {
      _openSaveToList(post);
    } else {
      if (colState.collections.isEmpty) {
        try {
          final savedColId = await notifier.getOrCreateSavedCollection();
          await notifier.addPostToCollection(savedColId, post.id);
          ref.read(timelineViewModelProvider.notifier).updateBookmarkState(post.id, true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Saved to Saved list"),
                backgroundColor: Color(0xFF7C57FC),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error auto-saving post: $e");
        }
      } else {
        _openSaveToList(post);
      }
    }
  }

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

  void _startOnboardingFlow() {
    ref.read(timelineViewModelProvider.notifier).startOnboardingFlow();
    _openCheckInComposer(isFirstCheckIn: true);
  }

  void _openCheckInComposer({bool isFirstCheckIn = false}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(isFirstCheckIn: isFirstCheckIn),
      ),
    );

    if (result == true) {
      ref.read(timelineViewModelProvider.notifier).loadPosts();
      ref.read(timelineViewModelProvider.notifier).completeFirstCheckIn();
    }
  }

  Widget _buildBody(TimelineState state) {
    switch (state.selectedNavIndex) {
      case 0:
        return Stack(
          children: [
            Column(
              children: [
                _buildHeader(state),
                const SizedBox(height: 8),
                Expanded(
                  child: SocialFeedView(
                    currentUserAvatarUrl: state.currentUserAvatarUrl,
                    followedUsernames: state.followedUsernames,
                    onAvatarTapped: () => _onAvatarTapped(state.posts),
                    openFollowFriends: () => _openFollowFriends(state.followedUsernames),
                    onLike: (post) => ref.read(timelineViewModelProvider.notifier).toggleLike(post.id),
                    onBookmark: _handleBookmarkTap,
                    onComment: _openComments,
                    onShare: _openShare,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 130,
              child: _buildFAB(state),
            ),
            if (state.isFirstCheckIn && state.showCoachmark)
              FabCoachmarkOverlay(
                onTap: _startOnboardingFlow,
              ),
          ],
        );
      case 1:
        return ExploreScreen(
          userAvatarUrl: state.currentUserAvatarUrl,
          onBackToTimeline: () {
            ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(0);
          },
        );
      case 2:
        return _buildBookingPlaceholder();
      case 3:
        return _buildOrderPlaceholder();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBookingPlaceholder() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE6FC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF7C57FC),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Bookings Yet",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Explore places on the map to book your next dining experience, sports session, or hotel stay.",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF82858C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(1);
            },
            child: Container(
              height: 48,
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF7C57FC),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(
                "Explore Places",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPlaceholder() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE6FC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF7C57FC),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Active Orders",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Place orders at your favorite cafes and restaurants to view their status here.",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF82858C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(1);
            },
            child: Container(
              height: 48,
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF7C57FC),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(
                "Explore Places",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(state),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                selectedIndex: state.selectedNavIndex,
                onItemTapped: (index) {
                  ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TimelineState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onAvatarTapped(state.posts),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: state.currentUserAvatarUrl != null
                  ? NetworkImage(state.currentUserAvatarUrl!) as ImageProvider
                  : const AssetImage(
                      'assets/home/images/element.png',
                    ),
            ),
          ),
          const SizedBox(width: 10),
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
                  'assets/home/images/coin.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 5),
                Text(
                  '${state.userCoins}',
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
          _buildActionButton(
            iconPath: 'assets/home/icons/chat_bubble_icon.svg',
            onTap: () => _openMessagesScreen(state.followedUsernames),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            iconPath: 'assets/home/icons/notification_02.svg',
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

  void _openMessagesScreen(Set<String> followedUsernames) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreen(
          followedUsernames: followedUsernames,
          onFollowChanged: (username, isFollowed) {
            ref.read(timelineViewModelProvider.notifier).toggleFollow(username, isFollowed);
          },
        ),
      ),
    );
  }

  void _openFollowFriends(Set<String> followedUsernames) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FollowFriendsBottomSheet(
          followedUsernames: followedUsernames,
          onFollowChanged: (username, isFollowed) {
            ref.read(timelineViewModelProvider.notifier).toggleFollow(username, isFollowed);
          },
        );
      },
    );
  }

  Widget _buildFAB(TimelineState state) {
    return GestureDetector(
      onTap: () {
        if (state.isFirstCheckIn) {
          ref.read(timelineViewModelProvider.notifier).setShowCoachmark(true);
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
