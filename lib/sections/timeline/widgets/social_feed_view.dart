import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timeline_post.dart';
import '../helpers/story_tracker.dart';
import 'story_viewer.dart';
import 'story_composer_screen.dart';

class SocialFeedView extends StatefulWidget {
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
  State<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<SocialFeedView> {
  bool _showFindFriendsCard = true;
  bool _isLoading = true;
  final List<TimelinePost> _socialPosts = [];
  final List<UserStoryGroup> _storyGroups = [];

  @override
  void initState() {
    super.initState();
    StoryTracker().init().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    _fetchSocialFeed();
    _fetchStories();
  }

  @override
  void didUpdateWidget(covariant SocialFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followedUsernames != oldWidget.followedUsernames) {
      _fetchSocialFeed();
      _fetchStories();
    }
  }

  Future<void> _fetchStories() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      // 1. Fetch followed user IDs
      final followsResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final userIds = List<Map<String, dynamic>>.from(followsResponse)
          .map((f) => f['following_id'] as String)
          .toList();

      // Include current user's ID
      userIds.add(currentUser.id);

      // 2. Fetch active stories from Supabase where expires_at > now()
      final storiesResponse = await client
          .from('stories')
          .select('*, user:profiles(id, username, first_name, last_name, avatar_url)')
          .inFilter('user_id', userIds)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: true);

      // 3. Group by user
      final Map<String, UserStoryGroup> grouped = {};
      for (var row in storiesResponse) {
        final user = row['user'];
        if (user == null) continue;

        final uId = user['id'] as String;
        final username = user['username'] as String? ?? 'unknown';
        final avatarUrl = user['avatar_url'] as String?;
        final mediaUrl = row['media_url'] as String;
        final createdAtStr = row['created_at'] as String;
        final createdAt = DateTime.parse(createdAtStr);
        final storyId = row['id'] as String;

        if (grouped.containsKey(uId)) {
          grouped[uId]!.mediaUrls.add(mediaUrl);
          grouped[uId]!.createdTimes.add(createdAt);
          grouped[uId]!.storyIds.add(storyId);
        } else {
          grouped[uId] = UserStoryGroup(
            userId: uId,
            username: username,
            avatarUrl: avatarUrl,
            mediaUrls: [mediaUrl],
            createdTimes: [createdAt],
            storyIds: [storyId],
          );
        }
      }

      if (mounted) {
        setState(() {
          _storyGroups.clear();
          _storyGroups.addAll(grouped.values);
        });
      }
    } catch (e) {
      debugPrint("Error fetching stories: $e");
    }
  }

  Future<void> _fetchSocialFeed() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      // 1. Fetch followed user IDs
      final followsResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = List<Map<String, dynamic>>.from(followsResponse)
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) {
        if (mounted) {
          setState(() {
            _socialPosts.clear();
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch user's liked post IDs to set isLiked correctly
      final likesResponse = await client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', currentUser.id);
      final likedPostIds = List<Map<String, dynamic>>.from(likesResponse)
          .map((l) => l['post_id'] as String)
          .toSet();

      // Fetch user's bookmarked post IDs
      final collectionsResponse = await client
          .from('collections')
          .select('id')
          .eq('user_id', currentUser.id);
      final collectionIds = List<Map<String, dynamic>>.from(collectionsResponse)
          .map((c) => c['id'] as String)
          .toList();
      Set<String> bookmarkedPostIds = {};
      if (collectionIds.isNotEmpty) {
        final collectionPostsResponse = await client
            .from('collection_posts')
            .select('post_id')
            .inFilter('collection_id', collectionIds);
        bookmarkedPostIds = List<Map<String, dynamic>>.from(collectionPostsResponse)
            .map((cp) => cp['post_id'] as String)
            .toSet();
      }

      // 2. Fetch posts of followed users
      final postsResponse = await client
          .from('posts')
          .select('*, author:profiles!posts_user_id_fkey(id, username, first_name, last_name, avatar_url)')
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false);

      final List<TimelinePost> fetchedPosts = List<Map<String, dynamic>>.from(postsResponse).map((postData) {
        final post = TimelinePost.fromMap(postData);
        return post.copyWith(
          isLiked: likedPostIds.contains(post.id),
          isBookmarked: bookmarkedPostIds.contains(post.id),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _socialPosts.clear();
          _socialPosts.addAll(fetchedPosts);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching social feed: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final currentUserGroup = _storyGroups.firstWhere(
      (g) => g.userId == Supabase.instance.client.auth.currentUser?.id,
      orElse: () => UserStoryGroup(userId: '', username: '', avatarUrl: '', mediaUrls: [], createdTimes: [], storyIds: []),
    );
    final hasOwnStory = currentUserGroup.userId.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchSocialFeed();
        await _fetchStories();
      },
      color: const Color(0xFF7C57FC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stories row
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Your Story Bubble
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (hasOwnStory) {
                                final index = _storyGroups.indexOf(currentUserGroup);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StoryViewer(
                                      storyGroups: _storyGroups,
                                      initialGroupIndex: index,
                                    ),
                                  ),
                                ).then((_) => _fetchStories());
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StoryComposerScreen(),
                                  ),
                                ).then((_) => _fetchStories());
                              }
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasOwnStory
                                      ? (StoryTracker().isGroupViewed(currentUserGroup.mediaUrls)
                                          ? const Color(0xFFE9E9E9)
                                          : const Color(0xFF7C57FC))
                                      : const Color(0xFFE9E9E9),
                                  width: hasOwnStory ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: widget.currentUserAvatarUrl != null &&
                                              widget.currentUserAvatarUrl!.isNotEmpty
                                          ? NetworkImage(widget.currentUserAvatarUrl!) as ImageProvider
                                          : const AssetImage(
                                              'assets/Timeline/images/avatar_placeholder.png',
                                            ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const StoryComposerScreen(),
                                  ),
                                ).then((_) => _fetchStories());
                              },
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

                // Followed user stories
                ..._storyGroups.where((g) => g.userId != Supabase.instance.client.auth.currentUser?.id).map((group) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        final index = _storyGroups.indexOf(group);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryViewer(
                              storyGroups: _storyGroups,
                              initialGroupIndex: index,
                            ),
                          ),
                        ).then((_) => _fetchStories());
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: StoryTracker().isGroupViewed(group.mediaUrls)
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF7C57FC), Color(0xFFFF57B9)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              border: StoryTracker().isGroupViewed(group.mediaUrls)
                                  ? Border.all(color: const Color(0xFFE9E9E9), width: 2)
                                  : null,
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
                                backgroundColor: Colors.grey[200],
                                backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                                    ? NetworkImage(group.avatarUrl!) as ImageProvider
                                    : const AssetImage(
                                        'assets/Timeline/images/avatar_placeholder.png',
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            group.username,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: const Color(0xFF5A5D67),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Find Friends Card
          if (widget.followedUsernames.isEmpty && _showFindFriendsCard)
            _buildFindFriendsCard(),

          // Feed Posts
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C57FC),
                    ),
                  )
                : (widget.followedUsernames.isEmpty || _socialPosts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: _socialPosts.length,
                        itemBuilder: (context, index) {
                          return _buildSocialPostCard(_socialPosts[index]);
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

  Widget _buildSocialPostCard(TimelinePost post) {
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
                backgroundColor: Colors.grey[200],
                backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                    ? (post.authorAvatar!.startsWith('http')
                        ? NetworkImage(post.authorAvatar!)
                        : AssetImage(post.authorAvatar!)) as ImageProvider
                    : const AssetImage('assets/Timeline/images/avatar_placeholder.png'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.authorName ?? 'unknown',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${post.postTime}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details row
          Row(
            children: [
              Text(
                post.categoryName,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  post.locationAddress,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (post.visitorCount > 0) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/Timeline/images/coin.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${post.visitorCount}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Caption/Description
          if (post.description.isNotEmpty) ...[
            Text(
              post.description,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: const Color(0xFF221F26),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Image
          if (post.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.imageUrl!,
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
          ],

          // Engagement buttons row exactly copying TimelinePostCard style
          Row(
            children: [
              _EngagementButton(
                iconPath: 'assets/Timeline/icons/like_icon.svg',
                count: post.likesCount,
                active: post.isLiked,
                onTap: () {
                  widget.onLike?.call(post);
                  setState(() {
                    post.isLiked = !post.isLiked;
                    post.likesCount += post.isLiked ? 1 : -1;
                  });
                },
              ),
              const SizedBox(width: 16),
              _EngagementButton(
                iconPath: 'assets/Timeline/icons/comment_icon.svg',
                count: post.commentsCount,
                active: false,
                onTap: () => widget.onComment?.call(post),
              ),
              const SizedBox(width: 16),
              _EngagementButton(
                iconPath: 'assets/Timeline/icons/share_icon_1.svg',
                count: 0,
                active: false,
                onTap: () => widget.onShare?.call(post),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  widget.onBookmark?.call(post);
                  setState(() {
                    post.isBookmarked = !post.isBookmarked;
                  });
                },
                child: SvgPicture.asset(
                  'assets/Timeline/icons/bookmark_icon.svg',
                  width: 20,
                  height: 20,
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
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              active ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
              BlendMode.srcIn,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
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
