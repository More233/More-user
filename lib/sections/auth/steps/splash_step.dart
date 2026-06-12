import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashStep extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLoginPressed;

  const SplashStep({
    super.key,
    required this.onGetStarted,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Splash main illustration
            SvgPicture.asset(
              'assets/Splash/logo.svg',
              width: 154,
              height: 48.79,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Color(0xFF7C57FC),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 36),
            // Title Header
            Text(
              'Discover more\naround you',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // Description Subtitle
            Text(
              'Check-in, save places, book, order,\nand stay connected.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),
            // Feature List Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B60FC).withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureRow(
                    iconPath: 'assets/Auth Section/Discover more around you/icon/location-01.svg',
                    title: 'Check in',
                    description: 'Let friends know where you are.',
                  ),
                  const Divider(color: Color(0xFFF3F4F6), height: 24),
                  _buildFeatureRow(
                    iconPath: 'assets/Auth Section/Discover more around you/icon/bookmark-02.svg',
                    title: 'Save places',
                    description: 'Keep your favorite places in one spot.',
                  ),
                  const Divider(color: Color(0xFFF3F4F6), height: 24),
                  _buildFeatureRow(
                    iconPath: 'assets/Auth Section/Discover more around you/icon/shopping-bag-01.svg',
                    title: 'Book & order',
                    description: 'Reserve tables and order with ease.',
                  ),
                  const Divider(color: Color(0xFFF3F4F6), height: 24),
                  _buildFeatureRow(
                    iconPath: 'assets/Auth Section/Discover more around you/icon/user-multiple.svg',
                    title: 'Stay connected',
                    description: 'See friends, activity, and updates.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Buttons Section
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Get started',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onLoginPressed,
              child: Text(
                'I already have an account',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C57FC),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Legal Footer Text
            Text(
              "Tap 'Continue' you agree to our",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: const Color(0xFFB0B0B8),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Terms & Privacy Policy',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: const Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required String iconPath,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEFC),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF7C57FC),
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
