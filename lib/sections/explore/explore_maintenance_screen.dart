import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/widgets/common/cached_image.dart';

class ExploreMaintenanceScreen extends StatelessWidget {
  final String? userAvatarUrl;
  final VoidCallback? onAvatarTapped;
  final VoidCallback? onBackToHome;
  final VoidCallback? onNavigateToOrders;

  const ExploreMaintenanceScreen({
    super.key,
    this.userAvatarUrl,
    this.onAvatarTapped,
    this.onBackToHome,
    this.onNavigateToOrders,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final bgColor = isDark ? const Color(0xFF0F131D) : const Color(0xFFF7F8FA);
    final cardBg = isDark ? const Color(0xFF171C28) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFECEEF2);
    final textColor = isDark ? Colors.white : const Color(0xFF1B1D28);
    final subtextColor = isDark ? const Color(0xFF9EA3AE) : const Color(0xFF717684);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background ambient soft glow behind the central illustration
          Positioned(
            top: topPadding + 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C57FC).withValues(alpha: isDark ? 0.22 : 0.12),
                      const Color(0xFF7C57FC).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: topPadding),

                // Top Navigation Bar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Left avatar
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onAvatarTapped?.call();
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
                                  ? CustomCachedImage(url: userAvatarUrl!, fit: BoxFit.cover)
                                  : Image.asset(
                                      'assets/home/images/avatar_placeholder.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Center logo / title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/Splash/logo.svg',
                            height: 24,
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              isDark ? Colors.white : const Color(0xFF7C57FC),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "استكشف",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 110 + bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Central maintenance illustration badge
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ripple circle
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF7C57FC).withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: const Color(0xFF7C57FC).withValues(alpha: 0.18),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Middle circle
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cardBg,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C57FC).withValues(alpha: 0.18),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8E6BFF), Color(0xFF6B42E8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.explore_rounded,
                                      size: 38,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              // Floating small maintenance wrench badge
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFAAD14),
                                    border: Border.all(
                                      color: cardBg,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFAAD14).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.build_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Maintenance Pill Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAAD14).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFFAAD14).withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFAAD14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "تحسينات وصيانة مجدولة",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFAAD14),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Main Title
                        Text(
                          "مغلقة للصيانة حالياً",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "نعمل على ترقية وتطوير تجربة الخريطة والاستكشاف التفاعلية لنقدم لكم تجربة استثنائية وأماكن أكثر دقة وقريباً سنكون متاحين من جديد.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: subtextColor,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Highlights info card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildFeatureRow(
                                isDark: isDark,
                                icon: Icons.map_outlined,
                                title: "خرائط تفاعلية متطورة",
                                subtitle: "تحديثات للسرعة وتحديد المواقع بدقة أعلى",
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: borderColor),
                              ),
                              _buildFeatureRow(
                                isDark: isDark,
                                icon: Icons.storefront_outlined,
                                title: "اكتشاف أماكن وفعاليات حصرية",
                                subtitle: "إضافة مزيد من المقاهي والمطاعم المميزة في مدينتك",
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: borderColor),
                              ),
                              _buildFeatureRow(
                                isDark: isDark,
                                icon: Icons.speed_rounded,
                                title: "أداء سلس وسريع",
                                subtitle: "تحسين استهلاك البيانات والتصفح الفوري",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Primary Action Button: Back to Home
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onBackToHome?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C57FC),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.home_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "العودة إلى الرئيسية",
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (onNavigateToOrders != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onNavigateToOrders?.call();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: const Color(0xFF7C57FC).withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.fastfood_outlined,
                                    size: 18,
                                    color: Color(0xFF7C57FC),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "تصفح قسم الطلبات والمطاعم",
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7C57FC),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7C57FC).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF7C57FC),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1B1D28),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF9EA3AE) : const Color(0xFF717684),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
