import 'package:flutter/material.dart';
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

    final push = settings.pushSettings;

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
            isAr ? 'التنبيهات' : 'Notifications',
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
              // SECTION 1: APP NOTIFICATIONS
              _buildSectionHeader(isAr ? 'تنبيهات التطبيق' : 'APP NOTIFICATIONS', isAr),
              _buildSwitchRow(
                title: isAr ? 'تذكيرات بتسجيلات الوصول القريبة' : 'Nearby check-in reminders',
                value: push['nearby_check_in_reminders'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('nearby_check_in_reminders', val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: isAr ? 'سجل الأصدقاء القريبين وصولهم' : 'Friends checked in nearby',
                value: push['friends_checked_in_nearby'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('friends_checked_in_nearby', val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: isAr ? 'الإشارات في تسجيلات الوصول' : 'Mentions in check-ins',
                value: push['mentions_in_check_ins'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('mentions_in_check_ins', val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: isAr ? 'الإعجابات والتعليقات على تسجيلاتي' : 'Likes and comments on my check-ins',
                value: push['likes_comments_on_check_ins'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('likes_comments_on_check_ins', val),
              ),

              // SECTION 2: SOCIAL & CHECK-IN ACTIVITY
              _buildSectionHeader(isAr ? 'النشاط الاجتماعي وتسجيل الوصول' : 'SOCIAL & CHECK-IN ACTIVITY', isAr),
              _buildSwitchRow(
                title: isAr ? 'طلبات الصداقة' : 'Friend requests',
                value: push['friend_requests'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('friend_requests', val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: isAr ? 'الرسائل' : 'Messages',
                value: push['messages'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('messages', val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: isAr ? 'الأماكن والقوائم المشتركة' : 'Shared places and lists',
                value: push['shared_places_lists'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('shared_places_lists', val),
              ),

              // SECTION 3: RECOMMENDATION UPDATES
              _buildSectionHeader(isAr ? 'تحديثات التوصية' : 'RECOMMENDATION UPDATES', isAr),
              _buildSwitchRow(
                title: isAr ? 'أماكن جديدة قد تعجبك' : 'New places you may like',
                value: push['new_places_may_like'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('new_places_may_like', val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                title: isAr ? 'العروض من الأماكن المحفوظة' : 'Offers from saved places',
                value: push['offers_saved_places'] ?? true,
                onChanged: (val) => notifier.updatePushSetting('offers_saved_places', val),
              ),

              const SizedBox(height: 24),
              // Helper text info label
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
                            ? 'يمكنك تغيير أذونات الإشعارات الفورية في أي وقت من إعدادات جهازك.'
                            : 'You can change push notification permissions anytime from your device settings',
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

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFE8E8E8)),
    );
  }
}
