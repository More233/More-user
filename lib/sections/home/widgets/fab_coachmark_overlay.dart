import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FabCoachmarkOverlay extends StatefulWidget {
  final VoidCallback onTap;

  const FabCoachmarkOverlay({super.key, required this.onTap});

  @override
  State<FabCoachmarkOverlay> createState() => _FabCoachmarkOverlayState();
}

class _FabCoachmarkOverlayState extends State<FabCoachmarkOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRipple(double progress) {
    // Ripples start at size 60 (FAB boundary) and expand to size 130 (maximum glow boundary)
    final double size = 60 + (130 - 60) * progress;
    final double opacity = (1.0 - progress);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFBCA4FF).withValues(alpha: 0.65 * opacity),
          width: 1.5,
        ),
        color: const Color(0xFFBCA4FF).withValues(alpha: 0.12 * opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate scale factors based on Figma design viewport (440x956)
          final double scaleX = constraints.maxWidth / 440;
          final double scaleY = constraints.maxHeight / 956;

          return Stack(
            children: [
              // Light transparent white frosted background blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.85, sigmaY: 3.85),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Highlight Circle (Purple-Pink glow cloud) with ImageFiltered blur
              Positioned(
                left: 106 * scaleX,
                top: 361 * scaleY,
                width: 331 * scaleX,
                height: 235 * scaleY,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: SvgPicture.asset(
                    'assets/home/icons/highlight_glow.svg',
                    fit: BoxFit.fill,
                  ),
                ),
              ),

              // Icon Bubbles Row (Location, Gallery/Photo, Camera)
              Positioned(
                left: 181 * scaleX,
                top: 412 * scaleY,
                width: 196 * scaleX,
                height: 64 * scaleY,
                child: Stack(
                  children: [
                    // Location Icon Bubble
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 56 * scaleX,
                      height: 58 * scaleX,
                      child: Image.asset(
                        'assets/home/images/location_bubble.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Plus sign (+) SVG between Location and Photo
                    Positioned(
                      left: 59 * scaleX,
                      top: 23 * scaleY,
                      width: 12 * scaleX,
                      height: 12 * scaleX,
                      child: SvgPicture.asset(
                        'assets/home/icons/plus_sign.svg',
                      ),
                    ),
                    // Photo/Gallery Icon Bubble
                    Positioned(
                      left: 71 * scaleX,
                      top: 2 * scaleY,
                      width: 54 * scaleX,
                      height: 56 * scaleX,
                      child: Image.asset(
                        'assets/home/images/photo_bubble.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Plus sign (+) SVG between Photo and Camera
                    Positioned(
                      left: 126 * scaleX,
                      top: 27 * scaleY,
                      width: 12 * scaleX,
                      height: 12 * scaleX,
                      child: SvgPicture.asset(
                        'assets/home/icons/plus_sign.svg',
                      ),
                    ),
                    // Camera Icon Bubble
                    Positioned(
                      left: 140 * scaleX,
                      top: 7 * scaleY,
                      width: 56 * scaleX,
                      height: 57 * scaleX,
                      child: Image.asset(
                        'assets/home/images/camera_bubble.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              // Tooltip Text directly over the glow cloud background
              Positioned(
                left: constraints.maxWidth * 0.5 + 59 * scaleX - (244 * scaleX) / 2,
                top: constraints.maxHeight * 0.5 + 39 * scaleY - (100 * scaleY) / 2,
                width: 244 * scaleX,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Make your first check-in",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18 * scaleX,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap + to share where you are, add a photo, and start collecting memories.",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12 * scaleX,
                        color: const Color(0xFF474747),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Dotted Line Arrow Curve pointing to FAB (aligned relative to right/bottom)
              Positioned(
                right: 41.5 * scaleX,
                bottom: 222.5 * scaleY + 16,
                width: 99.5 * scaleX,
                height: 144.5 * scaleY,
                child: SvgPicture.asset(
                  'assets/home/icons/dotted_arrow.svg',
                  fit: BoxFit.fill,
                ),
              ),

              // "Tap +" text next to the curve arrow (aligned relative to right/bottom)
              Positioned(
                right: 148 * scaleX,
                bottom: 397 * scaleY - 22,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap',
                      style: GoogleFonts.caveat(
                        fontSize: 24 * scaleX,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF703CFD),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    SvgPicture.asset(
                      'assets/home/icons/plus_sign.svg',
                      width: 14 * scaleX,
                      height: 14 * scaleX,
                    ),
                  ],
                ),
              ),

              // Animated Pulsing FAB Button - perfectly aligned with the actual FAB position (right: 16, bottom: 130)
              Positioned(
                right: 46 - 65,
                bottom: 160 - 65,
                width: 130,
                height: 130,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double p1 = _controller.value;
                    final double p2 = (_controller.value + 0.33) % 1.0;
                    final double p3 = (_controller.value + 0.66) % 1.0;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple 3 (Outer-most wave)
                        _buildRipple(p3),
                        // Ripple 2 (Middle wave)
                        _buildRipple(p2),
                        // Ripple 1 (Inner-most wave)
                        _buildRipple(p1),

                        // Solid White Inner boundary line that stays static around the FAB
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.95),
                              width: 2.0,
                            ),
                          ),
                        ),

                        // Purple FAB button with white border & white plus sign SVG
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C57FC),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/home/icons/plus_signlg.svg',
                              width: 28,
                              height: 28,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
