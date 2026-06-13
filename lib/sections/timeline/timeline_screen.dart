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
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _fetchUserProfile();
  }

  Future<void> _fetchPosts() async {
    try {
      final client = Supabase.instance.client;
      final List<dynamic> response = await client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final List<TimelinePost> fetchedPosts = [];
      for (final postData in response) {
        final categoryName = postData['category_name'] as String? ?? 'Hotel';
        CategoryIconType catIcon = CategoryIconType.building;
        if (categoryName.toLowerCase() == 'coffee' || categoryName.toLowerCase() == 'cafe') {
          catIcon = CategoryIconType.coffee;
        } else if (categoryName.toLowerCase() == 'attraction' || categoryName.toLowerCase() == 'camera') {
          catIcon = CategoryIconType.camera;
        }

        String postTimeStr = 'Just now';
        final createdAtStr = postData['created_at'] as String?;
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null) {
            final difference = DateTime.now().difference(createdAt.toLocal());
            if (difference.inMinutes < 1) {
              postTimeStr = 'Just now';
            } else if (difference.inMinutes < 60) {
              postTimeStr = '${difference.inMinutes}m ago';
            } else if (difference.inHours < 24) {
              postTimeStr = '${difference.inHours}h ago';
            } else {
              postTimeStr = '${difference.inDays}d ago';
            }
          }
        }

        final taggedListRaw = postData['tagged_friends'];
        final List<String> tagged = [];
        if (taggedListRaw is List) {
          for (final t in taggedListRaw) {
            tagged.add(t.toString());
          }
        }

        fetchedPosts.add(
          TimelinePost(
            id: postData['id'] as String,
            title: postData['title'] as String? ?? '',
            categoryName: categoryName,
            locationAddress: postData['location_address'] as String? ?? '',
            visitorCount: postData['visitor_count'] as int? ?? 1,
            postTime: postTimeStr,
            description: postData['description'] as String? ?? '',
            imageUrl: postData['image_url'] as String?,
            likesCount: postData['likes_count'] as int? ?? 0,
            commentsCount: postData['comments_count'] as int? ?? 0,
            categoryIcon: catIcon,
            comments: [],
            isPrivate: postData['is_private'] as bool? ?? false,
            stickerIndex: postData['sticker_index'] as int? ?? -1,
            taggedFriends: tagged,
          ),
        );
      }

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
                      builder: (context) => ProfileScreen(userPosts: _posts),
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
                    onBookmarkToggle: _toggleBookmark,
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
