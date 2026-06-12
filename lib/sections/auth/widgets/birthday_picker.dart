import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BirthdayPicker {
  static Future<DateTime?> show(BuildContext context, DateTime? initialDate) async {
    DateTime selectedDate = initialDate ?? DateTime(2000, 1, 1);
    
    // We can show a styled DatePickerDialog or build a fully custom calendar dialog.
    // A fully custom calendar dialog matches the requested premium design exactly.
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final now = DateTime.now();
            final years = List.generate(100, (index) => now.year - index);
            final months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            
            // Calculate days in the selected month/year
            int daysInMonth = DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              title: Text(
                'Select Birthday',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year and Month Dropdowns
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Month Selector
                      DropdownButton<int>(
                        value: selectedDate.month,
                        dropdownColor: Colors.white,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              months[index],
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              int day = selectedDate.day;
                              int maxDays = DateUtils.getDaysInMonth(selectedDate.year, val);
                              if (day > maxDays) day = maxDays;
                              selectedDate = DateTime(selectedDate.year, val, day);
                            });
                          }
                        },
                      ),
                      // Year Selector
                      DropdownButton<int>(
                        value: selectedDate.year,
                        dropdownColor: Colors.white,
                        items: years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              int day = selectedDate.day;
                              int maxDays = DateUtils.getDaysInMonth(val, selectedDate.month);
                              if (day > maxDays) day = maxDays;
                              selectedDate = DateTime(val, selectedDate.month, day);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Grid of days
                  SizedBox(
                    width: 280,
                    height: 200,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: daysInMonth,
                      itemBuilder: (context, index) {
                        final dayNum = index + 1;
                        final isSelected = selectedDate.day == dayNum;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = DateTime(selectedDate.year, selectedDate.month, dayNum);
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              dayNum.toString(),
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, selectedDate),
                  child: Text(
                    'Select',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
