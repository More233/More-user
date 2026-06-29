import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'story_composer_screen.dart';

class ReelsScreen extends StatefulWidget {
  final VoidCallback onBackToTimeline;
  const ReelsScreen({super.key, required this.onBackToTimeline});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _discAnimationController;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _reelsData = [
    {
      'username': 'abdallah_99',
      'avatarUrl': null,
      'category': 'Coffee & Bakery',
      'location': 'Key Cafe, Riyadh',
      'description': 'Checking out the new specialty coffee spot in Riyadh! ☕️✨ The vibe is absolutely premium.',
      'songName': 'Original Audio - abdallah_99',
      'likes': 1240,
      'comments': 84,
      'coverUrl': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=800&q=80',
      'isLiked': false,
    },
    {
      'username': 'sarah_travels',
      'avatarUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
      'category': 'Restaurant',
      'location': 'Villa Palma, Riyadh',
      'description': 'Best Italian dinner in town! 🍝 The truffle pasta is a must-try.',
      'songName': 'Lofi Study Beats - Aesthetic Sound',
      'likes': 3405,
      'comments': 230,
      'coverUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
      'isLiked': true,
    },
    {
      'username': 'ahmed_foodie',
      'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
      'category': 'Desserts',
      'location': 'Over Jar, Riyadh',
      'description': 'Chocolate injection chocolate heaven! 🍫🤤 Share this with a chocolate lover.',
      'songName': 'Summer Vibes - Pop Beats',
      'likes': 892,
      'comments': 45,
      'coverUrl': 'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?auto=format&fit=crop&w=800&q=80',
      'isLiked': false,
    }
  ];

  @override
  void initState() {
    super.initState();
    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _discAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onCameraPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryComposerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical PageView for Reels
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reelsData.length,
            itemBuilder: (context, index) {
              final reel = _reelsData[index];
              return _buildReelItem(reel);
            },
          ),

          // Top Header Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.onBackToTimeline,
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Text(
                  'Reels',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _onCameraPressed,
                  child: SvgPicture.asset(
                    'assets/home/icons/camera_01.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelItem(Map<String, dynamic> reel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Reel Background Image (Simulating video)
        Image.network(
          reel['coverUrl'] as String,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          },
        ),

        // Gradient Dark Overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),

        // Center Play Icon Placeholder
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white70,
              size: 40,
            ),
          ),
        ),

        // 2. Right Actions Sidebar
        Positioned(
          bottom: 120,
          right: 16,
          child: Column(
            children: [
              // Like Action
              _buildSidebarAction(
                icon: reel['isLiked'] as bool ? Icons.favorite : Icons.favorite_border,
                label: '${reel['likes']}',
                iconColor: reel['isLiked'] as bool ? Colors.red : Colors.white,
                onTap: () {
                  setState(() {
                    reel['isLiked'] = !(reel['isLiked'] as bool);
                    reel['likes'] = (reel['likes'] as int) + (reel['isLiked'] as bool ? 1 : -1);
                  });
                },
              ),
              const SizedBox(height: 20),

              // Comment Action
              _buildSidebarAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${reel['comments']}',
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // Share Action
              _buildSidebarAction(
                icon: Icons.near_me_outlined,
                label: 'Share',
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // Audio Spinning Disc
              RotationTransition(
                turns: _discAnimationController,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF333333), Colors.black],
                    ),
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF7C57FC),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Bottom Text Overlay Details
        Positioned(
          bottom: 120,
          left: 16,
          right: 70, // leave space for sidebar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info (avatar + name + follow)
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: reel['avatarUrl'] != null
                        ? NetworkImage(reel['avatarUrl'] as String)
                        : const AssetImage('assets/home/images/element.png') as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reel['username'] as String,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white60, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Follow',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                reel['description'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              // Place Category & Location Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C57FC).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      reel['category'] as String,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      reel['location'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Music scrolling name simulation
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reel['songName'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarAction({
    required IconData icon,
    required String label,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.25),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
