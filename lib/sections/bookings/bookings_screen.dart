import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/widgets/common/custom_loading_indicator.dart';

class BookingsScreen extends StatefulWidget {
  final VoidCallback onExploreTapped;

  const BookingsScreen({
    super.key,
    required this.onExploreTapped,
  });

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedSegment = 0; // 0: Upcoming, 1: Past
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _setupRealtime() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    _subscription = client
        .channel('public:bookings:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _fetchBookings(showLoader: false),
        )
        .subscribe();
  }

  Future<void> _fetchBookings({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await client
          .from('bookings')
          .select('*, venues(name, address, business_type)')
          .eq('user_id', user.id)
          .order('booking_date', ascending: true);

      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      _fetchBookings(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking cancelled successfully',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    final now = DateTime.now();
    return _bookings.where((b) {
      final dateStr = b['booking_date'] as String? ?? '';
      final date = DateTime.tryParse(dateStr) ?? now;
      final status = b['status'] as String? ?? 'pending';
      final isFuture = date.isAfter(now.subtract(const Duration(days: 1))) &&
          status != 'cancelled' &&
          status != 'completed';
      return _selectedSegment == 0 ? isFuture : !isFuture;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final cardBg = isDark ? const Color(0xFF181C26) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildSegmentItem(0, 'Upcoming'),
                  _buildSegmentItem(1, 'Past'),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const CustomLoadingIndicator()
                : _filteredBookings.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        color: const Color(0xFF7C57FC),
                        onRefresh: () => _fetchBookings(showLoader: false),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _filteredBookings.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _filteredBookings[index];
                            return _buildBookingCard(item, cardBg, borderColor, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(int index, String title) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> item,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final venue = item['venues'] as Map<String, dynamic>? ?? {};
    final venueName = venue['name'] as String? ?? 'More Venue';
    final address = venue['address'] as String? ?? '';
    final date = item['booking_date'] as String? ?? '';
    final time = item['booking_time'] as String? ?? '';
    final partySize = item['party_size']?.toString() ?? '1';
    final status = item['status'] as String? ?? 'pending';
    final bookingType = item['booking_type'] as String? ?? 'Table';

    Color statusColor = const Color(0xFFF59E0B);
    String statusText = 'Pending';
    if (status == 'confirmed') {
      statusColor = const Color(0xFF10B981);
      statusText = 'Confirmed ✓';
    } else if (status == 'rejected' || status == 'cancelled') {
      statusColor = const Color(0xFFEF4444);
      statusText = status == 'cancelled' ? 'Cancelled' : 'Rejected';
    } else if (status == 'completed') {
      statusColor = const Color(0xFF7C57FC);
      statusText = 'Completed';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  venueName,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              address,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Date & Time', '$date • $time', Icons.access_time, isDark),
              _buildInfoColumn('Guests', '$partySize ${partySize == '1' ? 'Guest' : 'Guests'}', Icons.people_outline, isDark),
              _buildInfoColumn('Type', bookingType[0].toUpperCase() + bookingType.substring(1), Icons.bookmark_border, isDark),
            ],
          ),
          if (status == 'pending' || status == 'confirmed') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => _cancelBooking(item['id'].toString()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Cancel Booking',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isUpcoming = _selectedSegment == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF7C57FC).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/home/icons/booking_nav_icon.svg',
                  width: 36,
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7C57FC),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isUpcoming ? 'No upcoming reservations' : 'No past reservations',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                  ? 'Book tables at your favorite spots, reserve hotel stays, or plan venue visits effortlessly.'
                  : 'Your completed and past reservations will appear here.',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isUpcoming)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.onExploreTapped,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    elevation: 0,
                  ),
                  child: Text(
                    'Find Places to Reserve',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
