import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            isAr ? 'مقترحات تسجيل الوصول' : 'Check-in Suggestions',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(height: 1, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8)),
              // Promo card banner matching Figma - 309
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F2)),
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
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'تساعدك المقترحات الذكية على تذكر الأماكن التي زرتها وتجعل من السهل تسجيل الوصول.'
                                  : 'Smart suggestions help you remember places you\'ve been and make it easy to check in.',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : const Color(0xFF666666),
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
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 8, color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF6F6F6)),
              _buildSectionHeader(isAr ? 'التفضيلات والمقترحات الذكية' : 'INTELLIGENT SUGGESTIONS', isAr, isDark),
              // Show check-in suggestions
              _buildToggleRow(
                iconPath: 'assets/setting/icons/idea_01.svg',
                title: isAr ? 'إظهار مقترحات تسجيل الوصول' : 'Show check-in suggestions',
                value: settings.showCheckInSuggestions,
                onChanged: (val) => notifier.updateField('show_check_in_suggestions', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Suggest places when nearby
              _buildToggleRow(
                iconPath: 'assets/setting/icons/location_06.svg',
                title: isAr ? 'اقتراح الأماكن عندما أكون قريباً' : 'Suggest places when nearby',
                value: settings.suggestPlacesWhenNearby,
                onChanged: (val) => notifier.updateField('suggest_places_when_nearby', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Suggest from recent visits
              _buildToggleRow(
                iconPath: 'assets/setting/icons/toggle_base.svg',
                title: isAr ? 'الاقتراح من الزيارات الأخيرة' : 'Suggest from recent visits',
                value: settings.suggestFromRecentVisits,
                onChanged: (val) => notifier.updateField('suggest_from_recent_visits', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Use photo time & location
              _buildToggleRow(
                iconPath: 'assets/setting/icons/radios.svg',
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

  Widget _buildToggleRow({
    required String iconPath,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
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

          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
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

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(height: 1, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8)),
    );
  }
}
