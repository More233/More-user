import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isAr = settings.preferredLanguage == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF707070);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    final push = settings.pushSettings;

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
            isAr ? 'التنبيهات' : 'Notifications',
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
              // SECTION 1: APP NOTIFICATIONS
              _buildSectionHeader(isAr ? 'تنبيهات التطبيق' : 'APP NOTIFICATIONS', isAr, isDark),
              _buildSwitchRow(
                title: isAr ? 'تذكيرات بتسجيلات الوصول القريبة' : 'Nearby check-in reminders',
                value: push['nearby_check_in_reminders'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('nearby_check_in_reminders', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchRow(
                title: isAr ? 'سجل الأصدقاء القريبين وصولهم' : 'Friends checked in nearby',
                value: push['friends_checked_in_nearby'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('friends_checked_in_nearby', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchRow(
                title: isAr ? 'الإشارات في تسجيلات الوصول' : 'Mentions in check-ins',
                value: push['mentions_in_check_ins'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('mentions_in_check_ins', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchRow(
                title: isAr ? 'الإعجابات والتعليقات على تسجيلاتي' : 'Likes and comments on my check-ins',
                value: push['likes_comments_on_check_ins'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('likes_comments_on_check_ins', val),
                isDark: isDark,
              ),

              // SECTION 2: SOCIAL & CHECK-IN ACTIVITY
              _buildSectionHeader(isAr ? 'النشاط الاجتماعي وتسجيل الوصول' : 'SOCIAL & CHECK-IN ACTIVITY', isAr, isDark),
              _buildSwitchRow(
                title: isAr ? 'طلبات الصداقة' : 'Friend requests',
                value: push['friend_requests'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('friend_requests', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchRow(
                title: isAr ? 'الرسائل' : 'Messages',
                value: push['messages'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('messages', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchRow(
                title: isAr ? 'الأماكن والقوائم المشتركة' : 'Shared places and lists',
                value: push['shared_places_lists'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('shared_places_lists', val),
                isDark: isDark,
              ),

              // SECTION 3: RECOMMENDATION UPDATES
              _buildSectionHeader(isAr ? 'تحديثات التوصية' : 'RECOMMENDATION UPDATES', isAr, isDark),
              _buildSwitchRow(
                title: isAr ? 'أماكن جديدة قد تعجبك' : 'New places you may like',
                value: push['new_places_may_like'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('new_places_may_like', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchRow(
                title: isAr ? 'العروض من الأماكن المحفوظة' : 'Offers from saved places',
                value: push['offers_saved_places'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('offers_saved_places', val),
                isDark: isDark,
              ),

              const SizedBox(height: 24),
              // Helper text info label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: textMutedColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'يمكنك تغيير أذونات الإشعارات الفورية في أي وقت من إعدادات جهازك.'
                            : 'You can change push notification permissions anytime from your device settings',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: textMutedColor,
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

  Widget _buildSectionHeader(String title, bool isAr, bool isDark) {
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

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF7C57FC),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: dividerColor),
    );
  }
}
