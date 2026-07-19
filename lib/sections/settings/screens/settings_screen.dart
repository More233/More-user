import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import 'privacy_settings_screen.dart';
import 'send_feedback_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {




  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1219) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F1219) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'الإعدادات' : 'Settings',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: settings.loading
            ? const Center(
                child: CupertinoActivityIndicator(
                  color: Color(0xFF7C57FC),
                  radius: 12,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Divider(height: 1, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8)),
                    _buildSectionHeader(isAr ? 'الخصوصية' : 'PRIVACY', isAr, isDark),
                    _buildFeatureRow(
                      icon: Icons.lock_outline,
                      title: isAr ? 'الخصوصية والظهور' : 'Privacy & Visibility',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 8, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'الدعم' : 'SUPPORT', isAr, isDark),
                    _buildFeatureRow(
                      icon: Icons.mail_outline,
                      title: isAr ? 'إرسال ملاحظاتك' : 'Send Feedback',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SendFeedbackScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(isDark),
                    _buildFeatureRow(
                      icon: Icons.info_outline,
                      title: isAr ? 'حول More' : 'About More',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () => _showAboutMoreDialog(context, isAr),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  void _showAboutMoreDialog(BuildContext context, bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF131722) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF323232);
    final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF555555);
    final Color versionTextColor = isDark ? Colors.white54 : const Color(0xFF888888);
    final Color borderDividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFBFBFBF);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/Splash/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFFECE7FF),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF7C57FC),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'More',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'الإصدار 1.0.1 (169)' : 'Version 1.0.1 (169)',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: versionTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    isAr
                        ? 'تطبيق More لتسجيلات الوصول واستكشاف الأماكن المفضلة ومشاركتها مع أصدقائك.'
                        : 'More is a check-in app to discover, save and share your favorite places with friends.',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Licenses Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showLicensePage(
                      context: context,
                      applicationName: 'More',
                      applicationVersion: '1.0.1',
                    );
                  },
                  child: Container(
                    width: 286,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: borderDividerColor, width: 0.7),
                        bottom: BorderSide(color: borderDividerColor, width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'عرض التراخيص' : 'Licenses',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9E85FF) : const Color(0xFF7C57FC),
                      ),
                    ),
                  ),
                ),
                
                // Close Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'إغلاق' : 'Close',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF373737),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildSectionHeader(String title, bool isAr, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF666666),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required bool isAr,
    String? trailingText,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isDark ? Colors.white : const Color(0xFF262626),
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: isDark ? Colors.white38 : const Color(0xFF909090),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            isAr ? Icons.arrow_back : Icons.arrow_forward_ios,
            size: isAr ? 20 : 14,
            color: const Color(0xFFCCCCCC),
          ),
        ],
      ),
      onTap: onTap,
    );
  }


  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(height: 1, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8)),
    );
  }
}

