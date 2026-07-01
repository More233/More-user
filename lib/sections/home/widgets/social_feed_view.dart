import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/story_tracker.dart';
import '../models/timeline_post.dart';
import 'post_image_slider.dart';
import '../models/user_story_group.dart';
import '../view_models/social_feed_view_model.dart';
import 'story_composer_screen.dart';
import 'story_viewer.dart';
import 'check_in_composer_screen.dart';
import 'die_cut_sticker.dart';

class SocialFeedView extends ConsumerStatefulWidget {
  final String? currentUserAvatarUrl;
  final Set<String> followedUsernames;
  final VoidCallback onAvatarTapped;
  final VoidCallback openFollowFriends;
  final Function(TimelinePost)? onLike;
  final Function(TimelinePost)? onComment;
  final Function(TimelinePost)? onShare;
  final Function(TimelinePost)? onBookmark;

  const SocialFeedView({
    super.key,
    required this.currentUserAvatarUrl,
    required this.followedUsernames,
    required this.onAvatarTapped,
    required this.openFollowFriends,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
  });

  @override
  ConsumerState<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends ConsumerState<SocialFeedView> {
  String _getStickerEmoji(int index) {
    if (index == 1) return "❤️";
    if (index == 2) return "🍺";
    if (index == 3) return "👏";
    if (index == 4) return "👍";
    if (index == 5) return "🔥";
    if (index == 6) return "😍";
    if (index == 7) return "➕";
    
    if (index >= 8) {
      final customIndex = index - 8;
      final customStickers = [
        '🥳', '😎', '⛈️', '❤️', '🐸', '🔥', '👋', '👍', '🍺', '⏰', '🚗', '🚕',
        '💄', '🧻', '🖼️', '💊', '⚾', '🚫', '🏁', '🥧', '🩹', '🛍️', '🍻', '🌲',
        '🛒', '🌵', '👮', '🛟', '🍦', '🥯', '🐶', '🕴️', '👠', '🥾', '🦕', '🏛️'
      ];
      if (customIndex < customStickers.length) {
        return customStickers[customIndex];
      }
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(socialFeedViewModelProvider.notifier).init();
    });
  }

  @override
  void didUpdateWidget(covariant SocialFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followedUsernames != oldWidget.followedUsernames) {
      ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialFeedViewModelProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final currentUserGroup = state.storyGroups.firstWhere(
      (g) => g.userId == currentUserId,
      orElse: () => UserStoryGroup(
        userId: '',
        username: '',
        avatarUrl: '',
        mediaUrls: [],
        createdTimes: [],
        storyIds: [],
      ),
    );
    final hasOwnStory = currentUserGroup.userId.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(socialFeedViewModelProvider.notifier).refreshFeed(),
      color: const Color(0xFF7C57FC),
      child: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C57FC),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 12, bottom: 120),
              itemCount: 1 + (state.socialPosts.isEmpty ? 1 : state.socialPosts.length),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 165,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Create story card (current user)
                            Container(
                              width: 110,
                              height: 150,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: hasOwnStory
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF7C57FC), Color(0xFFFF45B5), Color(0xFFFF805D)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    )
                                  : null,
                              padding: hasOwnStory ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(hasOwnStory ? 12.5 : 12),
                                  color: Colors.white,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(hasOwnStory ? 12.5 : 12),
                                  child: Stack(
                                    children: [
                                      // Background image: always current user's profile image
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.grey[300],
                                          child: widget.currentUserAvatarUrl != null && widget.currentUserAvatarUrl!.isNotEmpty
                                              ? (widget.currentUserAvatarUrl!.startsWith('http')
                                                  ? Image.network(widget.currentUserAvatarUrl!, fit: BoxFit.cover)
                                                  : Image.asset(widget.currentUserAvatarUrl!, fit: BoxFit.cover))
                                              : Image.asset(
                                                  'assets/home/images/avatar_placeholder.png',
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      // Dark overlay
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: hasOwnStory ? 0.45 : 0.35),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Content: Avatar + Name + Plus Icon
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              if (hasOwnStory) {
                                                final index = state.storyGroups.indexOf(currentUserGroup);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StoryViewer(
                                                      storyGroups: state.storyGroups,
                                                      initialGroupIndex: index,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const StoryComposerScreen(),
                                                  ),
                                                ).then((val) {
                                                  if (val == true) {
                                                    ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
                                                  }
                                                });
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  // Center: white circle with plus icon (only if no active story)
                                                  if (!hasOwnStory)
                                                    Align(
                                                      alignment: Alignment.topLeft,
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration: const BoxDecoration(
                                                          color: Colors.white,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.add,
                                                          color: Color(0xFF7C57FC),
                                                          size: 16,
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    const SizedBox.shrink(),
                                                  // Bottom: text
                                                  Text(
                                                    hasOwnStory ? 'Your Story' : 'Create a story',
                                                    style: GoogleFonts.ibmPlexSansArabic(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
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
                            // Friends story cards
                            ...state.storyGroups.where((g) => g.userId != currentUserId).map((group) {
                              final hasViewed = StoryTracker().isGroupViewed(group.mediaUrls);
                              return Container(
                                width: 110,
                                height: 150,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: hasViewed
                                      ? null
                                      : const LinearGradient(
                                          colors: [Color(0xFF7C57FC), Color(0xFFFF45B5), Color(0xFFFF805D)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                ),
                                padding: hasViewed ? EdgeInsets.zero : const EdgeInsets.all(2.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(hasViewed ? 15 : 12.5),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(hasViewed ? 15 : 12.5),
                                    child: Stack(
                                      children: [
                                        // Background: first story media image
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.grey[300],
                                            child: group.mediaUrls.isNotEmpty
                                                ? Image.network(
                                                    group.mediaUrls.first,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                                      'assets/home/images/element.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    'assets/home/images/element.png',
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                        // Dark overlay
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        // Tap target & display overlay
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                final index = state.storyGroups.indexOf(group);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StoryViewer(
                                                      storyGroups: state.storyGroups,
                                                      initialGroupIndex: index,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  setState(() {}); // Refresh border colors after viewing
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Top-left: User avatar with colorful border
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: hasViewed ? const Color(0xFFE9E9E9) : const Color(0xFF7C57FC),
                                                          width: 2,
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets.all(1.5),
                                                      child: CircleAvatar(
                                                        radius: 14,
                                                        backgroundColor: Colors.grey[200],
                                                        backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                                                            ? (group.avatarUrl!.startsWith('http')
                                                                ? NetworkImage(group.avatarUrl!)
                                                                : AssetImage(group.avatarUrl!)) as ImageProvider
                                                            : const AssetImage('assets/home/images/avatar_placeholder.png'),
                                                      ),
                                                    ),
                                                    // Bottom: Username
                                                    Text(
                                                      group.username,
                                                      style: GoogleFonts.ibmPlexSansArabic(
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
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
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.followedUsernames.isEmpty && state.showFindFriendsCard)
                        _buildFindFriendsCard(),
                    ],
                  );
                }

                if (state.socialPosts.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildSocialPostCard(state.socialPosts[index - 1]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No posts from friends yet',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
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
            onTap: widget.openFollowFriends,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref.read(socialFeedViewModelProvider.notifier).hideFindFriendsCard();
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

  void _editPost(TimelinePost post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(
          editPost: post,
        ),
      ),
    );

    if (result == true && mounted) {
      ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Check-in deleted successfully."),
            backgroundColor: Color(0xFF7C57FC),
          ),
        );
        ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
      }
    } catch (e) {
      debugPrint("Error deleting post: $e");
    }
  }

  Widget _buildSocialPostCard(TimelinePost post) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                ? (post.authorAvatar!.startsWith('http')
                    ? NetworkImage(post.authorAvatar!)
                    : AssetImage(post.authorAvatar!)) as ImageProvider
                : const AssetImage('assets/home/images/avatar_placeholder.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
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
                  Row(
                    children: [
                      Text(
                        post.authorName ?? 'unknown',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      if (post.stickerIndex != -1) ...[
                        const SizedBox(width: 6),
                        DieCutSticker(
                          emoji: _getStickerEmoji(post.stickerIndex),
                          size: 20,
                          strokeWidth: 4,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        '•  ${post.postTime}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                      const Spacer(),
                      if (post.authorId == currentUserId)
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF82858C),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 141),
                          color: const Color(0x99131116),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editPost(post);
                            } else if (value == 'delete') {
                              _confirmDeletePost(post);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/home/icons/edit_02.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/home/icons/delete_03_1.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFDF0000),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Color(0xFFDF0000),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (post.description.isNotEmpty) ...[
                    Text(
                      post.description,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13.5,
                        color: const Color(0xFF221F26),
                        height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (post.locationAddress.isNotEmpty) ...[
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/home/icons/location_01.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF7C57FC),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          post.shortLocationAddress,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF82858C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                  PostImageSlider(
                    imageUrls: post.imageUrls,
                    height: 180,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    _EngagementButton(
                      iconPath: 'assets/home/icons/like_icon.svg',
                      count: post.likesCount,
                      active: post.isLiked,
                      onTap: () {
                        ref.read(socialFeedViewModelProvider.notifier).toggleLikeLocal(post.id);
                        widget.onLike?.call(post);
                      },
                    ),
                    const SizedBox(width: 24),
                    _EngagementButton(
                      iconPath: 'assets/home/icons/comment_icon.svg',
                      count: post.commentsCount,
                      active: false,
                      onTap: () => widget.onComment?.call(post),
                    ),
                    const SizedBox(width: 24),
                    _EngagementButton(
                      iconPath: 'assets/home/icons/share_icon_1.svg',
                      count: 0,
                      active: false,
                      onTap: () => widget.onShare?.call(post),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        ref.read(socialFeedViewModelProvider.notifier).toggleBookmarkLocal(post.id);
                        widget.onBookmark?.call(post);
                      },
                      child: SvgPicture.asset(
                        'assets/home/icons/bookmark_icon.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          post.isBookmarked ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _EngagementButton extends StatelessWidget {
  final String iconPath;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  const _EngagementButton({
    required this.iconPath,
    required this.count,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              active ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
              BlendMode.srcIn,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
