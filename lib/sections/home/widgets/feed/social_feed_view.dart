import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/story_tracker.dart';
import '../../helpers/story_preloader.dart';
import 'package:video_player/video_player.dart';
import '../../models/timeline_post.dart';
import 'post_image_slider.dart';
import 'engagement_button.dart';
import '../../models/user_story_group.dart';
import '../../view_models/social_feed_view_model.dart';
import '../story/story_composer_screen.dart';
import '../story/story_viewer.dart';
import 'check_in_composer_screen.dart';
import '../../profile_screen.dart';
import '../common/custom_loading_indicator.dart';

class SocialFeedView extends ConsumerStatefulWidget {
  final String? currentUserAvatarUrl;
  final Set<String> followedUsernames;
  final VoidCallback onAvatarTapped;
  final VoidCallback openFollowFriends;
  final Function(TimelinePost)? onLike;
  final Function(TimelinePost)? onComment;
  final Function(TimelinePost)? onShare;
  final Function(TimelinePost)? onBookmark;
  final Function(double lat, double lng, String address)? onLocationTapped;

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
    this.onLocationTapped,
  });

  @override
  ConsumerState<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends ConsumerState<SocialFeedView> {

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

    ref.listen(socialFeedViewModelProvider, (previous, next) {
      if (previous?.storyGroups != next.storyGroups) {
        HomeStoryPreloader.instance.preloadFeedStories(context, next.storyGroups);
      }
    });

    final currentUserGroup = state.storyGroups.firstWhere(
      (g) => g.userId == currentUserId,
      orElse: () => UserStoryGroup(
        userId: '',
        username: '',
        avatarUrl: '',
        mediaUrls: [],
        createdTimes: [],
        storyIds: [],
        overlays: [],
      ),
    );
    final hasOwnStory = currentUserGroup.userId.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(socialFeedViewModelProvider.notifier).refreshFeed(),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 165,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                     if (!hasOwnStory)
                      Container(
                        width: 110,
                        height: 150,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF2F2F7),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: widget.currentUserAvatarUrl != null && widget.currentUserAvatarUrl!.isNotEmpty
                                          ? (widget.currentUserAvatarUrl!.startsWith('http')
                                              ? NetworkImage(widget.currentUserAvatarUrl!)
                                              : AssetImage(widget.currentUserAvatarUrl!)) as ImageProvider
                                          : const AssetImage('assets/home/images/avatar_placeholder.png'),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C57FC),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: Text(
                                'Add story',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  color: const Color(0xFF82858C),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
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
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 110,
                        height: 150,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF2F2F7),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: Colors.grey[300],
                                  child: currentUserGroup.mediaUrls.isNotEmpty
                                      ? (_isVideoFile(currentUserGroup.mediaUrls.first)
                                          ? VideoThumbnailPreview(videoUrl: currentUserGroup.mediaUrls.first)
                                          : Image.network(
                                              currentUserGroup.mediaUrls.first,
                                              fit: BoxFit.cover,
                                            ))
                                      : widget.currentUserAvatarUrl != null && widget.currentUserAvatarUrl!.isNotEmpty
                                          ? (widget.currentUserAvatarUrl!.startsWith('http')
                                              ? Image.network(widget.currentUserAvatarUrl!, fit: BoxFit.cover)
                                              : Image.asset(widget.currentUserAvatarUrl!, fit: BoxFit.cover))
                                          : Image.asset(
                                              'assets/home/images/avatar_placeholder.png',
                                              fit: BoxFit.cover,
                                            ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.35),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF7C57FC),
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(1.5),
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: widget.currentUserAvatarUrl != null && widget.currentUserAvatarUrl!.isNotEmpty
                                        ? (widget.currentUserAvatarUrl!.startsWith('http')
                                            ? NetworkImage(widget.currentUserAvatarUrl!)
                                            : AssetImage(widget.currentUserAvatarUrl!)) as ImageProvider
                                        : const AssetImage('assets/home/images/avatar_placeholder.png'),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  'Your Story',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      final index = state.storyGroups.indexOf(currentUserGroup);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryViewer(
                                            storyGroups: state.storyGroups,
                                            initialGroupIndex: index,
                                          ),
                                        ),
                                      ).then((_) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
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
                                        ? (_isVideoFile(group.mediaUrls.first)
                                            ? VideoThumbnailPreview(videoUrl: group.mediaUrls.first)
                                            : Image.network(
                                                group.mediaUrls.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                                  'assets/home/images/element.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ))
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
              const SizedBox(height: 8),
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFE8E8E8),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (state.isLoading && state.socialPosts.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: CustomLoadingIndicator(),
          )
        else if (state.socialPosts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 12, bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildSocialPostCard(state.socialPosts[index]);
                },
                childCount: state.socialPosts.length,
              ),
            ),
          ),
      ],
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userPosts: const [],
                        userId: post.authorId,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                      ? (post.authorAvatar!.startsWith('http')
                          ? NetworkImage(post.authorAvatar!)
                          : AssetImage(post.authorAvatar!)) as ImageProvider
                      : const AssetImage('assets/home/images/avatar_placeholder.png'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    height: 32,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userPosts: const [],
                                  userId: post.authorId,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            post.authorName ?? 'unknown',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•  ${post.postTime}',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: const Color(0xFF82858C),
                            height: 1.0,
                          ),
                        ),
                        const Spacer(),
                        if (post.authorId == currentUserId)
                          PopupMenuButton<String>(
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
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.more_vert,
                                color: Color(0xFF82858C),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (post.locationAddress.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () async {
                        if (post.latitude != null && post.longitude != null && widget.onLocationTapped != null) {
                          widget.onLocationTapped!(post.latitude!, post.longitude!, post.shortLocationAddress);
                        } else {
                          final String query = (post.latitude != null && post.longitude != null)
                              ? '${post.latitude},${post.longitude}'
                              : post.locationAddress;
                          final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
                          final uri = Uri.tryParse(googleMapsUrl);
                          if (uri != null) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (post.description.isNotEmpty) ...[
                    Text(
                      post.description,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13.5,
                        color: const Color(0xFF221F26),
                        height: 1.4,
                      ),
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
                    EngagementButton(
                      iconPath: 'assets/home/icons/like_icon.svg',
                      count: post.likesCount,
                      active: post.isLiked,
                      iconSize: 18.0,
                      fontSize: 13.0,
                      spacing: 6.0,
                      onTap: () {
                        ref.read(socialFeedViewModelProvider.notifier).toggleLikeLocal(post.id);
                        widget.onLike?.call(post);
                      },
                    ),
                    const SizedBox(width: 24),
                    EngagementButton(
                      iconPath: 'assets/home/icons/comment_icon.svg',
                      count: post.commentsCount,
                      active: false,
                      iconSize: 18.0,
                      fontSize: 13.0,
                      spacing: 6.0,
                      onTap: () => widget.onComment?.call(post),
                    ),
                    const SizedBox(width: 24),
                    EngagementButton(
                      iconPath: 'assets/home/icons/share_icon_1.svg',
                      count: 0,
                      active: false,
                      iconSize: 18.0,
                      fontSize: 13.0,
                      spacing: 6.0,
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
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    const Divider(
      height: 1,
      thickness: 0.8,
      color: Color(0xFFE8E8E8),
    ),
    const SizedBox(height: 16),
  ],
);
  }
}

bool _isVideoFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
}

class VideoThumbnailPreview extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailPreview({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailPreview> createState() => _VideoThumbnailPreviewState();
}

class _VideoThumbnailPreviewState extends State<VideoThumbnailPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing video thumbnail: $e");
    }
  }

  @override
  void didUpdateWidget(covariant VideoThumbnailPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _isInitialized = false;
      _initController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C57FC)),
        ),
      ),
    );
  }
}


