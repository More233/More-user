import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../explore/explore_screen.dart';
import 'models/timeline_post.dart';
import 'models/timeline_state.dart';
import 'view_models/timeline_view_model.dart';
import 'view_models/collections_view_model.dart';
import 'view_models/social_feed_view_model.dart';
import 'notifications_screen.dart';
import 'view_models/notifications_view_model.dart';
import 'view_models/messages_view_model.dart';
import 'widgets/common/bottom_nav_bar.dart';
import 'widgets/feed/check_in_composer_screen.dart';
import 'widgets/bottom_sheets/comments_bottom_sheet.dart';
import 'widgets/common/fab_coachmark_overlay.dart';
import 'widgets/bottom_sheets/follow_friends_bottom_sheet.dart';
import 'widgets/chat/messages_screen.dart';
import 'widgets/common/custom_loading_indicator.dart';
import 'widgets/bottom_sheets/save_to_list_bottom_sheet.dart';
import 'widgets/bottom_sheets/share_bottom_sheet.dart';
import 'widgets/feed/social_feed_view.dart';
import 'widgets/common/user_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<MessagesScreenState> _messagesKey = GlobalKey<MessagesScreenState>();
  double? _selectedExploreLat;
  double? _selectedExploreLng;
  String? _selectedExploreAddress;
  bool _isHeaderVisible = true;
  bool _isNavBarVisible = true;

  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;
  bool _isMenuOpen = false;
  bool _canDrag = false;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    );
    
    Future.microtask(() {
      ref.read(timelineViewModelProvider.notifier).init();
      ref.read(collectionsViewModelProvider.notifier).init();
      ref.read(notificationsViewModelProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _onAvatarTapped() {
    HapticFeedback.lightImpact();
    if (_isMenuOpen) {
      _menuAnimationController.reverse();
      setState(() {
        _isMenuOpen = false;
      });
    } else {
      _menuAnimationController.forward();
      setState(() {
        _isMenuOpen = true;
      });
    }
  }

  void _onHorizontalDragStart(DragStartDetails details, int selectedNavIndex) {
    if (_isMenuOpen || selectedNavIndex == 0 || details.globalPosition.dx < 45.0) {
      _canDrag = true;
    } else {
      _canDrag = false;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_canDrag) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.76;
    _menuAnimationController.value += details.delta.dx / menuWidth;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_canDrag) return;
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity < -200) {
      // Swiped left quickly -> close
      _menuAnimationController.reverse();
      setState(() {
        _isMenuOpen = false;
      });
      return;
    } else if (velocity > 200) {
      // Swiped right quickly -> open
      _menuAnimationController.forward();
      setState(() {
        _isMenuOpen = true;
      });
      return;
    }

    if (_isMenuOpen) {
      // If it was already open, if they dragged it left at all (value < 0.85), close it
      if (_menuAnimationController.value < 0.85) {
        _menuAnimationController.reverse();
        setState(() {
          _isMenuOpen = false;
        });
      } else {
        _menuAnimationController.forward();
      }
    } else {
      // If it was closed, if they dragged it right past 0.25, open it
      if (_menuAnimationController.value > 0.25) {
        _menuAnimationController.forward();
        setState(() {
          _isMenuOpen = true;
        });
      } else {
        _menuAnimationController.reverse();
      }
    }
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
          onAvatarTapped: _onAvatarTapped,
        ),
        const NotificationsScreen(
          showBackButton: false,
        ),
        MessagesScreen(
          key: _messagesKey,
          followedUsernames: state.followedUsernames,
          onFollowChanged: (username, isFollowed) {
            ref.read(timelineViewModelProvider.notifier).toggleFollow(username, isFollowed);
          },
          showBackButton: false,
          onAvatarTapped: _onAvatarTapped,
        ),
      ],
    );
  }

  Widget _buildTimelineTab(TimelineState state) {
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
                onAvatarTapped: _onAvatarTapped,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.76;

    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        final slide = menuWidth * _menuAnimation.value;
        const scale = 1.0; // No scaling per user request

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF7F9FA), // Matches Drawer background color
          body: Stack(
            children: [
              // Under Layer: The Drawer Menu
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: menuWidth,
                child: Transform.translate(
                  offset: Offset((_menuAnimation.value - 1.0) * 80.0, 0.0), // Parallax effect
                  child: UserDrawer(
                    onProfileUpdated: () {
                      ref.read(timelineViewModelProvider.notifier).refreshAll();
                    },
                    onCloseMenu: () {
                      _menuAnimationController.reverse();
                      setState(() {
                        _isMenuOpen = false;
                      });
                    },
                  ),
                ),
              ),
              // Top Layer: The Main Content
              Transform.translate(
                offset: Offset(slide, 0.0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_menuAnimation.value * 64.0),
                      boxShadow: _menuAnimation.value > 0 ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15 * _menuAnimation.value), // deep outer shadow
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(-5, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07 * _menuAnimation.value), // soft inner shadow
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(-2, 0),
                        ),
                      ] : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_menuAnimation.value * 64.0), // 64px rounded corners
                      child: Stack(
                        children: [
                          GestureDetector(
                            onHorizontalDragStart: (state.selectedNavIndex == 0 || _isMenuOpen)
                                ? (details) => _onHorizontalDragStart(details, state.selectedNavIndex)
                                : null,
                            onHorizontalDragUpdate: (state.selectedNavIndex == 0 || _isMenuOpen)
                                ? (details) => _onHorizontalDragUpdate(details)
                                : null,
                            onHorizontalDragEnd: (state.selectedNavIndex == 0 || _isMenuOpen)
                                ? _onHorizontalDragEnd
                                : null,
                            child: Scaffold(
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
                                            ? const CustomLoadingIndicator()
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
                                          unreadNotificationsCount: ref.watch(notificationsViewModelProvider).unreadCount,
                                          unreadMessagesCount: ref.watch(messagesViewModelProvider).threads.fold<int>(0, (sum, t) => sum + (t['unreadCount'] as int? ?? 0)),
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
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                        right: 16,
                                        bottom: _isNavBarVisible ? 70 + bottomPadding : 20 + bottomPadding,
                                        child: IgnorePointer(
                                          ignoring: !(state.selectedNavIndex == 0 || state.selectedNavIndex == 3),
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 200),
                                            opacity: (state.selectedNavIndex == 0 || state.selectedNavIndex == 3) ? 1.0 : 0.0,
                                            child: _buildFAB(state),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Invisible gesture overlay on the right when menu is open to close menu on tap
              if (_isMenuOpen)
                Positioned(
                  left: slide,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _menuAnimationController.reverse();
                      setState(() {
                        _isMenuOpen = false;
                      });
                    },
                    onHorizontalDragStart: (details) => _onHorizontalDragStart(details, state.selectedNavIndex),
                    onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details),
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
              onTap: _onAvatarTapped,
              child: Hero(
                 tag: 'user-avatar',
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
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
        HapticFeedback.lightImpact();
        if (state.selectedNavIndex == 3) {
          _messagesKey.currentState?.showNewChatBottomSheet();
        } else {
          if (state.isFirstCheckIn) {
            ref.read(timelineViewModelProvider.notifier).setShowCoachmark(true);
          } else {
            _openCheckInComposer();
          }
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Color(0xFF7C57FC),
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: state.selectedNavIndex == 3
              ? const Icon(
                  CupertinoIcons.plus_bubble,
                  key: ValueKey('chat_icon'),
                  color: Colors.white,
                  size: 26,
                )
              : const Icon(
                  Icons.add,
                  key: ValueKey('add_icon'),
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
    );
  }
}
