import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BirthdayStep extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(DateTime birthday) onCompleted;

  const BirthdayStep({
    super.key,
    required this.onBack,
    required this.onCompleted,
  });

  @override
  State<BirthdayStep> createState() => _BirthdayStepState();
}

class _BirthdayStepState extends State<BirthdayStep> {
  int _selectedDay = 18;
  int _selectedMonth = 10; // October
  int _selectedYear = 2006;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  final int _startYear = 1940;
  final int _endYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _selectedYear - _startYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDays() {
    final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > maxDays) {
      setState(() {
        _selectedDay = maxDays;
        _dayController.jumpToItem(maxDays - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    final daysList = List.generate(maxDays, (index) => index + 1);
    final yearsList = List.generate(_endYear - _startYear + 1, (index) => _startYear + index);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color subtitleColor = isDark ? Colors.white70 : const Color(0xFF9CA3AF);
    final Color pickerCardBg = isDark ? const Color(0xFF1E2433) : const Color(0xFFFCFCFD);
    final Color pickerCardBorder = isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8);
    final Color privacyBannerBg = isDark ? const Color(0xFF1E2433) : const Color(0xFFF5F3FF);
    final Color privacyBannerBorder = isDark ? const Color(0xFF2C354A) : const Color(0xFFEDE9FE);
    final Color privacyTextColor = isDark ? const Color(0xFF9086E8) : const Color(0xFF5B4FB3);
    final Color bottomSheetBg = isDark ? const Color(0xFF131722) : Colors.white;
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/Auth Section/icons/arrow_left.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : const Color(0xFF1A1A2E),
              BlendMode.srcIn,
            ),
          ),
          onPressed: widget.onBack,
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/Splash/logo.svg',
          width: 120,
          height: 38,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Color(0xFF7C57FC),
            BlendMode.srcIn,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Text(
                'Basic information',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us a little about your birthday.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 36),
              // Cupertino Picker Outer Card Container
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: pickerCardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: pickerCardBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background highlights overlay for selected item row
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Row(
                        children: [
                          // Day Picker
                          Expanded(
                            flex: 2,
                            child: CupertinoPicker(
                              scrollController: _dayController,
                              itemExtent: 44,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedDay = daysList[index];
                                });
                              },
                              children: daysList.map((day) {
                                return Center(
                                  child: Text(
                                    day.toString(),
                                    style: TextStyle(
                                      color: _selectedDay == day
                                          ? const Color(0xFF7C57FC)
                                          : const Color(0xFF9CA3AF),
                                      fontWeight: _selectedDay == day
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // Month Picker
                          Expanded(
                            flex: 3,
                            child: CupertinoPicker(
                              scrollController: _monthController,
                              itemExtent: 44,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedMonth = index + 1;
                                  _updateDays();
                                });
                              },
                              children: _months.map((month) {
                                final isSel = _months[_selectedMonth - 1] == month;
                                return Center(
                                  child: Text(
                                    month,
                                    style: TextStyle(
                                      color: isSel
                                          ? const Color(0xFF7C57FC)
                                          : const Color(0xFF9CA3AF),
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // Year Picker
                          Expanded(
                            flex: 2,
                            child: CupertinoPicker(
                              scrollController: _yearController,
                              itemExtent: 44,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedYear = yearsList[index];
                                  _updateDays();
                                });
                              },
                              children: yearsList.map((year) {
                                return Center(
                                  child: Text(
                                    year.toString(),
                                    style: TextStyle(
                                      color: _selectedYear == year
                                          ? const Color(0xFF7C57FC)
                                          : const Color(0xFF9CA3AF),
                                      fontWeight: _selectedYear == year
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tip / privacy info banner below picker
              Container(
                decoration: BoxDecoration(
                  color: privacyBannerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: privacyBannerBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE6FC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF7C57FC),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Your birthday won't be shown publicly.",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: privacyTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => widget.onCompleted(DateTime(_selectedYear, _selectedMonth, _selectedDay)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Center "Why do you ask for this?"
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Show a styled sheet or dialog explaining why we ask for birthday
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: bottomSheetBg,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why we ask for this',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'We use your birthday to help customize your experience on More, protect younger users, and comply with age requirements.',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 15,
                                  color: textMutedColor,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C57FC),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Got it',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    'Why do you ask for this?',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
