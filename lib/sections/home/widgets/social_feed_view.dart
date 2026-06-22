import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/story_tracker.dart';
import '../models/timeline_post.dart';
import '../models/user_story_group.dart';
import '../view_models/social_feed_view_model.dart';
import 'story_composer_screen.dart';
import 'story_viewer.dart';

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
      child: Column(
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
                  child: Stack(
                    children: [
                      // Background image: current user's profile image
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.grey[300],
                            child: widget.currentUserAvatarUrl != null && widget.currentUserAvatarUrl!.isNotEmpty
                                ? (widget.currentUserAvatarUrl!.startsWith('http')
                                    ? Image.network(widget.currentUserAvatarUrl!, fit: BoxFit.cover)
                                    : Image.asset(widget.currentUserAvatarUrl!, fit: BoxFit.cover))
                                : const Image(
                                    image: AssetImage('assets/home/images/avatar_placeholder.png'),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      // Dark semi-transparent overlay
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      // InkWell for taps
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
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
                                ).then((_) => ref.read(socialFeedViewModelProvider.notifier).refreshFeed());
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StoryComposerScreen(),
                                  ),
                                ).then((_) => ref.read(socialFeedViewModelProvider.notifier).refreshFeed());
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(height: 24),
                                  // Center: white circle with plus icon
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFF7C57FC),
                                      size: 20,
                                    ),
                                  ),
                                  // Bottom: "Create a story" text
                                  Text(
                                    'Create a story',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
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
                // Friends story cards
                ...state.storyGroups.where((g) => g.userId != currentUserId).map((group) {
                  final hasViewed = StoryTracker().isGroupViewed(group.mediaUrls);
                  final firstMediaUrl = group.mediaUrls.isNotEmpty ? group.mediaUrls.first : '';
                  return Container(
                    width: 110,
                    height: 150,
                    margin: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        // Background: first story media image
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: Colors.grey[200],
                              child: firstMediaUrl.isNotEmpty
                                  ? (firstMediaUrl.startsWith('http')
                                      ? Image.network(firstMediaUrl, fit: BoxFit.cover)
                                      : Image.asset(firstMediaUrl, fit: BoxFit.cover))
                                  : const Image(
                                      image: AssetImage('assets/home/images/avatar_placeholder.png'),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        // Dark overlay gradient (top and bottom)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.35),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // InkWell for taps
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
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
                                ).then((_) => ref.read(socialFeedViewModelProvider.notifier).refreshFeed());
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
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (widget.followedUsernames.isEmpty && state.showFindFriendsCard)
            _buildFindFriendsCard(),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C57FC),
                    ),
                  )
                : (widget.followedUsernames.isEmpty || state.socialPosts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: state.socialPosts.length,
                        itemBuilder: (context, index) {
                          return _buildSocialPostCard(state.socialPosts[index]);
                        },
                      )),
          ),
        ],
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

  Widget _buildSocialPostCard(TimelinePost post) {
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
                      const SizedBox(width: 6),
                      Text(
                        '•  ${post.postTime}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF82858C),
                          size: 20,
                        ),
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
                          post.locationAddress,
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
                if (post.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
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
