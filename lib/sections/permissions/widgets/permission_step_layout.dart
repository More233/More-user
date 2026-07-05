import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders a full step UI screen in the onboarding flow.
class PermissionStepLayout extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final List<Widget> featureRows;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String secondaryButtonText;
  final VoidCallback onSecondaryPressed;

  const PermissionStepLayout({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.featureRows,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    required this.secondaryButtonText,
    required this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCFCFC),
      child: SafeArea(
        child: Column(
          children: [
            // Top Illustration
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Body Content
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading & Subtitle
                    Text(
                      title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Feature Rows List
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: featureRows.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => featureRows[index],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    GestureDetector(
                      onTap: onPrimaryPressed,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          primaryButtonText,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onSecondaryPressed,
                      child: Container(
                        width: double.infinity,
                        height: 24,
                        alignment: Alignment.center,
                        child: Text(
                          secondaryButtonText,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C57FC),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
