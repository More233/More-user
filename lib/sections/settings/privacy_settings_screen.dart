import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  void _showVisibilitySelector({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String fieldKey,
    required String currentValue,
    required bool isAr,
    List<Map<String, String>>? customOptions,
  }) {
    final notifier = ref.read(settingsProvider.notifier);
    String selectedVal = currentValue;

    final defaultOptions = [
      {'title': isAr ? 'الكل' : 'All', 'value': 'all'},
      {'title': isAr ? 'الأصدقاء' : 'Friends', 'value': 'friends'},
      {'title': isAr ? 'أنا فقط' : 'Only me', 'value': 'only_me'},
    ];

    final options = customOptions ?? defaultOptions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.visibility, color: Color(0xFF7C57FC), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13,
                                color: const Color(0xFF707070),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Render options list
                  ...options.map((opt) {
                    final isSelected = opt['value'] == selectedVal;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => selectedVal = opt['value']!),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt['title']!,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFCCCCCC),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF7C57FC),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE8E8E8)),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C57FC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await notifier.updateField(fieldKey, selectedVal);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        isAr ? 'حفظ' : 'Save',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        isAr ? 'إلغاء' : 'Cancel',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF707070),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getVisibilityLabel(String val, bool isAr) {
    switch (val) {
      case 'all':
        return isAr ? 'الكل' : 'All';
      case 'friends':
        return isAr ? 'الأصدقاء' : 'Friends';
      case 'only_me':
        return isAr ? 'أنا فقط' : 'Only me';
      case 'everyone':
        return isAr ? 'الجميع' : 'Everyone';
      case 'friends_of_friends':
        return isAr ? 'أصدقاء الأصدقاء' : 'Friends of friends';
      default:
        return isAr ? 'الأصدقاء' : 'Friends';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
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
            isAr ? 'الخصوصية والظهور' : 'Privacy & Visibility',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
              
              // SECTION 1: PROFILE
              _buildSectionHeader(isAr ? 'الملف الشخصي' : 'PROFILE', isAr),
              _buildSelectorRow(
                context: context,
                ref: ref,
                icon: Icons.person_outline,
                title: isAr ? 'ظهور الملف الشخصي' : 'Profile visibility',
                subtitle: isAr ? 'إدارة من يمكنه رؤية ملفك الشخصي' : 'Manage who can see your account',
                fieldKey: 'profile_visibility',
                currentValue: settings.profileVisibility,
                isAr: isAr,
              ),
              _buildDivider(),
              _buildSelectorRow(
                context: context,
                ref: ref,
                icon: Icons.person_add_outlined, // Fallback or placeholder icon
                title: isAr ? 'طلبات الصداقة' : 'Friend requests',
                subtitle: isAr ? 'إدارة من يمكنه إرسال طلبات الصداقة إليك' : 'Manage who can request friendships',
                fieldKey: 'friend_requests_visibility',
                currentValue: settings.friendRequestsVisibility,
                isAr: isAr,
                customOptions: [
                  {'title': isAr ? 'الجميع' : 'Everyone', 'value': 'everyone'},
                  {'title': isAr ? 'أصدقاء الأصدقاء' : 'Friends of friends', 'value': 'friends_of_friends'},
                ],
              ),

              // SECTION 2: CHECK-INS
              _buildSectionHeader(isAr ? 'تسجيلات الوصول' : 'CHECK-INS', isAr),
              _buildSelectorRow(
                context: context,
                ref: ref,
                icon: Icons.location_on_outlined,
                title: isAr ? 'ظهور تسجيلات الوصول' : 'Check-in visibility',
                subtitle: isAr ? 'إدارة من يمكنه رؤية تسجيلات وصولك' : 'Manage who can see your check-ins',
                fieldKey: 'check_in_visibility',
                currentValue: settings.checkInVisibility,
                isAr: isAr,
              ),
              _buildDivider(),
              _buildToggleRow(
                icon: Icons.group_outlined,
                title: isAr ? 'إظهاري في "هنا الآن"' : 'Show me in Here now',
                value: settings.showMeHereNow,
                onChanged: (val) => notifier.updateField('show_me_here_now', val),
              ),
              _buildDivider(),
              _buildToggleRow(
                icon: Icons.verified_user_outlined,
                title: isAr ? 'السماح للأصدقاء بتسجيل الوصول معي' : 'Let friends check in with me',
                value: settings.letFriendsCheckInWithMe,
                onChanged: (val) => notifier.updateField('let_friends_check_in_with_me', val),
              ),

              // SECTION 3: ACTIVITY & SOCIAL
              _buildSectionHeader(isAr ? 'النشاط والاجتماع' : 'ACTIVITY & SOCIAL', isAr),
              _buildSelectorRow(
                context: context,
                ref: ref,
                icon: Icons.show_chart_outlined, // Fallback or placeholder icon
                title: isAr ? 'إظهار الإحصائيات والمتتاليات' : 'Show stats & streaks',
                subtitle: isAr ? 'إدارة من يمكنه رؤية إحصائياتك' : 'Manage who can see your stats & streaks',
                fieldKey: 'show_stats_streaks',
                currentValue: settings.showStatsStreaks,
                isAr: isAr,
              ),
              _buildDivider(),
              _buildToggleRow(
                icon: Icons.storefront_outlined, // Fallback or placeholder icon
                title: isAr ? 'إظهار الأماكن المحفوظة في ملفي الشخصي' : 'Show saved places on profile',
                value: settings.showSavedPlacesProfile,
                onChanged: (val) => notifier.updateField('show_saved_places_profile', val),
              ),
              _buildDivider(),
              _buildToggleRow(
                icon: Icons.alternate_email_outlined, // Fallback or placeholder at icon
                title: isAr ? 'السماح بالإشارات والذكر' : 'Allow tags & mentions',
                value: settings.allowTagsMentions,
                onChanged: (val) => notifier.updateField('allow_tags_mentions', val),
              ),

              const SizedBox(height: 24),
              // Bottom alert label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF909090), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'أنت تتحكم في من يمكنه رؤية نشاطك عبر تطبيق More.'
                            : 'You control who can see your activity across More.',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: const Color(0xFF707070),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildSelectorRow({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required String fieldKey,
    required String currentValue,
    required bool isAr,
    List<Map<String, String>>? customOptions,
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
          color: Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getVisibilityLabel(currentValue, isAr),
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF909090),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isAr ? Icons.arrow_back : Icons.arrow_forward_ios,
            size: isAr ? 20 : 14,
            color: const Color(0xFFCCCCCC),
          ),
        ],
      ),
      onTap: () => _showVisibilitySelector(
        context: context,
        ref: ref,
        title: title,
        subtitle: subtitle,
        fieldKey: fieldKey,
        currentValue: currentValue,
        isAr: isAr,
        customOptions: customOptions,
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF7C57FC),
            activeTrackColor: const Color(0xFFECE7FF),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 64, right: 16),
      child: Divider(height: 1, color: Color(0xFFE8E8E8)),
    );
  }
}
