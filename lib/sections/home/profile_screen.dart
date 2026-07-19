import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/common/bottom_nav_bar.dart';
import 'view_models/timeline_view_model.dart';
import 'view_models/notifications_view_model.dart';
import 'view_models/messages_view_model.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/timeline_post.dart';
import 'view_models/collections_view_model.dart';
import 'widgets/feed/timeline_post_card.dart';
import 'widgets/bottom_sheets/comments_bottom_sheet.dart';
import 'widgets/bottom_sheets/share_bottom_sheet.dart';
import 'widgets/bottom_sheets/save_to_list_bottom_sheet.dart';
import 'widgets/feed/check_in_composer_screen.dart';
import '../settings/screens/edit_profile_screen.dart';
import 'widgets/common/custom_loading_indicator.dart';
import 'followers_following_screen.dart';
import 'widgets/chat/conversation_screen.dart';
import 'widgets/common/cached_image.dart';
import 'package:cached_network_image/cached_network_image.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  final List<TimelinePost> userPosts;
  final VoidCallback? onPostUpdated;
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userPosts = const [],
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
  String _joinedDate = '';
  bool _isFollowing = false;
  bool _followLoading = false;
  bool _messageLoading = false;

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
        client
            .from('follows')
            .select()
            .eq('follower_id', currentUser.id)
            .eq('following_id', targetUserId)
            .maybeSingle(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final followersData = results[1] as List<dynamic>;
      final followingData = results[2] as List<dynamic>;
      final postsResponse = results[3] as List<dynamic>;
      final followCheck = results[4];
      final isFollowing = followCheck != null;

      if (profile != null) {
        _fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        _username = profile['username'] ?? '';
        _avatarUrl = profile['avatar_url'] as String?;
        _coverUrl = profile['cover_url'] as String?;

        final createdAtStr = profile['created_at'] as String?;
        if (createdAtStr != null) {
          final dt = DateTime.tryParse(createdAtStr);
          if (dt != null) {
            const months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            if (dt.month >= 1 && dt.month <= 12) {
              _joinedDate = 'Joined ${months[dt.month - 1]} ${dt.year}';
            }
          }
        }
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
          _isFollowing = isFollowing;
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


  void _viewProfilePicture() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Glassmorphic Backdrop Blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
              // Close on tap outside
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Pinch-to-zoom interactive viewer for the FULL IMAGE
              Center(
                child: Hero(
                  tag: 'user-avatar-fullscreen',
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: Image(
                        image: _getAvatarProvider(_username, _avatarUrl),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // Close button at top right (positioned very high)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          fileOptions: const FileOptions(cacheControl: '31536000', upsert: true),
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
        return CachedNetworkImageProvider(dbUrl);
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
        return ShareBottomSheet(post: post);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? const Color(0xFF1E2433) : Colors.white,
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
                    color: isDark ? Colors.white : const Color(0xFF323232),
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
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: isDark ? const Color(0xFF2C354A) : const Color(0xFFBFBFBF), width: 0.7),
                        bottom: BorderSide(color: isDark ? const Color(0xFF2C354A) : const Color(0xFFBFBFBF), width: 0.7),
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
                        color: isDark ? Colors.white70 : const Color(0xFF373737),
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

  Future<void> _toggleFollow() async {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    final targetUserId = widget.userId;
    if (currentUserId == null || targetUserId == null) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _followLoading = true;
    });

    try {
      if (_isFollowing) {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', targetUserId);

        setState(() {
          _isFollowing = false;
          _followersCount = (_followersCount - 1).clamp(0, 9999999);
        });
      } else {
        await client.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': targetUserId,
        });

        try {
          await client.from('notifications').insert({
            'user_id': targetUserId,
            'actor_id': currentUserId,
            'category': 'follow',
          });
        } catch (ne) {
          debugPrint("Error inserting follow notification: $ne");
        }

        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
      widget.onPostUpdated?.call();
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    } finally {
      setState(() {
        _followLoading = false;
      });
    }
  }

  Future<void> _openMessageConversation() async {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    final targetUserId = widget.userId;
    if (currentUserId == null || targetUserId == null) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _messageLoading = true;
    });

    try {
      final existingThreadResponse = await client
          .from('chat_threads')
          .select()
          .or('and(user1_id.eq.$currentUserId,user2_id.eq.$targetUserId),and(user1_id.eq.$targetUserId,user2_id.eq.$currentUserId)')
          .maybeSingle();

      String threadId;
      if (existingThreadResponse != null) {
        threadId = existingThreadResponse['id'] as String;
      } else {
        final insertResponse = await client.from('chat_threads').insert({
          'user1_id': currentUserId,
          'user2_id': targetUserId,
        }).select().single();
        threadId = insertResponse['id'] as String;
      }

      final otherProfile = await client
          .from('profiles')
          .select('id, username, avatar_url, first_name, last_name')
          .eq('id', targetUserId)
          .single();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            threadId: threadId,
            otherProfile: otherProfile,
            currentUserId: currentUserId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error opening message conversation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to open chat: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _messageLoading = false;
        });
      }
    }
  }

  Widget _buildGridImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CustomCachedImage(
        url: path,
        fit: BoxFit.cover,
        errorWidget: Container(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_profileLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const CustomLoadingIndicator(),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    widget.onPostUpdated?.call();
                  }
                } : () {},
                onShare: _pickCoverImage, // Note: preserved original functionality
                onCoverTap: isCurrentUser ? _pickCoverImage : () {},
                onAvatarTap: _viewProfilePicture,
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
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _username.isNotEmpty ? '@$_username' : '',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : const Color(0xFF687684),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.white60 : const Color(0xFF687684)),
                          const SizedBox(width: 6),
                          Text(
                            _joinedDate.isNotEmpty ? _joinedDate : 'Joined March 2021',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : const Color(0xFF687684),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Following / Followers
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final targetUserId = widget.userId ?? Supabase.instance.client.auth.currentUser?.id ?? '';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowersFollowingScreen(
                                    userId: targetUserId,
                                    username: _username,
                                    initialTabIndex: 1, // Following tab
                                  ),
                                ),
                              ).then((_) => _fetchProfileData());
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Text(
                                  '$_followingCount',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Following',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : const Color(0xFF687684),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              final targetUserId = widget.userId ?? Supabase.instance.client.auth.currentUser?.id ?? '';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowersFollowingScreen(
                                    userId: targetUserId,
                                    username: _username,
                                    initialTabIndex: 0, // Followers tab
                                  ),
                                ),
                              ).then((_) => _fetchProfileData());
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Text(
                                  '$_followersCount',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Followers',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : const Color(0xFF687684),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isCurrentUser) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _followLoading ? null : _toggleFollow,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _isFollowing
                                        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6))
                                        : const Color(0xFF7C57FC),
                                    borderRadius: BorderRadius.circular(100),
                                    border: _isFollowing
                                        ? Border.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB))
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: _followLoading
                                      ? const CupertinoActivityIndicator(
                                          color: Colors.grey,
                                          radius: 8,
                                        )
                                      : Text(
                                          _isFollowing ? 'Following' : 'Follow',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _isFollowing
                                                ? (isDark ? Colors.white : const Color(0xFF374151))
                                                : Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _messageLoading ? null : _openMessageConversation,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB)),
                                  ),
                                  alignment: Alignment.center,
                                  child: _messageLoading
                                      ? const CupertinoActivityIndicator(
                                          color: Color(0xFF7C57FC),
                                          radius: 8,
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.chat_bubble_outline,
                                              size: 16,
                                              color: isDark ? Colors.white : const Color(0xFF374151),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Message',
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF374151),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                      color: isDark ? Colors.white : Colors.black,
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
                Divider(height: 8, color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF6F6F6)),
                // My Timeline Feed Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'My Feed',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
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
                        child: RepaintBoundary(
                          key: ValueKey('profile_post_${post.id}'),
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
          unreadNotificationsCount: ref.watch(notificationsViewModelProvider).unreadCount,
          unreadMessagesCount: ref.watch(messagesViewModelProvider).threads.fold<int>(0, (sum, t) => sum + (t['unreadCount'] as int? ?? 0)),
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
                  ? CustomCachedImage(url: coverUrl!, fit: BoxFit.cover)
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
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
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
                // Cover Upload Icon
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
                      Icons.photo_camera_outlined,
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
