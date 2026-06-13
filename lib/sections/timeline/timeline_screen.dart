import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'models/timeline_post.dart';
import 'widgets/timeline_tab_bar.dart';
import 'widgets/timeline_post_card.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/share_bottom_sheet.dart';
import 'widgets/check_in_composer_screen.dart';
import 'widgets/fab_coachmark_overlay.dart';
import 'widgets/save_to_list_bottom_sheet.dart';
import 'widgets/messages_screen.dart';
import 'widgets/follow_friends_bottom_sheet.dart';
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
  bool _showFindFriendsCard = true;
  final Set<String> _followedUsernames = {};

  // Stateful list of timeline posts
  final List<TimelinePost> _posts = [];
  String? _currentUserAvatarUrl;

  // Mock social posts for feed
  final List<SocialPost> _socialPosts = [
    SocialPost(
      authorName: 'Jordan Lee',
      authorAvatar: 'assets/Timeline/Story/image/Profile Image.png',
      timeText: '35min',
      description: 'Coffee date and great conversations. ☕️✨\nNothing like a slow morning to set the tone.',
      location: 'Atmosphere Coffee Shop, Riyadh',
      imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=600&auto=format&fit=crop',
      likes: 27,
      comments: 1,
      shares: 1,
    ),
    SocialPost(
      authorName: 'Ava Johnson',
      authorAvatar: 'assets/Timeline/Story/image/Avatar.png',
      timeText: '1h',
      description: 'Stunning sunset view from the tower today! 🌅 The skyline looks incredible.',
      location: 'Kingdom Centre, Riyadh',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop',
      likes: 42,
      comments: 3,
      shares: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchUserProfile();
    CollectionsManager().loadCollections();
  }

  Future<void> _fetchPosts() async {
    try {
      final client = Supabase.instance.client;
      final List<dynamic> response = await client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final List<TimelinePost> fetchedPosts = response
          .map((postData) => TimelinePost.fromMap(postData as Map<String, dynamic>))
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

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 12),
              Text("Uploading profile photo..."),
            ],
          )),
        );

        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) return;

        final file = File(image.path);
        final fileName = 'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await client.storage.from('post-images').upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

        await client.from('profiles').update({
          'avatar_url': publicUrl,
        }).eq('id', user.id);

        if (mounted) {
          setState(() {
            _currentUserAvatarUrl = publicUrl;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile photo updated successfully!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking/uploading profile image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile photo: $e")),
        );
      }
    }
  }

  void _onAvatarTapped() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFF7C57FC)),
                title: Text(
                  'View Profile',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userPosts: _posts,
                        onPostUpdated: _fetchPosts,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF7C57FC)),
                title: Text(
                  'Change Profile Photo',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }


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
            onTap: _onAvatarTapped,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: _currentUserAvatarUrl != null
                  ? NetworkImage(_currentUserAvatarUrl!) as ImageProvider
                  : const AssetImage(
                      'assets/Timeline/Personal Timeline  Default State/image/Element.png',
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
                  'assets/Timeline/Personal Timeline  Default State/image/image 156.png',
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
              iconPath: 'assets/Timeline/Personal Timeline  Default State/icon/search-01.svg',
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
              iconPath: 'assets/Timeline/Personal Timeline  Default State/icon/notification-02.svg',
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
              iconPath: 'assets/Timeline/Social Onboarding/chat_bubble_icon.svg',
              onTap: _openMessagesScreen,
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              iconPath: 'assets/Timeline/Social Onboarding/add_friend_icon.svg',
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
            onBookmark: () => _handleBookmarkTap(post),
            onComment: () => _openComments(post),
            onShare: () => _openShare(post),
            onEdit: () => _editPost(post),
            onDelete: () => _confirmDeletePost(post),
            isLastInSection: postIndex == _posts.length - 1,
          ),
        );
      },
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
          },
        );
      },
    );
  }

  Widget _buildSocialFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stories
        _buildStoriesRow(),
        const SizedBox(height: 12),

        // Find Friends Card (if no friends followed and not dismissed)
        if (_followedUsernames.isEmpty && _showFindFriendsCard)
          _buildFindFriendsCard(),

        // Posts
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: _followedUsernames.isEmpty ? 0 : _socialPosts.length,
            itemBuilder: (context, index) {
              return _buildSocialPostCard(_socialPosts[index]);
            },
          ),
        ),
      ],
    );
  }

  String _getAvatarAssetForUsername(String username) {
    switch (username.toLowerCase()) {
      case 'mayat':
        return 'assets/Timeline/Story/image/Profile Image.png';
      case 'jordanmarco':
        return 'assets/Timeline/Story/image/Profile Image2.png';
      case 'avaj':
        return 'assets/Timeline/Story/image/Avatar.png';
      case 'karennne':
        return 'assets/Timeline/Personal Timeline  Default State/image/Element.png';
      default:
        return 'assets/Timeline/Personal Timeline  Default State/image/Element.png';
    }
  }

  Widget _buildStoriesRow() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Your Story
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _onAvatarTapped,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE9E9E9), width: 1),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _currentUserAvatarUrl != null
                              ? NetworkImage(_currentUserAvatarUrl!) as ImageProvider
                              : const AssetImage(
                                  'assets/Timeline/Personal Timeline  Default State/image/Element.png',
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Story',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF5A5D67),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Followed stories
          ..._followedUsernames.map((username) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C57FC), Color(0xFFFF57B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage(_getAvatarAssetForUsername(username)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    username,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: const Color(0xFF5A5D67),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFindFriendsCard() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openFollowFriends,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EEFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: Color(0xFF7C57FC),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find friends to follow',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Friends of friends and your contacts',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: const Color(0xFF82858C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _showFindFriendsCard = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialPostCard(SocialPost post) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8E8E8),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(post.authorAvatar),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${post.timeText}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF82858C)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Caption/Description
          Text(
            post.description,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF221F26),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF7C57FC),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  post.location,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7C57FC),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              post.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Engagement buttons
          Row(
            children: [
              // Like
              GestureDetector(
                onTap: () {
                  setState(() {
                    post.isLiked = !post.isLiked;
                    post.likes += post.isLiked ? 1 : -1;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likes}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: post.isLiked ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Comment
              GestureDetector(
                onTap: () {
                  // Open comments
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF82858C),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.comments}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: const Color(0xFF82858C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Share
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF82858C),
                      size: 20,
                    ),
                    if (post.shares > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${post.shares}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),

              // Bookmark
              GestureDetector(
                onTap: () {
                  setState(() {
                    post.isBookmarked = !post.isBookmarked;
                  });
                },
                child: Icon(
                  post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: post.isBookmarked ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
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

class SocialPost {
  final String authorName;
  final String authorAvatar;
  final String timeText;
  final String description;
  final String location;
  final String imageUrl;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  bool isBookmarked;

  SocialPost({
    required this.authorName,
    required this.authorAvatar,
    required this.timeText,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}
