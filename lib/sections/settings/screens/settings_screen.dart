import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/settings_provider.dart';
import '../widgets/language_sheet.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';
import 'location_settings_screen.dart';
import 'suggestions_settings_screen.dart';
import 'appearance_screen.dart';
import 'privacy_settings_screen.dart';
import 'blocked_users_screen.dart';
import 'help_support_screen.dart';
import 'send_feedback_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _fullName = '';
  String _username = '';
  String? _avatarUrl;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final profile = await client
          .from('profiles')
          .select('first_name, last_name, username, avatar_url')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profile != null && mounted) {
        setState(() {
          _fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
          _username = profile['username'] ?? '';
          _avatarUrl = profile['avatar_url'] as String?;
          _profileLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile details in settings: $e");
      if (mounted) {
        setState(() {
          _profileLoading = false;
        });
      }
    }
  }

  ImageProvider _getAvatarProvider(String username, String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return CachedNetworkImageProvider(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    return const AssetImage('assets/home/images/element.png');
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const LanguageSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
        body: settings.loading || _profileLoading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: Color(0xFF7C57FC),
                  radius: 12,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Divider(height: 1, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8)),
                    _buildProfileRow(isAr, isDark),
                    Divider(height: 8, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'الحساب' : 'ACCOUNT', isAr, isDark),
                    _buildFeatureRow(
                      icon: Icons.person_outline,
                      title: isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        if (updated == true) {
                           _fetchUserData();
                        }
                      },
                    ),
                    _buildDivider(isDark),
                    _buildFeatureRow(
                      icon: Icons.language_outlined,
                      title: isAr ? 'اللغة' : 'Language',
                      isAr: isAr,
                      isDark: isDark,
                      trailingText: settings.preferredLanguage == 'ar'
                          ? 'العربية'
                          : (settings.preferredLanguage == 'en' ? 'English' : 'Device'),
                      onTap: () => _showLanguageBottomSheet(context),
                    ),
                    Divider(height: 8, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'التجربة' : 'EXPERIENCE', isAr, isDark),
                    _buildFeatureRow(
                      icon: Icons.notifications_none_outlined,
                      title: isAr ? 'التنبيهات' : 'Notifications',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(isDark),
                    _buildFeatureRow(
                      icon: Icons.location_on_outlined,
                      title: isAr ? 'الموقع والأماكن المجاورة' : 'Location & Nearby',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(isDark),
                    _buildFeatureRow(
                      icon: Icons.dark_mode_outlined,
                      title: isAr ? 'المظهر' : 'Appearance',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppearanceScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(isDark),
                    _buildFeatureRow(
                      icon: Icons.lightbulb_outline,
                      title: isAr ? 'مقترحات تسجيل الوصول' : 'Check-in Suggestions',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuggestionsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 8, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6)),
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
                    _buildDivider(isDark),
                    _buildFeatureRow(
                      icon: Icons.block_outlined,
                      title: isAr ? 'الأشخاص المحظورين' : 'Blocked People',
                      isAr: isAr,
                      isDark: isDark,
                      trailingText: isAr
                          ? '${settings.blockedUsers.length} محظور'
                          : '${settings.blockedUsers.length} blocked',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 8, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'الدعم' : 'SUPPORT', isAr, isDark),
                    _buildFeatureRow(
                      icon: Icons.help_outline,
                      title: isAr ? 'المساعدة والدعم' : 'Help & Support',
                      isAr: isAr,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(isDark),
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

  Widget _buildProfileRow(bool isAr, bool isDark) {
    return InkWell(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
        if (updated == true) {
          _fetchUserData();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF2F2F2),
              backgroundImage: _getAvatarProvider(_username, _avatarUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName.isNotEmpty ? _fullName : (isAr ? 'اسم المستخدم' : 'No Name'),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _username.isNotEmpty ? '@$_username' : '',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : const Color(0xFF707070),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isAr ? Icons.arrow_back : Icons.arrow_forward_ios,
              size: isAr ? 20 : 16,
              color: const Color(0xFFBBBBBB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isAr, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white54 : const Color(0xFF909090),
          letterSpacing: 1.0,
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF7C57FC),
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

