import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/social_post.dart';

class SocialFeedView extends StatefulWidget {
  final String? currentUserAvatarUrl;
  final Set<String> followedUsernames;
  final VoidCallback onAvatarTapped;
  final VoidCallback openFollowFriends;

  const SocialFeedView({
    super.key,
    required this.currentUserAvatarUrl,
    required this.followedUsernames,
    required this.onAvatarTapped,
    required this.openFollowFriends,
  });

  @override
  State<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<SocialFeedView> {
  bool _showFindFriendsCard = true;

  // Mock social posts for feed
  final List<SocialPost> _socialPosts = [
    SocialPost(
      authorName: 'Jordan Lee',
      authorAvatar: 'assets/Timeline/images/profile_image_1.png',
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
      authorAvatar: 'assets/Timeline/images/avatar.png',
      timeText: '1h',
      description: 'Stunning sunset view from the tower today! 🌅 The skyline looks incredible.',
      location: 'Kingdom Centre, Riyadh',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=600&auto=format&fit=crop',
      likes: 42,
      comments: 3,
      shares: 0,
    ),
  ];

  String _getAvatarAssetForUsername(String username) {
    switch (username.toLowerCase()) {
      case 'mayat':
        return 'assets/Timeline/images/profile_image_1.png';
      case 'jordanmarco':
        return 'assets/Timeline/images/profile_image2.png';
      case 'avaj':
        return 'assets/Timeline/images/avatar.png';
      case 'karennne':
        return 'assets/Timeline/images/avatar_placeholder.png';
      default:
        return 'assets/Timeline/images/avatar_placeholder.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stories
        _buildStoriesRow(),
        const SizedBox(height: 12),

        // Find Friends Card (if no friends followed and not dismissed)
        if (widget.followedUsernames.isEmpty && _showFindFriendsCard)
          _buildFindFriendsCard(),

        // Posts
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: widget.followedUsernames.isEmpty ? 0 : _socialPosts.length,
            itemBuilder: (context, index) {
              return _buildSocialPostCard(_socialPosts[index]);
            },
          ),
        ),
      ],
    );
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
                      onTap: widget.onAvatarTapped,
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
                          backgroundImage: widget.currentUserAvatarUrl != null
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
          ...widget.followedUsernames.map((username) {
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
            onTap: widget.openFollowFriends,
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
}
