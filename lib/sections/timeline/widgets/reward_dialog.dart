import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timeline_post.dart';

class RewardDialog extends StatelessWidget {
  final VoidCallback? onClaimTap;
  final String locationName;
  final String? currentUserAvatarUrl;
  final TimelinePost? savedPost;

  const RewardDialog({
    super.key,
    this.onClaimTap,
    this.locationName = "Helnan Auberge El Fayoum Hotel",
    this.currentUserAvatarUrl,
    this.savedPost,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF2F0F9),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F0F9),
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // Top Section with Confetti Background
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Confetti Painter
                          CustomPaint(
                            size: const Size(double.infinity, 260),
                            painter: _ConfettiPainter(),
                          ),
                          // Avatar Stack (Hotel Avatar + Purple Checkmark)
                          Column(
                            children: [
                              const SizedBox(height: 40),
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.bottomRight,
                                children: [
                                  // Circular Hotel Image / User Avatar
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: currentUserAvatarUrl != null
                                          ? Image.network(
                                              currentUserAvatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, e, s) => Image.asset(
                                                'assets/Timeline/Personal Timeline  Default State/image/Element.png',
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.asset(
                                              'assets/Timeline/Check-in Success  First Check-in Reward/image/hotel_placeholder.png',
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ),
                                  // Purple Checkmark Badge
                                  Positioned(
                                    bottom: -6,
                                    right: -8,
                                    width: 42,
                                    height: 46,
                                    child: Image.asset(
                                      'assets/Timeline/Check-in Success  First Check-in Reward/image/first_checkin_sticker.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Title
                              Text(
                                "Your first check-in here!",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A2E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              // Subtitle
                              Text(
                                locationName,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF82858C),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 1. Rewards Breakdown Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Milestone 1: First check-in
                            _buildRewardRow(
                              iconPath: 'assets/Timeline/Check-in Success  First Check-in Reward/icon/location.svg',
                              title: "First check-in",
                              subtitle: "Thanks for being here.",
                              coins: "+100",
                              coinAsset: 'assets/Timeline/Check-in Success  First Check-in Reward/image/single_coin.png',
                            ),
                            const Divider(height: 1, color: Color(0xFFEFEFEF), indent: 70, endIndent: 20),
                            // Milestone 2: First hotel
                            _buildRewardRow(
                              iconPath: 'assets/Timeline/Check-in Success  First Check-in Reward/icon/hotel.svg',
                              title: "First hotel",
                              subtitle: "Exploring new places.",
                              coins: "+100",
                              coinAsset: 'assets/Timeline/Check-in Success  First Check-in Reward/image/single_coin.png',
                            ),
                            const Divider(height: 1, color: Color(0xFFEFEFEF), indent: 70, endIndent: 20),
                            // Milestone 3: Great photo
                            _buildRewardRow(
                              iconPath: 'assets/Timeline/Check-in Success  First Check-in Reward/icon/camera.svg',
                              title: "Great photo",
                              subtitle: "Nice shot!",
                              coins: "+100",
                              coinAsset: 'assets/Timeline/Check-in Success  First Check-in Reward/image/single_coin.png',
                            ),
                            // Highlighted total row at the bottom of the card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAF9FD),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Coins stack icon
                                  Image.asset(
                                    'assets/Timeline/Check-in Success  First Check-in Reward/image/coins_stack.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    "Coins earned",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "300",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF7C57FC),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Gold coin badge
                                  Image.asset(
                                    'assets/Timeline/Personal Timeline  Default State/image/image 156.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Sticker Unlocked Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Sticker Image
                            Image.asset(
                              'assets/Timeline/Check-in Success  First Check-in Reward/image/checkmark_badge.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "New sticker unlocked!",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF7C57FC),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "First Check-In",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "You checked in at your first place.",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      color: const Color(0xFF82858C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right arrow SVG
                            SvgPicture.asset(
                              'assets/Timeline/Check-in Success  First Check-in Reward/icon/arrow_right.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF82858C),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Bottom Action Done Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onClaimTap ?? () {
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
  }

  Widget _buildRewardRow({
    required String iconPath,
    required String title,
    required String subtitle,
    required String coins,
    required String coinAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // SVG Row Icon in circular purple container
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF2EEFC),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              iconPath,
              colorFilter: const ColorFilter.mode(
                Color(0xFF7C57FC),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ],
            ),
          ),
          // Value earned
          Text(
            coins,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7C57FC),
            ),
          ),
          const SizedBox(width: 8),
          // Coin icon
          Image.asset(
            coinAsset,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// Confetti painter for decorative celebration background
class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42); // deterministic random seed for static placement
    final colors = [
      const Color(0xFF4CAFFF), // blue
      const Color(0xFFFF547C), // pink
      const Color(0xFFFFC043), // yellow
      const Color(0xFF7C57FC), // purple
    ];

    for (int i = 0; i < 40; i++) {
      final color = colors[rand.nextInt(colors.length)];
      final paint = Paint()
        ..color = color.withValues(alpha: rand.nextDouble() * 0.4 + 0.5)
        ..style = PaintingStyle.fill;

      final double x = rand.nextDouble() * size.width;
      final double y = rand.nextDouble() * (size.height - 40);
      final double radius = rand.nextDouble() * 4 + 3;

      if (rand.nextBool()) {
        // Draw confetti circle
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else {
        // Draw rotated rectangular/ribbon confetti
        final double width = rand.nextDouble() * 8 + 4;
        final double height = rand.nextDouble() * 12 + 6;
        final double rotation = rand.nextDouble() * math.pi;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
