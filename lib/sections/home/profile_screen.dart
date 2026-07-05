import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/bottom_nav_bar.dart';
import 'view_models/timeline_view_model.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/timeline_post.dart';
import 'view_models/collections_view_model.dart';
import 'widgets/timeline_post_card.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/share_bottom_sheet.dart';
import 'widgets/save_to_list_bottom_sheet.dart';
import 'widgets/check_in_composer_screen.dart';
import '../settings/edit_profile_screen.dart';
import 'widgets/custom_loading_indicator.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  final List<TimelinePost> userPosts;
  final VoidCallback? onPostUpdated;
  final String? userId;

  const ProfileScreen({
    super.key,
    required this.userPosts,
    this.onPostUpdated,
    this.userId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late List<TimelinePost> _posts;

  bool _profileLoading = true;
  String _fullName = '';
  String _username = '';
  String? _avatarUrl;
  String? _coverUrl;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _posts = List.from(widget.userPosts);
    Future.microtask(() {
      ref.read(collectionsViewModelProvider.notifier).init();
    });
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final targetUserId = widget.userId ?? currentUser.id;

      final results = await Future.wait<dynamic>([
        client
            .from('profiles')
            .select()
            .eq('id', targetUserId)
            .maybeSingle(),
        client
            .from('follows')
            .select('follower_id')
            .eq('following_id', targetUserId),
        client
            .from('follows')
            .select('following_id')
            .eq('follower_id', targetUserId),
        client
            .from('posts')
            .select('*, author:profiles!posts_user_id_fkey(id, username, first_name, last_name, avatar_url)')
            .eq('user_id', targetUserId)
            .order('created_at', ascending: false),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final followersData = results[1] as List<dynamic>;
      final followingData = results[2] as List<dynamic>;
      final postsResponse = results[3] as List<dynamic>;

      if (profile != null) {
        _fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        _username = profile['username'] ?? '';
        _avatarUrl = profile['avatar_url'] as String?;
        _coverUrl = profile['cover_url'] as String?;
      }

      _followersCount = followersData.length;
      _followingCount = followingData.length;

      final List<TimelinePost> userPostsList = [];
      for (var row in postsResponse) {
        userPostsList.add(TimelinePost.fromMap(row as Map<String, dynamic>));
      }
      _posts = userPostsList;



      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile data: $e");
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
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
            _avatarUrl = publicUrl;
          });
          widget.onPostUpdated?.call();
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

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        if (!mounted) return;

        setState(() {
          _profileLoading = true;
        });

        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) return;

        final file = File(image.path);
        final fileName = 'covers/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await client.storage.from('post-images').upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

        await client.from('profiles').update({
          'cover_url': publicUrl,
        }).eq('id', user.id);

        if (mounted) {
          setState(() {
            _coverUrl = publicUrl;
            _profileLoading = false;
          });
          widget.onPostUpdated?.call();
        }
      }
    } catch (e) {
      debugPrint("Error picking/uploading cover image: $e");
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update cover photo: $e")),
        );
      }
    }
  }


  ImageProvider _getAvatarProvider(String username, String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return NetworkImage(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    switch (username.toLowerCase()) {
      case 'mayat':
        return const AssetImage('assets/home/images/profile_image_1.png');
      case 'jordanmarco':
        return const AssetImage('assets/home/images/profile_image2.png');
      case 'avaj':
        return const AssetImage('assets/home/images/avatar.png');
      case 'karennne':
        return const AssetImage('assets/home/images/element.png');
      default:
        return const AssetImage('assets/home/images/element.png');
    }
  }

  void _toggleLike(TimelinePost post) {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
    });
    widget.onPostUpdated?.call();
  }

  Future<void> _updateBookmarkState(String postId, bool isBookmarked) async {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index].isBookmarked = isBookmarked;
      }
    });
    try {
      ref.read(collectionsViewModelProvider.notifier).updatePostBookmarkState(postId, isBookmarked);
    } catch (e) {
      debugPrint("Error updating bookmark state: $e");
    }
    widget.onPostUpdated?.call();
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
            _updateBookmarkState(post.id, isSaved);
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
            widget.onPostUpdated?.call();
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
      widget.onPostUpdated?.call();
      _fetchProfileData();
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
        widget.onPostUpdated?.call();
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

  Widget _buildGridImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    final isAsset = !path.startsWith('/') && !path.startsWith('file:');
    if (isAsset) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: CustomLoadingIndicator(),
      );
    }

    // Collect all image URLs from posts for the photo grid
    final photos = _posts
        .expand((post) => post.imageUrls)
        .toList();

    final isCurrentUser = widget.userId == null || widget.userId == Supabase.instance.client.auth.currentUser?.id;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final coverHeight = screenWidth / 3.6; // Wider aspect ratio (approx 3.6:1) to make the cover less tall
    final maxExtent = coverHeight + topPadding;
    final minExtent = topPadding + 56.0;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          HapticFeedback.lightImpact();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            // Pinned collapsing Twitter header
            SliverPersistentHeader(
              pinned: true,
              delegate: TwitterProfileHeaderDelegate(
                maxExtentVal: maxExtent,
                minExtentVal: minExtent,
                topPadding: topPadding,
                fullName: _fullName,
                username: _username,
                coverUrl: _coverUrl,
                postCount: _posts.length,
                avatarImageProvider: _getAvatarProvider(_username, _avatarUrl),
                onBack: () => Navigator.pop(context),
                onEdit: isCurrentUser ? () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                  if (updated == true) {
                    _fetchProfileData();
                  }
                } : () {},
                onShare: _pickCoverImage, // Note: preserved original functionality
                onCoverTap: isCurrentUser ? _pickCoverImage : () {},
                onAvatarTap: isCurrentUser ? _pickProfileImage : () {},
                isCurrentUser: isCurrentUser,
              ),
            ),
            // Profile details & contents
            SliverList(
              delegate: SliverChildListDelegate([
                // Profile details content (now directly in the list, no Stack/overlap needed here)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 52, 16, 0), // 52px top padding to leave room for the overlapping avatar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullName.isNotEmpty ? _fullName : 'No Name',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _username.isNotEmpty ? '@$_username' : '',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF687684),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Joined Date & Links (Static/Mocked matching Twitter)
                      Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Color(0xFF687684)),
                          const SizedBox(width: 4),
                          Text(
                            'facebook.com/abdullah.elawady',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF7C57FC),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF687684)),
                          const SizedBox(width: 6),
                          Text(
                            'Joined March 2021',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF687684),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Following / Followers
                      Row(
                        children: [
                          Text(
                            '$_followingCount',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Following',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF687684),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '$_followersCount',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Followers',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF687684),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Photos Grid Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'My Check-in Photos',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Photos Grid
                if (photos.isEmpty)
                  _buildEmptyPhotos()
                else
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildGridImage(photos[index]),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                const Divider(height: 8, color: Color(0xFFF6F6F6)),
                // My Timeline Feed Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'My Feed',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                // My timeline posts
                if (_posts.isEmpty)
                  _buildEmptyFeed()
                else
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TimelinePostCard(
                          post: post,
                          onLike: () => _toggleLike(post),
                          onBookmark: () => _handleBookmarkTap(post),
                          onComment: () => _openComments(post),
                          onShare: () => _openShare(post),
                          onEdit: () => _editPost(post),
                          onDelete: () => _confirmDeletePost(post),
                          isLastInSection: index == _posts.length - 1,
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ]),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: ref.watch(timelineViewModelProvider).selectedNavIndex,
          userAvatarUrl: _avatarUrl,
          onItemTapped: (index) {
            HapticFeedback.lightImpact();
            ref.read(timelineViewModelProvider.notifier).setSelectedNavIndex(index);
            Navigator.pop(context);
          },
        ),
        floatingActionButton: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckInComposerScreen(),
              ),
            ).then((_) => _fetchProfileData());
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
        ),
      ),
    );
  }

  Widget _buildEmptyPhotos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No photos checked in yet.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            color: const Color(0xFF82858C),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No posts added yet.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            color: const Color(0xFF82858C),
          ),
        ),
      ),
    );
  }
}

class TwitterProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double maxExtentVal;
  final double minExtentVal;
  final double topPadding;
  final String fullName;
  final String username;
  final String? coverUrl;
  final int postCount;
  final ImageProvider avatarImageProvider;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onCoverTap;
  final VoidCallback onAvatarTap;
  final bool isCurrentUser;

  TwitterProfileHeaderDelegate({
    required this.maxExtentVal,
    required this.minExtentVal,
    required this.topPadding,
    required this.fullName,
    required this.username,
    required this.coverUrl,
    required this.postCount,
    required this.avatarImageProvider,
    required this.onBack,
    required this.onEdit,
    required this.onShare,
    required this.onCoverTap,
    required this.onAvatarTap,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Dynamic button circle background styling (fades out as we collapse)
    final circleBgColor = Colors.black.withValues(alpha: (1.0 - progress) * 0.38);
    // Dynamic text color for header title (fades in as we collapse)
    final textColor = Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image / Fallback Purple (pinned and constrained to at least minExtent)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: (maxExtent - shrinkOffset).clamp(minExtent, double.infinity),
          child: GestureDetector(
            onTap: onCoverTap,
            child: Container(
              color: const Color(0xFF7C57FC),
              child: coverUrl != null && coverUrl!.isNotEmpty
                  ? Image.network(coverUrl!, fit: BoxFit.cover)
                  : null,
            ),
          ),
        ),
        // Title & Subtitle (fades in as we collapse)
        Positioned(
          left: 60,
          top: topPadding,
          bottom: 0,
          child: Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'No Name',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '$postCount posts',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Avatar (Circular, overlapping cover image, fades out as we collapse)
        Positioned(
          left: 16,
          top: maxExtent - 42 - shrinkOffset,
          child: Opacity(
            opacity: (1.0 - progress * 2.0).clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Hero(
                  tag: 'user-avatar',
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: avatarImageProvider,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Back Button
        Positioned(
          left: 16,
          top: topPadding + (56 - 36) / 2, // Centered in the 56px height toolbar
          child: GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: circleBgColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        // Actions (Edit, Share)
        if (isCurrentUser)
          Positioned(
            right: 16,
            top: topPadding + (56 - 36) / 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit Icon (Swapped: edit first, then share/upload)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: circleBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Share/Upload Icon
                GestureDetector(
                  onTap: onShare,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: circleBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.ios_share,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Bottom divider (fades in as we collapse)
        if (progress > 0.9)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: ((progress - 0.9) / 0.1).clamp(0.0, 1.0),
              child: const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFE1E8ED),
              ),
            ),
          ),
      ],
    );
  }

  @override
  double get maxExtent => maxExtentVal;

  @override
  double get minExtent => minExtentVal;

  @override
  bool shouldRebuild(covariant TwitterProfileHeaderDelegate oldDelegate) {
    return oldDelegate.maxExtentVal != maxExtentVal ||
        oldDelegate.minExtentVal != minExtentVal ||
        oldDelegate.fullName != fullName ||
        oldDelegate.username != username ||
        oldDelegate.coverUrl != coverUrl ||
        oldDelegate.postCount != postCount ||
        oldDelegate.avatarImageProvider != avatarImageProvider;
  }
}
