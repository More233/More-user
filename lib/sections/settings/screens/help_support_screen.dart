import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@more.app',
      queryParameters: {
        'subject': 'More App Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      debugPrint('Error launching email client: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email client. Please email support@more.app')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/15550199'); // Mock WhatsApp number
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $whatsappUri';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color promoBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFF9F9FA);
    final Color promoBorder = isDark ? const Color(0xFF1E2433) : const Color(0xFFF0F0F2);
    final Color iconWrapperBg = isDark ? const Color(0xFF2A1C54) : const Color(0xFFF3EFFF);
    final Color arrowColor = isDark ? Colors.white24 : const Color(0xFFCCCCCC);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'المساعدة والدعم' : 'Help & Support',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: dividerColor),
              // Promo card banner matching Figma - 321
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: promoBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: promoBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'نحن هنا للمساعدة' : "We're here to help",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'يرد فريق الدعم لدينا عادةً في غضون 24 ساعة.'
                                  : 'Our support team typically replies within 24 hours.',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: textMutedColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // help_promo image matching mockup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/setting/images/help_promo.png',
                          width: 120,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 120,
                            height: 96,
                            color: isDark ? const Color(0xFF1F2430) : Colors.grey[200],
                            child: const Icon(Icons.help_center_outlined, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {},
                  style: GoogleFonts.ibmPlexSansArabic(color: textColor),
                  decoration: InputDecoration(
                    hintText: isAr ? 'ابحث في مواضيع المساعدة...' : 'Search help topics...',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white38 : const Color(0xFFBBBBBB)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/setting/icons/search_01.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white38 : const Color(0xFF888888),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Popular Topics section matching Figma - 322
              _buildSectionHeader(isAr ? 'المواضيع الشائعة' : 'POPULAR TOPICS', isAr),
              _buildTopicRow(
                icon: Icons.location_on_outlined,
                title: isAr ? 'تسجيلات الوصول' : 'Check-ins',
                subtitle: isAr ? 'كيفية تسجيل الوصول وإدارته' : 'How to check in and manage check-ins',
                isAr: isAr,
              ),
              _buildDivider(),
              _buildTopicRow(
                icon: Icons.people_outline,
                title: isAr ? 'الأصدقاء والتواصل' : 'Friends & Connections',
                subtitle: isAr
                    ? 'إضافة الأصدقاء، وإدارة الطلبات والاتصالات'
                    : 'Add friends, manage requests, and connections',
                isAr: isAr,
              ),
              _buildDivider(),
              _buildTopicRow(
                icon: Icons.storefront_outlined,
                title: isAr ? 'الأماكن المحفوظة' : 'Saved Places',
                subtitle: isAr
                    ? 'حفظ وتنظيم وإدارة أمكنتك المفضلة'
                    : 'Save, organize, and manage your favorite places',
                isAr: isAr,
              ),
              _buildDivider(),
              _buildTopicRow(
                icon: Icons.notifications_none_outlined,
                title: isAr ? 'التنبيهات' : 'Notifications',
                subtitle: isAr ? 'التحكم في التنبيهات التي تتلقاها' : 'Control what notifications you receive',
                isAr: isAr,
              ),
              _buildDivider(),
              _buildTopicRow(
                icon: Icons.lock_outline,
                title: isAr ? 'الخصوصية والأمان' : 'Privacy & Safety',
                subtitle: isAr ? 'الحفاظ على أمان حسابك وبياناتك' : 'Keep your account and data secure',
                isAr: isAr,
              ),
              _buildDivider(),
              _buildTopicRow(
                icon: Icons.settings_outlined,
                title: isAr ? 'إعدادات الحساب' : 'Account Settings',
                subtitle: isAr
                    ? 'تحديث ملفك الشخصي وتفضيلات حسابك'
                    : 'Update your profile and account preferences',
                isAr: isAr,
              ),
              Divider(height: 8, color: isDark ? const Color(0xFF131722) : const Color(0xFFF6F6F6)),
              
              // Reach Out options section matching Figma - 321
              _buildSectionHeader(isAr ? 'اختر طريقة للاتصال بنا' : 'CHOOSE A WAY TO REACH US', isAr),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconWrapperBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/setting/icons/mail_01.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF7C57FC),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(
                  isAr ? 'مراسلتنا عبر البريد الإلكتروني' : 'Email us',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'support@more.app',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: const Color(0xFF7C57FC),
                  ),
                ),
                trailing: Icon(
                  isAr ? Icons.arrow_back : Icons.arrow_forward_ios,
                  size: isAr ? 20 : 14,
                  color: arrowColor,
                ),
                onTap: _launchEmail,
              ),
              _buildDivider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconWrapperBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF7C57FC), size: 20),
                ),
                title: Text(
                  'WhatsApp',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  isAr ? 'راسلنا على واتساب' : 'Message us on WhatsApp',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: textMutedColor,
                  ),
                ),
                trailing: Icon(
                  isAr ? Icons.arrow_back : Icons.arrow_forward_ios,
                  size: isAr ? 20 : 14,
                  color: arrowColor,
                ),
                onTap: _launchWhatsApp,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isAr) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sectionHeaderBg = isDark ? const Color(0xFF131722) : const Color(0xFFFAFAFA);
    final Color sectionHeaderTextColor = isDark ? Colors.white70 : const Color(0xFF909090);

    return Container(
      width: double.infinity,
      color: sectionHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: sectionHeaderTextColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTopicRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAr,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF707070);
    final Color iconWrapperBg = isDark ? const Color(0xFF2A1C54) : const Color(0xFFF3EFFF);
    final Color arrowColor = isDark ? Colors.white24 : const Color(0xFFCCCCCC);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconWrapperBg,
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
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          color: textMutedColor,
        ),
      ),
      trailing: Icon(
        isAr ? Icons.arrow_back : Icons.arrow_forward_ios,
        size: isAr ? 20 : 14,
        color: arrowColor,
      ),
      onTap: () {
        // Expand/navigate to sub-topic details (mocked or simple dialog)
      },
    );
  }

  Widget _buildDivider() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(height: 1, color: dividerColor),
    );
  }
}
