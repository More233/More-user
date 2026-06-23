import 'dart:io';
import 'package:flutter/material.dart';
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
import 'widgets/saved_screen.dart';
import '../auth/auth_flow_page.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final List<TimelinePost> userPosts;
  final VoidCallback? onPostUpdated;

  const ProfileScreen({
    super.key,
    required this.userPosts,
    this.onPostUpdated,
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
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  int _coins = 0;

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

      // 1. Fetch profile info
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profile != null) {
        _fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        _username = profile['username'] ?? '';
        _avatarUrl = profile['avatar_url'] as String?;
      }

      // 2. Fetch followers count
      final followersData = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUser.id);
      _followersCount = (followersData as List).length;

      // 3. Fetch following count
      final followingData = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);
      _followingCount = (followingData as List).length;

      // 4. Fetch posts
      final postsResponse = await client
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(id, username, first_name, last_name, avatar_url)')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final List<TimelinePost> userPostsList = [];
      for (var row in postsResponse as List) {
        userPostsList.add(TimelinePost.fromMap(row as Map<String, dynamic>));
      }
      _posts = userPostsList;
      _postsCount = userPostsList.length;

      // 5. Coins calculation
      _coins = _postsCount > 0 ? 300 : 0;

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

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
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
                  'Sign out of your account?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF323232),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Sign Out Button
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
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
                      'Sign Out',
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
                  onTap: () => Navigator.pop(context, false),
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

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthFlowPage()),
          (route) => false,
        );
      } catch (e) {
        debugPrint("Error signing out: $e");
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
          _postsCount = _posts.length;
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
    // Collect all image URLs from posts for the photo grid
    final photos = _posts
        .expand((post) => post.imageUrls)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedScreen(),
                ),
              );
              if (mounted) {
                ref.read(collectionsViewModelProvider.notifier).loadCollections();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            // Profile Card Info
            _buildProfileHeader(context, _posts.length),
            const Divider(height: 8, color: Color(0xFFF6F6F6)),
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
          ],
        ),
      ),
    );
  }



  Widget _buildProfileHeader(BuildContext context, int postsCount) {
    if (_profileLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7C57FC),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _getAvatarProvider(_username, _avatarUrl),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$_postsCount', 'Posts'),
                    _buildStatItem('$_followersCount', 'Followers'),
                    _buildStatItem('$_followingCount', 'Following'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // User name and Bio
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName.isNotEmpty ? _fullName : 'No Name',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _username.isNotEmpty ? '@$_username' : '',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF3B3C4F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Coin and edit profile row
          Row(
            children: [
              // Coin Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/home/images/coin.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_coins Coins',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF464646),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Edit Profile Button (Mock)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC8C8C8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B3C4F),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12,
            color: const Color(0xFF82858C),
          ),
        ),
      ],
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
