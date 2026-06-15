import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/timeline_post.dart';
import 'widgets/timeline_tab_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/share_bottom_sheet.dart';
import 'widgets/check_in_composer_screen.dart';
import 'widgets/fab_coachmark_overlay.dart';
import 'widgets/save_to_list_bottom_sheet.dart';
import 'widgets/messages_screen.dart';
import 'widgets/follow_friends_bottom_sheet.dart';
import 'widgets/personal_feed_view.dart';
import 'widgets/social_feed_view.dart';
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

  // Social Onboarding states
  final Set<String> _followedUsernames = {};

  // Stateful list of timeline posts
  final List<TimelinePost> _posts = [];
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchUserProfile();
    _fetchFollows();
    CollectionsManager().loadCollections();
  }

  Future<void> _fetchFollows() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final List<dynamic> response = await client
          .from('follows')
          .select('following_id, profiles!follows_following_id_fkey(username)')
          .eq('follower_id', currentUser.id);

      final List<String> followingUsernames = [];
      for (var row in response) {
        if (row['profiles'] != null && row['profiles']['username'] != null) {
          followingUsernames.add(row['profiles']['username'] as String);
        }
      }

      if (mounted) {
        setState(() {
          _followedUsernames.clear();
          _followedUsernames.addAll(followingUsernames);
        });
      }
    } catch (e) {
      debugPrint("Error fetching follows: $e");
    }
  }

  Future<void> _toggleFollow(String username, bool follow) async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final profileResponse = await client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (profileResponse == null) return;
      final followingId = profileResponse['id'] as String;

      if (follow) {
        await client.from('follows').upsert({
          'follower_id': currentUser.id,
          'following_id': followingId,
        });

        await _createNotification(
          receiverId: followingId,
          type: 'follow',
        );
      } else {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', currentUser.id)
            .eq('following_id', followingId);
      }
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    }
  }

  Future<void> _createNotification({
    required String receiverId,
    required String type,
    String? postId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;
      if (currentUser.id == receiverId) return;

      await client.from('notifications').insert({
        'sender_id': currentUser.id,
        'receiver_id': receiverId,
        'type': type,
        'post_id': postId,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint("Error creating notification: $e");
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;

      final List<dynamic> response = await client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      Set<String> likedPostIds = {};
      if (currentUser != null) {
        final likesResponse = await client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', currentUser.id);
        likedPostIds = List<Map<String, dynamic>>.from(likesResponse)
            .map((l) => l['post_id'] as String)
            .toSet();
      }

      Set<String> bookmarkedPostIds = {};
      if (currentUser != null) {
        final collectionsResponse = await client
            .from('collections')
            .select('id')
            .eq('user_id', currentUser.id);
        final collectionIds = List<Map<String, dynamic>>.from(collectionsResponse)
            .map((c) => c['id'] as String)
            .toList();
        if (collectionIds.isNotEmpty) {
          final collectionPostsResponse = await client
              .from('collection_posts')
              .select('post_id')
              .inFilter('collection_id', collectionIds);
          bookmarkedPostIds = List<Map<String, dynamic>>.from(collectionPostsResponse)
              .map((cp) => cp['post_id'] as String)
              .toSet();
        }
      }

      final List<TimelinePost> fetchedPosts = response
          .map((postData) {
            final post = TimelinePost.fromMap(postData as Map<String, dynamic>);
            return post.copyWith(
              isLiked: likedPostIds.contains(post.id),
              isBookmarked: bookmarkedPostIds.contains(post.id),
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _posts.clear();
          _posts.addAll(fetchedPosts);
          if (_posts.isNotEmpty) {
            _isFirstCheckIn = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching posts: $e");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final data = await client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && data['avatar_url'] != null && mounted) {
          setState(() {
            _currentUserAvatarUrl = data['avatar_url'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
  }



  void _onAvatarTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userPosts: _posts,
          onPostUpdated: () {
            _fetchPosts();
            _fetchUserProfile();
          },
        ),
      ),
    );
  }


  // Toggle Like state
  Future<void> _toggleLike(String postId) async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;
      final post = _posts[index];
      final isLikedNow = !post.isLiked;

      setState(() {
        post.isLiked = isLikedNow;
        post.likesCount += isLikedNow ? 1 : -1;
      });

      final postResponse = await client
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .maybeSingle();

      if (postResponse == null) return;
      final authorId = postResponse['user_id'] as String;

      if (isLikedNow) {
        await client.from('post_likes').insert({
          'post_id': postId,
          'user_id': currentUser.id,
        });

        await _createNotification(
          receiverId: authorId,
          type: 'like',
          postId: postId,
        );
      } else {
        await client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUser.id);
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  // Toggle Bookmark state (called by search/profile updates)
  Future<void> _updateBookmarkState(String postId, bool isBookmarked) async {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index].isBookmarked = isBookmarked;
      }
    });
    try {
      final client = Supabase.instance.client;
      await client.from('posts').update({'is_bookmarked': isBookmarked}).eq('id', postId);
    } catch (e) {
      debugPrint("Error updating bookmark state: $e");
    }
  }

  // Open Save to list Bottom Sheet
  void _openSaveToList(TimelinePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SaveToListBottomSheet(
          post: post,
          onSavedStateChanged: (isSaved) {
            _updateBookmarkState(post.id, isSaved);
          },
        );
      },
    );
  }

  Future<void> _handleBookmarkTap(TimelinePost post) async {
    final manager = CollectionsManager();
    if (!manager.isLoaded) {
      await manager.loadCollections();
    }

    if (post.isBookmarked) {
      _openSaveToList(post);
    } else {
      if (manager.collections.isEmpty) {
        try {
          final savedColId = await manager.getOrCreateSavedCollection();
          await manager.addPostToCollection(savedColId, post.id);
          await _updateBookmarkState(post.id, true);
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

  void _editPost(TimelinePost post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(
          editPost: post,
        ),
      ),
    );

    if (result == true) {
      _fetchPosts();
    }
  }

  void _confirmDeletePost(TimelinePost post) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete this check-in?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF323232),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Delete Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(post.id);
                  },
                  child: Container(
                    width: 286,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                        bottom: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Delete',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFD80000),
                      ),
                    ),
                  ),
                ),
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF373737),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      final client = Supabase.instance.client;
      await client.from('posts').delete().eq('id', postId);
      
      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Check-in deleted successfully."),
            backgroundColor: Color(0xFF7C57FC),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete check-in: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(isFirstCheckIn: isFirstCheckIn),
      ),
    );

    if (result == true) {
      _fetchPosts();
      setState(() {
        _isFirstCheckIn = false;
        _userCoins = 300;
      });
    }
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
                      ? PersonalFeedView(
                          posts: _posts,
                          onLike: (post) => _toggleLike(post.id),
                          onBookmark: _handleBookmarkTap,
                          onComment: _openComments,
                          onShare: _openShare,
                          onEdit: _editPost,
                          onDelete: _confirmDeletePost,
                        )
                      : SocialFeedView(
                          currentUserAvatarUrl: _currentUserAvatarUrl,
                          followedUsernames: _followedUsernames,
                          onAvatarTapped: _onAvatarTapped,
                          openFollowFriends: _openFollowFriends,
                          onLike: (post) => _toggleLike(post.id),
                          onBookmark: _handleBookmarkTap,
                          onComment: _openComments,
                          onShare: _openShare,
                        ),
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
            onTap: _onAvatarTapped,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: _currentUserAvatarUrl != null
                  ? NetworkImage(_currentUserAvatarUrl!) as ImageProvider
                  : const AssetImage(
                      'assets/Timeline/images/element.png',
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
                  'assets/Timeline/images/coin.png',
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
          if (_selectedTabIndex == 0) ...[
            // Search button
            _buildActionButton(
              iconPath: 'assets/Timeline/icons/search_01.svg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimelineSearchScreen(
                      posts: _posts,
                      onLikeToggle: _toggleLike,
                      onBookmarkToggle: _updateBookmarkState,
                      onPostUpdated: _fetchPosts,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Notification button
            _buildActionButton(
              iconPath: 'assets/Timeline/icons/notification_02.svg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ] else ...[
            _buildActionButton(
              iconPath: 'assets/Timeline/icons/chat_bubble_icon.svg',
              onTap: _openMessagesScreen,
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              iconPath: 'assets/Timeline/icons/add_friend_icon.svg',
              onTap: _openFollowFriends,
            ),
          ],
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



  void _openMessagesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreen(
          followedUsernames: _followedUsernames,
          onFollowChanged: (username, isFollowed) {
            setState(() {
              if (isFollowed) {
                _followedUsernames.add(username);
              } else {
                _followedUsernames.remove(username);
              }
            });
            _toggleFollow(username, isFollowed);
          },
        ),
      ),
    );
  }

  void _openFollowFriends() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FollowFriendsBottomSheet(
          followedUsernames: _followedUsernames,
          onFollowChanged: (username, isFollowed) {
            setState(() {
              if (isFollowed) {
                _followedUsernames.add(username);
              } else {
                _followedUsernames.remove(username);
              }
            });
            _toggleFollow(username, isFollowed);
          },
        );
      },
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


