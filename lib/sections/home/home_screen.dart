import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../explore/explore_screen.dart';
import 'models/timeline_post.dart';
import 'models/timeline_state.dart';
import 'view_models/timeline_view_model.dart';
import 'view_models/collections_view_model.dart';
import 'view_models/social_feed_view_model.dart';
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
  double? _selectedExploreLat;
  double? _selectedExploreLng;
  String? _selectedExploreAddress;
  bool _isHeaderVisible = true;
  bool _isNavBarVisible = true;

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
      ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
    }
  }

  Widget _buildBody(TimelineState state) {
    return IndexedStack(
      index: state.selectedNavIndex,
      children: [
        _buildTimelineTab(state),
        ExploreScreen(
          userAvatarUrl: state.currentUserAvatarUrl,
          initialLatitude: _selectedExploreLat,
          initialLongitude: _selectedExploreLng,
          initialAddress: _selectedExploreAddress,
          onBackToTimeline: () {
            ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(0);
          },
        ),
        const NotificationsScreen(
          showBackButton: false,
        ),
        MessagesScreen(
          followedUsernames: state.followedUsernames,
          onFollowChanged: (username, isFollowed) {
            ref.read(timelineViewModelProvider.notifier).toggleFollow(username, isFollowed);
          },
          showBackButton: false,
        ),
      ],
    );
  }

  Widget _buildTimelineTab(TimelineState state) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isHeaderVisible ? 56.0 : 0.0,
              child: ClipRect(
                child: _buildHeader(state),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isHeaderVisible ? 8.0 : 0.0,
              child: const SizedBox(height: 8),
            ),
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
                onLocationTapped: (lat, lng, address) {
                  setState(() {
                    _selectedExploreLat = lat;
                    _selectedExploreLng = lng;
                    _selectedExploreAddress = address;
                  });
                  ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(1);
                },
              ),
            ),
          ],
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          right: 16,
          bottom: _isNavBarVisible ? 70 + bottomPadding : 20 + bottomPadding,
          child: _buildFAB(state),
        ),
        if (state.isFirstCheckIn && state.showCoachmark)
          FabCoachmarkOverlay(
            onTap: _startOnboardingFlow,
          ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineViewModelProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = 50.0 + bottomPadding;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (state.selectedNavIndex == 0) {
              if (notification is ScrollUpdateNotification) {
                final delta = notification.scrollDelta;
                if (delta != null) {
                  if (delta > 0.5) {
                    if (_isHeaderVisible || _isNavBarVisible) {
                      setState(() {
                        _isHeaderVisible = false;
                        _isNavBarVisible = false;
                      });
                    }
                  } else if (delta < -0.5) {
                    if (!_isHeaderVisible || !_isNavBarVisible) {
                      setState(() {
                        _isHeaderVisible = true;
                        _isNavBarVisible = true;
                      });
                    }
                  }
                }
                if (notification.metrics.pixels <= 0) {
                  if (!_isHeaderVisible || !_isNavBarVisible) {
                    setState(() {
                      _isHeaderVisible = true;
                      _isNavBarVisible = true;
                    });
                  }
                }
              } else if (notification is ScrollEndNotification) {
                if (notification.metrics.pixels <= 0) {
                  if (!_isHeaderVisible || !_isNavBarVisible) {
                    setState(() {
                      _isHeaderVisible = true;
                      _isNavBarVisible = true;
                    });
                  }
                } else {
                  if (!_isNavBarVisible) {
                    setState(() {
                      _isNavBarVisible = true;
                    });
                  }
                }
              }
            }
            return false;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildBody(state),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                bottom: _isNavBarVisible ? 0.0 : -navBarHeight,
                child: BottomNavBar(
                  selectedIndex: state.selectedNavIndex,
                  userAvatarUrl: state.currentUserAvatarUrl,
                  onItemTapped: (index) {
                    setState(() {
                      _isHeaderVisible = true;
                      _isNavBarVisible = true;
                      if (index != 1) {
                        _selectedExploreLat = null;
                        _selectedExploreLng = null;
                        _selectedExploreAddress = null;
                      }
                    });
                    ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TimelineState state) {
    return Container(
      color: Colors.white,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left aligned profile avatar
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _onAvatarTapped(state.posts),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE9E9E9),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: state.currentUserAvatarUrl != null && state.currentUserAvatarUrl!.isNotEmpty
                      ? (state.currentUserAvatarUrl!.startsWith('http')
                          ? Image.network(state.currentUserAvatarUrl!, fit: BoxFit.cover)
                          : Image.asset(state.currentUserAvatarUrl!, fit: BoxFit.cover))
                      : Image.asset(
                          'assets/home/images/avatar_placeholder.png',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
          // Centered logo
          SvgPicture.asset(
            'assets/Splash/logo.svg',
            height: 22,
            colorFilter: const ColorFilter.mode(
              Color(0xFF7C57FC),
              BlendMode.srcIn,
            ),
          ),
        ],
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
        decoration: const BoxDecoration(
          color: Color(0xFF7C57FC),
          shape: BoxShape.circle,
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
