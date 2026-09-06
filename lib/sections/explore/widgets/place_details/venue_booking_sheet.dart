import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VenueBookingSheet extends StatefulWidget {
  final String venueId;
  final String venueName;
  final String? venueCategory;
  final VoidCallback? onBookingSuccess;

  const VenueBookingSheet({
    super.key,
    required this.venueId,
    required this.venueName,
    this.venueCategory,
    this.onBookingSuccess,
  });

  static void show(
    BuildContext context, {
    required String venueId,
    required String venueName,
    String? venueCategory,
    VoidCallback? onBookingSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VenueBookingSheet(
        venueId: venueId,
        venueName: venueName,
        venueCategory: venueCategory,
        onBookingSuccess: onBookingSuccess,
      ),
    );
  }

  @override
  State<VenueBookingSheet> createState() => _VenueBookingSheetState();
}

class _VenueBookingSheetState extends State<VenueBookingSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '19:30';
  int _partySize = 2;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '12:00 PM',
    '1:30 PM',
    '3:00 PM',
    '6:00 PM',
    '7:30 PM',
    '8:30 PM',
    '9:30 PM',
    '10:30 PM',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _toIsoDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitBooking() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      final dateStr = _toIsoDate(_selectedDate);

      String targetVenueId = widget.venueId;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(targetVenueId);

      if (!isUuid) {
        final venues = await client.from('venues').select('id').limit(1);
        if (venues.isNotEmpty) {
          targetVenueId = venues[0]['id'].toString();
        } else {
          final newVenue = await client.from('venues').insert({
            'name': widget.venueName,
            'business_type': 'restaurant',
            'latitude': 24.7136,
            'longitude': 46.6753,
            'address': 'Riyadh, Saudi Arabia',
          }).select('id').single();
          targetVenueId = newVenue['id'].toString();
        }
      }

      await client.from('bookings').insert({
        'venue_id': targetVenueId,
        'user_id': user?.id,
        'booking_type': 'table',
        'booking_date': dateStr,
        'booking_time': _selectedTime,
        'party_size': _partySize,
        'special_requests': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;

      Navigator.pop(context);
      widget.onBookingSuccess?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reservation confirmed at ${widget.venueName}',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7C57FC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final cardBg = isDark ? const Color(0xFF181C26) : const Color(0xFFF7F8FA);
    final borderColor = isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8);
    final textColor = isDark ? Colors.white : const Color(0xFF1F242E);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset > 0 ? bottomInset + 20 : 36,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C354A) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.calendar_month, color: Color(0xFF7C57FC), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserve a Table',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        widget.venueName,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.6)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Picker Card
            Text(
              'Reservation Date',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFF7C57FC),
                          onPrimary: Colors.white,
                          surface: bgColor,
                          onSurface: textColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFF7C57FC), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(_selectedDate),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 14, color: textColor.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Time Slots
            Text(
              'Available Time',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((time) {
                final isSelected = _selectedTime == time;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTime = time);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7C57FC) : cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7C57FC) : borderColor,
                      ),
                    ),
                    child: Text(
                      time,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Party Size
            Text(
              'Party Size',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, color: Color(0xFF7C57FC), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '$_partySize ${_partySize == 1 ? 'Guest' : 'Guests'}',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_partySize > 1) {
                            HapticFeedback.lightImpact();
                            setState(() => _partySize--);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Icon(Icons.remove, size: 16, color: textColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          if (_partySize < 20) {
                            HapticFeedback.lightImpact();
                            setState(() => _partySize++);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C57FC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Special notes
            Text(
              'Special Requests (Optional)',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: 'e.g. outdoor seating, anniversary...',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      'Confirm Reservation',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
