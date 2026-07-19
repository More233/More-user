import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/country_info.dart';

class CountryPicker extends StatelessWidget {
  final CountryInfo selectedCountry;
  final ValueChanged<CountryInfo> onCountryChanged;

  const CountryPicker({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  static const List<CountryInfo> countries = [
    CountryInfo(
      code: 'SA',
      dialCode: '+966',
      flagEmoji: '🇸🇦',
      name: 'Saudi Arabia',
      hintFormat: '5X XXX XXXX',
    ),
    CountryInfo(
      code: 'EG',
      dialCode: '+20',
      flagEmoji: '🇪🇬',
      name: 'Egypt',
      hintFormat: '1X XXX XXXXX',
    ),
    CountryInfo(
      code: 'AE',
      dialCode: '+971',
      flagEmoji: '🇦🇪',
      name: 'United Arab Emirates',
      hintFormat: '5X XXX XXXX',
    ),
  ];

  void _showSelectionBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bottomSheetBg = isDark ? const Color(0xFF131722) : Colors.white;
    final Color handleColor = isDark ? Colors.white24 : const Color(0xFFE8E8E8);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color textColor = isDark ? Colors.white70 : const Color(0xFF1A1A2E);
    final Color dialTextColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: bottomSheetBg,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Country',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              ...countries.map((country) {
                final isSelected = country.code == selectedCountry.code;
                return ListTile(
                  leading: Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country.name,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF7C57FC) : textColor,
                    ),
                  ),
                  trailing: Text(
                    country.dialCode,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF7C57FC) : dialTextColor,
                    ),
                  ),
                  onTap: () {
                    onCountryChanged(country);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color displayTextColor = isDark ? Colors.white : const Color(0xFF1F242E);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSelectionBottomSheet(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCountry.flagEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            selectedCountry.code,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: displayTextColor,
            ),
          ),
          const SizedBox(width: 4),
          SvgPicture.asset(
            'assets/Auth Section/icons/arrow_down.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              displayTextColor,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
