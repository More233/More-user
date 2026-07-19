import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class LocationSettingsScreen extends ConsumerWidget {
  const LocationSettingsScreen({super.key});

  void _showPermissionBottomSheet(BuildContext context, WidgetRef ref, bool isAr) {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    String selectedPerm = settings.locationPermission;

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
                  // Drag handle slider
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
                  // Header Row
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF7C57FC), size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'صلاحية الموقع' : 'Location Permission',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            isAr
                                ? 'إدارة صلاحيات الوصول لموقعك.'
                                : 'Manage your location access.',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF707070),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Options
                  _buildRadioOption(
                    title: isAr ? 'مطلقاً' : 'Never',
                    value: 'never',
                    currentValue: selectedPerm,
                    onTap: (val) => setState(() => selectedPerm = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  _buildRadioOption(
                    title: isAr ? 'السؤال في المرة القادمة أو عند المشاركة' : 'Ask Next Time Or when I Share',
                    value: 'ask_next_time',
                    currentValue: selectedPerm,
                    onTap: (val) => setState(() => selectedPerm = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  _buildRadioOption(
                    title: isAr ? 'أثناء استخدام التطبيق' : 'While Using the App',
                    value: 'while_using',
                    currentValue: selectedPerm,
                    onTap: (val) => setState(() => selectedPerm = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  _buildRadioOption(
                    title: isAr ? 'دائماً' : 'Always',
                    value: 'always',
                    currentValue: selectedPerm,
                    onTap: (val) => setState(() => selectedPerm = val),
                  ),
                  const SizedBox(height: 32),
                  // Buttons: Save & Cancel
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
                        await notifier.updateField('location_permission', selectedPerm);
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

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String currentValue,
    required ValueChanged<String> onTap,
  }) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onTap(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
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
    );
  }

  String _getPermissionText(String value, bool isAr) {
    switch (value) {
      case 'never':
        return isAr ? 'مطلقاً' : 'Never';
      case 'ask_next_time':
        return isAr ? 'عند الطلب' : 'Ask Next Time';
      case 'while_using':
        return isAr ? 'أثناء الاستخدام' : 'While Using';
      case 'always':
        return isAr ? 'دائماً' : 'Always';
      default:
        return isAr ? 'أثناء الاستخدام' : 'While Using';
    }
  }

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
            isAr ? 'الموقع والأماكن المجاورة' : 'Location & Nearby',
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
              _buildSectionHeader(isAr ? 'صلاحية الوصول للموقع' : 'Location access', isAr, isDark),
              // Permission selector row
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Color(0xFF7C57FC),
                  ),
                ),
                title: Text(
                  isAr ? 'إذن الموقع الجغرافي' : 'Location permission',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPermissionText(settings.locationPermission, isAr),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : const Color(0xFF909090),
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
                onTap: () => _showPermissionBottomSheet(context, ref, isAr),
              ),
              _buildDivider(isDark),
              // Precise Location toggle
              _buildToggleRow(
                icon: Icons.gps_fixed_outlined,
                title: isAr ? 'الموقع الدقيق' : 'Precise location',
                subtitle: isAr
                    ? 'تحسين دقة تحديد الموقع لتسجيلات الوصول والنتائج القريبة'
                    : 'Improve accuracy for check-ins and nearby results',
                value: settings.preciseLocation,
                onChanged: (val) => notifier.updateField('precise_location', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Show nearby spots toggle
              _buildToggleRow(
                icon: Icons.storefront_outlined,
                title: isAr ? 'إظهار الأماكن المجاورة' : 'Show nearby places',
                subtitle: isAr
                    ? 'استكشاف المحلات والمقاهي والأماكن من حولك'
                    : 'Discover shops, cafes, and spots around you',
                value: settings.showNearbyPlaces,
                onChanged: (val) => notifier.updateField('show_nearby_places', val),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              // Prompts when arrive toggle
              _buildToggleRow(
                icon: Icons.notifications_none_outlined,
                title: isAr ? 'موجهات تسجيلات الوصول القريبة' : 'Nearby check-in prompts',
                subtitle: isAr
                    ? 'الحصول على اقتراحات لتسجيل الوصول عند وصولك للأماكن'
                    : 'Get prompts to check in when you arrive',
                value: settings.nearbyCheckInPrompts,
                onChanged: (val) => notifier.updateField('nearby_check_in_prompts', val),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : const Color(0xFF888888),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
