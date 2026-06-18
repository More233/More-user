import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/timeline_post.dart';
import 'reward_dialog.dart';

class PostingLoadingScreen extends StatefulWidget {
  final TimelinePost newPost;
  final List<String> selectedImages;
  final String? currentUserAvatarUrl;

  const PostingLoadingScreen({
    super.key,
    required this.newPost,
    required this.selectedImages,
    this.currentUserAvatarUrl,
  });

  @override
  State<PostingLoadingScreen> createState() => _PostingLoadingScreenState();
}

class _PostingLoadingScreenState extends State<PostingLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  bool _taskCompleted = false;
  bool _animationCompleted = false;
  TimelinePost? _savedPost;

  @override
  void initState() {
    super.initState();
    
    // Smooth progress bar animation over 2.5 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationCompleted = true;
        _checkCompletionAndNavigate();
      }
    });

    _progressController.forward();
    _startPostingTask();
  }

  Future<String?> _uploadImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return null;
      }
      
      final client = Supabase.instance.client;
      final fileName = '${client.auth.currentUser?.id}/${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}';
      
      await client.storage.from('post-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading image to Supabase: $e");
      return null;
    }
  }

  Future<void> _startPostingTask() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception("No authenticated user");

      // Upload image if selected and is not an asset
      String? publicImageUrl;
      if (widget.selectedImages.isNotEmpty) {
        final localPath = widget.selectedImages.first;
        if (localPath.startsWith('assets/')) {
          publicImageUrl = localPath;
        } else {
          publicImageUrl = await _uploadImage(localPath);
        }
      }

      // Insert post into Supabase 'posts' table
      final response = await client.from('posts').insert({
        'user_id': currentUserId,
        'title': widget.newPost.title,
        'category_name': widget.newPost.categoryName,
        'location_address': widget.newPost.locationAddress,
        'description': widget.newPost.description,
        'image_url': publicImageUrl,
        'is_private': widget.newPost.isPrivate,
        'sticker_index': widget.newPost.stickerIndex,
        'tagged_friends': widget.newPost.taggedFriends,
        'latitude': widget.newPost.latitude,
        'longitude': widget.newPost.longitude,
        'place_id': widget.newPost.placeId,
      }).select().single();

      final String insertedId = response['id'] as String;



      _savedPost = widget.newPost.copyWith(
        id: insertedId,
        imageUrl: publicImageUrl,
      );

      _taskCompleted = true;
      _checkCompletionAndNavigate();
    } catch (e) {
      debugPrint("Error in posting task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post: ${e.toString()}")),
        );
        Navigator.pop(context); // Go back to composer
      }
    }
  }

  void _checkCompletionAndNavigate() async {
    if (_taskCompleted && _animationCompleted && mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => RewardDialog(
            locationName: _savedPost?.title ?? widget.newPost.title,
            currentUserAvatarUrl: widget.currentUserAvatarUrl,
            savedPost: _savedPost ?? widget.newPost,
          ),
        ),
      );
      if (result == true && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Center circular graphic stack
            Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Decorative Confetti/Sparks around the circle
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _ConfettiSparksPainter(),
                  ),
                  
                  // Circular image
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C57FC).withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.currentUserAvatarUrl != null
                          ? Image.network(
                              widget.currentUserAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, e, s) => Image.asset(
                                'assets/Timeline/images/element.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/Timeline/images/element.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

                  // Location Pin Circle overlapping at bottom
                  Positioned(
                    bottom: -10,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C57FC),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/Timeline/icons/location.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Text headers
            Text(
              "Posting your check-in...",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Almost there!",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF586674),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE6FC).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double progressWidth = constraints.maxWidth * _progressAnimation.value;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: progressWidth,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C57FC),
                              Color(0xFF945CF6),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// Confetti/Sparks painter for loading screen background
class _ConfettiSparksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = javaRand(42);
    final colors = [
      const Color(0xFF4CAFFF), // blue
      const Color(0xFFFF547C), // pink
      const Color(0xFFFFC043), // yellow
      const Color(0xFF7C57FC), // purple
    ];

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    for (int i = 0; i < 24; i++) {
      final color = colors[rand.nextInt(colors.length)];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      // Place in a ring around the center circle
      final double angle = (i * 15) * 3.14159 / 180 + (rand.nextDouble() * 0.2);
      final double distance = 85.0 + (rand.nextDouble() * 30.0);
      final double x = cx + distance * math.cos(angle);
      final double y = cy + distance * math.sin(angle);

      if (rand.nextBool()) {
        // Draw spark star/diamond shape
        final path = Path()
          ..moveTo(x, y - 6)
          ..lineTo(x + 4, y)
          ..lineTo(x, y + 6)
          ..lineTo(x - 4, y)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Draw tiny confetti circle or square
        final double sizeVal = rand.nextDouble() * 4 + 3;
        canvas.drawCircle(Offset(x, y), sizeVal / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  
  // Custom deterministic random to avoid random import conflict
  _DeterministicRand javaRand(int seed) {
    return _DeterministicRand(seed);
  }
}

class _DeterministicRand {
  int seed;
  _DeterministicRand(this.seed);
  
  int nextInt(int max) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed % max;
  }
  
  double nextDouble() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return (seed % 1000) / 1000.0;
  }
  
  bool nextBool() {
    return nextInt(2) == 0;
  }
}
