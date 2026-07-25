import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:country_code_picker/country_code_picker.dart';
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
      flagUri: 'flags/sa.png',
    ),
    CountryInfo(
      code: 'EG',
      dialCode: '+20',
      flagEmoji: '🇪🇬',
      name: 'Egypt',
      hintFormat: '1X XXX XXXXX',
      flagUri: 'flags/eg.png',
    ),
    CountryInfo(
      code: 'AE',
      dialCode: '+971',
      flagEmoji: '🇦🇪',
      name: 'United Arab Emirates',
      hintFormat: '5X XXX XXXX',
      flagUri: 'flags/ae.png',
    ),
  ];

  void _showSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerBottomSheet(
        selectedCountryCode: selectedCountry.code,
        onSelect: (countryCode) {
          onCountryChanged(
            CountryInfo(
              code: countryCode.code ?? 'SA',
              dialCode: countryCode.dialCode ?? '+966',
              flagEmoji: '',
              name: countryCode.name ?? '',
              hintFormat: 'X XXX XXXX',
              flagUri: countryCode.flagUri,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color displayTextColor = isDark ? Colors.white : const Color(0xFF1F242E);
    final String flagAsset = 'flags/${selectedCountry.code.toLowerCase()}.png';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSelectionBottomSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                flagAsset,
                package: 'country_code_picker',
                width: 26,
                height: 18,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    selectedCountry.flagEmoji,
                    style: const TextStyle(fontSize: 18),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedCountry.code,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: displayTextColor,
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              'assets/Auth Section/icons/arrow_down.svg',
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(
                displayTextColor,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerBottomSheet extends StatefulWidget {
  final String selectedCountryCode;
  final ValueChanged<CountryCode> onSelect;

  const _CountryPickerBottomSheet({
    required this.selectedCountryCode,
    required this.onSelect,
  });

  @override
  State<_CountryPickerBottomSheet> createState() => _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<_CountryPickerBottomSheet> {
  late List<CountryCode> _allCountries;
  late List<CountryCode> _filteredCountries;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Populate all countries from country_code_picker
    _allCountries = codes.map((json) => CountryCode.fromJson(json)).toList();
    _filteredCountries = List.from(_allCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredCountries = List.from(_allCountries);
      } else {
        _filteredCountries = _allCountries.where((c) {
          final name = (c.name ?? '').toLowerCase();
          final code = (c.code ?? '').toLowerCase();
          final dialCode = (c.dialCode ?? '').toLowerCase();
          return name.contains(q) || code.contains(q) || dialCode.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF131722) : Colors.white;
    final Color handleColor = isDark ? Colors.white24 : const Color(0xFFE8E8E8);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color dialTextColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    final Color inputBg = isDark ? const Color(0xFF1F242E) : const Color(0xFFF3F4F6);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Select Country',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCountries,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      color: dialTextColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: dialTextColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final isSelected = country.code == widget.selectedCountryCode;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          country.flagUri!,
                          package: 'country_code_picker',
                          width: 28,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 20),
                        ),
                      ),
                      title: Text(
                        country.name ?? '',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF7C57FC) : textColor,
                        ),
                      ),
                      trailing: Text(
                        country.dialCode ?? '',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF7C57FC) : dialTextColor,
                        ),
                      ),
                      onTap: () {
                        widget.onSelect(country);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
