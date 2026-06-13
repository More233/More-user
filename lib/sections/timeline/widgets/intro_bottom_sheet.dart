import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroBottomSheet extends StatelessWidget {
  final VoidCallback onStartTap;

  const IntroBottomSheet({super.key, required this.onStartTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle (Slider)
          Container(
            width: 56,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFC1C1C1),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),

          // Header Title
          Text(
            'Your first check-in',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle Description
          Text(
            'Add a caption, a photo, or tag friends\nto make it yours.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              color: const Color(0xFF6D6D6D),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Center Illustration Stack
          SizedBox(
            width: 314,
            height: 174,
            child: Stack(
              children: [
                // 1. Featured Street/Food Truck Photo
                Positioned(
                  left: 49,
                  top: 14,
                  width: 217,
                  height: 142,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/Timeline/images/food_truck_street.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 2. Girl Avatar (Top Left)
                Positioned(
                  left: 36.5,
                  top: 0,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/Timeline/images/avatar_female.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // 3. Caption Message Speech Bubble Overlay (Bottom Middle-Left)
                Positioned(
                  left: 131,
                  top: 108,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Perfect spot to relax\nwith a view ✨',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),

                // 4. Guy Avatar (Bottom Right)
                Positioned(
                  left: 236,
                  top: 114,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/Timeline/images/avatar_male.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Continue Button
          SafeArea(
            top: false,
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
                onPressed: onStartTap,
                child: Text(
                  'Continue',
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
    );
  }
}
