import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/timeline_post.dart';
import 'widgets/timeline_post_card.dart';
import 'widgets/comments_bottom_sheet.dart';
import 'widgets/share_bottom_sheet.dart';
import 'widgets/save_to_list_bottom_sheet.dart';
import 'widgets/check_in_composer_screen.dart';
import 'widgets/collection_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  final List<TimelinePost> userPosts;
  final VoidCallback? onPostUpdated;

  const ProfileScreen({
    super.key,
    required this.userPosts,
    this.onPostUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<TimelinePost> _posts;

  bool _collectionsLoading = true;

  @override
  void initState() {
    super.initState();
    _posts = List.from(widget.userPosts);
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() => _collectionsLoading = true);
    await CollectionsManager().loadCollections();
    if (mounted) {
      setState(() => _collectionsLoading = false);
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
      final client = Supabase.instance.client;
      await client.from('posts').update({'is_bookmarked': isBookmarked}).eq('id', postId);
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
      setState(() {});
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
    // Collect all image URLs from posts for the photo grid
    final photos = _posts
        .where((post) => post.imageUrl != null)
        .map((post) => post.imageUrl!)
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            // Profile Card Info
            _buildProfileHeader(context, _posts.length),
            const Divider(height: 8, color: Color(0xFFF6F6F6)),
            _buildCollectionsSection(),
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

  Widget _buildCollectionsSection() {
    if (_collectionsLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7C57FC),
          ),
        ),
      );
    }

    final collections = CollectionsManager().collections;
    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'My Collections',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final col = collections[index];
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CollectionDetailsScreen(
                        collectionId: col.id,
                        collectionName: col.name,
                        onRefresh: () {
                          _loadCollections();
                        },
                      ),
                    ),
                  );
                  _loadCollections();
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: col.coverImageUrl != null
                            ? Image.network(
                                col.coverImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFolderPlaceholder(),
                              )
                            : _buildFolderPlaceholder(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        col.name,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${col.postIds.length} items',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFolderPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.folder_rounded,
          color: Color(0xFF7C57FC),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, int postsCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(
                  'assets/Timeline/images/element.png',
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('$postsCount', 'Posts'),
                    _buildStatItem('250', 'Followers'),
                    _buildStatItem('180', 'Following'),
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
                  'Abdallah Al-Awady',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coffee enthusiast & Explorer ☕️✨',
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
                      'assets/Timeline/images/coin.png',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '200 Coins',
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
