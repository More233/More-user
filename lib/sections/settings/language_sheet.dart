import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';

class LanguageSheet extends ConsumerStatefulWidget {
  const LanguageSheet({super.key});

  @override
  ConsumerState<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends ConsumerState<LanguageSheet> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(settingsProvider).preferredLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);
    final isAr = _selectedLanguage == 'ar';

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
          // Title/Header Row
          Row(
            children: [
              const Icon(Icons.language, color: Color(0xFF7C57FC), size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'اللغة' : 'Language',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    isAr
                        ? 'اختر لغة التطبيق المفضلة لديك.'
                        : 'Choose your preferred app language.',
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
          // English option
          _buildLanguageOption(
            title: 'English',
            subtitle: isAr ? 'اللغة الافتراضية' : 'Default language',
            value: 'en',
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Arabic option
          _buildLanguageOption(
            title: 'العربية',
            subtitle: isAr ? 'العربية (من اليمين لليسار)' : 'Arabic (RTL)',
            value: 'ar',
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Device language option
          _buildLanguageOption(
            title: isAr ? 'استخدام لغة الجهاز' : 'Use device language',
            subtitle: isAr
                ? 'مطابقة لغة الهاتف تلقائياً'
                : 'Automatically match your phone language',
            value: 'device',
          ),
          const SizedBox(height: 32),
          // Actions: Save & Cancel
          Row(
            children: [
              Expanded(
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
                    final navigator = Navigator.of(context);
                    await notifier.updateField('preferred_language', _selectedLanguage);
                    navigator.pop();
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
            ],
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
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedLanguage == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: const Color(0xFF909090),
                    ),
                  ),
                ],
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
}
