import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class SuggestionsSettingsScreen extends ConsumerWidget {
  const SuggestionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isAr = settings.preferredLanguage == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color promoBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFF9F9FA);
    final Color promoBorder = isDark ? const Color(0xFF1E2433) : const Color(0xFFF0F0F2);
    final Color sectionHeaderBg = isDark ? const Color(0xFF131722) : const Color(0xFFFAFAFA);

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
            isAr ? 'مقترحات تسجيل الوصول' : 'Check-in Suggestions',
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
              // Promo card banner matching Figma - 309
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
                              isAr ? 'لا تفوت أي ذكرى أبداً' : 'Never miss a memory',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'تساعدك المقترحات الذكية على تذكر الأماكن التي زرتها وتجعل من السهل تسجيل الوصول.'
                                  : 'Smart suggestions help you remember places you\'ve been and make it easy to check in.',
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
                      // suggestions_promo image matching mockup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/setting/images/suggestions_promo.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 96,
                            height: 96,
                            color: isDark ? const Color(0xFF131722) : Colors.grey[200],
                            child: Icon(Icons.image, color: isDark ? Colors.white24 : Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 8, color: sectionHeaderBg),
              _buildSectionHeader(isAr ? 'التفضيلات والمقترحات الذكية' : 'INTELLIGENT SUGGESTIONS', isAr, isDark),
              // Show check-in suggestions
              _buildToggleRow(
                icon: Icons.lightbulb_outline,
                title: isAr ? 'إظهار مقترحات تسجيل الوصول' : 'Show check-in suggestions',
                value: settings.showCheckInSuggestions,
                onChanged: (val) => notifier.updateField('show_check_in_suggestions', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Suggest places when nearby
              _buildToggleRow(
                icon: Icons.location_on_outlined,
                title: isAr ? 'اقتراح الأماكن عندما أكون قريباً' : 'Suggest places when nearby',
                value: settings.suggestPlacesWhenNearby,
                onChanged: (val) => notifier.updateField('suggest_places_when_nearby', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Suggest from recent visits
              _buildToggleRow(
                icon: Icons.history,
                title: isAr ? 'الاقتراح من الزيارات الأخيرة' : 'Suggest from recent visits',
                value: settings.suggestFromRecentVisits,
                onChanged: (val) => notifier.updateField('suggest_from_recent_visits', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Use photo time & location
              _buildToggleRow(
                icon: Icons.photo_library_outlined,
                title: isAr ? 'استخدام وقت وموقع الصور' : 'Use photo time & location',
                value: settings.usePhotoTimeLocation,
                onChanged: (val) => notifier.updateField('use_photo_time_location', val),
                isDark: isDark,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isAr, bool isDark) {
    final Color sectionHeaderTextColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: sectionHeaderTextColor,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
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
          const SizedBox(width: 16),
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
            activeTrackColor: const Color(0xFF7C57FC),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(height: 1, color: dividerColor),
    );
  }
}
