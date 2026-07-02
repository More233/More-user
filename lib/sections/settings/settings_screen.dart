import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_provider.dart';
import 'language_sheet.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';
import 'location_settings_screen.dart';
import 'suggestions_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'blocked_users_screen.dart';
import 'help_support_screen.dart';
import 'send_feedback_screen.dart';
import '../auth/auth_flow_page.dart';

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
        return NetworkImage(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    return const AssetImage('assets/home/images/element.png');
  }

  Future<void> _handleLogout(BuildContext context) async {
    final stateSettings = ref.read(settingsProvider);
    final isAr = stateSettings.preferredLanguage == 'ar';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'تسجيل الخروج من حسابك؟' : 'Sign out of your account?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF323232),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Sign Out Button
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    width: 286,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                        bottom: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'تسجيل الخروج' : 'Sign Out',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFD80000),
                      ),
                    ),
                  ),
                ),
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'إلغاء' : 'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF373737),
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

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthFlowPage()),
          (route) => false,
        );
      } catch (e) {
        debugPrint("Error signing out: $e");
      }
    }
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

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'الإعدادات' : 'Settings',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: settings.loading || _profileLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C57FC),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const Divider(height: 1, color: Color(0xFFE8E8E8)),
                    _buildProfileRow(isAr),
                    const Divider(height: 8, color: Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'الحساب' : 'ACCOUNT', isAr),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/user.svg',
                      title: isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
                      isAr: isAr,
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
                    _buildDivider(),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/language_square.svg',
                      title: isAr ? 'اللغة' : 'Language',
                      isAr: isAr,
                      trailingText: settings.preferredLanguage == 'ar'
                          ? 'العربية'
                          : (settings.preferredLanguage == 'en' ? 'English' : 'Device'),
                      onTap: () => _showLanguageBottomSheet(context),
                    ),
                    const Divider(height: 8, color: Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'التجربة' : 'EXPERIENCE', isAr),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/notification_02.svg',
                      title: isAr ? 'التنبيهات' : 'Notifications',
                      isAr: isAr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/location_01.svg',
                      title: isAr ? 'الموقع والأماكن المجاورة' : 'Location & Nearby',
                      isAr: isAr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/idea_01.svg',
                      title: isAr ? 'مقترحات تسجيل الوصول' : 'Check-in Suggestions',
                      isAr: isAr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuggestionsSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 8, color: Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'الخصوصية' : 'PRIVACY', isAr),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/security_lock.svg',
                      title: isAr ? 'الخصوصية والظهور' : 'Privacy & Visibility',
                      isAr: isAr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/user_block_01.svg',
                      title: isAr ? 'الأشخاص المحظورين' : 'Blocked People',
                      isAr: isAr,
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
                    const Divider(height: 8, color: Color(0xFFF6F6F6)),
                    _buildSectionHeader(isAr ? 'الدعم' : 'SUPPORT', isAr),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/help_circle.svg',
                      title: isAr ? 'المساعدة والدعم' : 'Help & Support',
                      isAr: isAr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/mail_01.svg',
                      title: isAr ? 'إرسال ملاحظاتك' : 'Send Feedback',
                      isAr: isAr,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SendFeedbackScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildFeatureRow(
                      iconPath: 'assets/setting/icons/information_circle.svg',
                      title: isAr ? 'حول More' : 'About More',
                      isAr: isAr,
                      onTap: () => _showAboutMoreDialog(context, isAr),

                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF3B30),
                          ),
                          onPressed: () => _handleLogout(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/setting/icons/logout_02.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFFF3B30),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? 'تسجيل الخروج' : 'Log out',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF3B30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  void _showAboutMoreDialog(BuildContext context, bool isAr) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
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
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'الإصدار 1.0.1 (118)' : 'Version 1.0.1 (118)',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr
                      ? 'تطبيق More لتسجيلات الوصول واستكشاف الأماكن المفضلة ومشاركتها مع أصدقائك.'
                      : 'More is a check-in app to discover, save and share your favorite places with friends.',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF555555),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          showLicensePage(
                            context: context,
                            applicationName: 'More',
                            applicationVersion: '1.0.1',
                          );
                        },
                        child: Text(
                          isAr ? 'عرض التراخيص' : 'Licenses',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C57FC),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          isAr ? 'إغلاق' : 'Close',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(bool isAr) {
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _username.isNotEmpty ? '@$_username' : '',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF707070),
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

  Widget _buildSectionHeader(String title, bool isAr) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF909090),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required String iconPath,
    required String title,
    required bool isAr,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Color(0xFF7C57FC),
            BlendMode.srcIn,
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
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
                color: const Color(0xFF909090),
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


  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 64, right: 16),
      child: Divider(height: 1, color: Color(0xFFE8E8E8)),
    );
  }
}

