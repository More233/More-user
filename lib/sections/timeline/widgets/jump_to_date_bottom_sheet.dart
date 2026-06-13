import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JumpToDateBottomSheet extends StatefulWidget {
  final DateTime initialDate;

  const JumpToDateBottomSheet({super.key, required this.initialDate});

  @override
  State<JumpToDateBottomSheet> createState() => _JumpToDateBottomSheetState();
}

class _JumpToDateBottomSheetState extends State<JumpToDateBottomSheet> {
  late int _showingYear;
  late int _showingMonth;
  DateTime? _selectedDate;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    _showingYear = widget.initialDate.year;
    _showingMonth = widget.initialDate.month;
    _selectedDate = widget.initialDate;
  }

  void _goToPrevMonth() {
    setState(() {
      if (_showingMonth == 1) {
        _showingMonth = 12;
        _showingYear--;
      } else {
        _showingMonth--;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_showingMonth == 12) {
        _showingMonth = 1;
        _showingYear++;
      } else {
        _showingMonth++;
      }
    });
  }

  List<DateTime?> _generateDays() {
    final days = <DateTime?>[];
    final firstDayOfMonth = DateTime(_showingYear, _showingMonth, 1);
    
    // In Dart: 1 = Monday, 7 = Sunday
    // Since our week starts on Monday, empty slots = firstDayOfMonth.weekday - 1
    int emptySlots = firstDayOfMonth.weekday - 1;
    for (int i = 0; i < emptySlots; i++) {
      days.add(null);
    }
    
    final totalDays = DateTime(_showingYear, _showingMonth + 1, 0).day;
    for (int i = 1; i <= totalDays; i++) {
      days.add(DateTime(_showingYear, _showingMonth, i));
    }
    
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _generateDays();
    final monthName = _months[_showingMonth - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle / Slider
          Center(
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC1C1C1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header Title
          Text(
            'Jump to Date',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),

          // Calendar Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Month Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Month/Year indicator Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x0D000000), // 5% black
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$monthName $_showingYear',
                            style: GoogleFonts.figtree(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    
                    // Month navigation buttons
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _goToPrevMonth,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0x0D000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _goToNextMonth,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0x0D000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weekday Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdays.map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.figtree(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final date = days[index];
                    if (date == null) {
                      return const SizedBox();
                    }

                    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
                    final isToday = _isSameDay(date, today);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: GoogleFonts.figtree(
                              fontSize: isSelected ? 20 : 18,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday ? const Color(0xFF007AFF) : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Button
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context, _selectedDate);
                },
                child: Text(
                  'Jump to Date',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
