import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/widgets/common/custom_loading_indicator.dart';
import '../auth/auth_flow_page.dart';

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
          'الحجوزات',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const CustomLoadingIndicator()
          : _bookings.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  color: const Color(0xFF7C57FC),
                  onRefresh: () => _fetchBookings(showLoader: false),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _bookings[index];
                      return _buildBookingCard(item, cardBg, borderColor, isDark);
                    },
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
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final bool isLoggedIn = user != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration / Icon with Alert badge matching Hungerstation
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/home/icons/booking_nav_icon.svg',
                      width: 50,
                      height: 50,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7C57FC),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'حجوزاتك ستظهر هنا',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isLoggedIn
                    ? 'ستظهر حجوزاتك السابقة والقادمة هنا فور قيامك بالحجز.'
                    : 'سجل الدخول لعرض حجوزاتك السابقة والقادمة.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (isLoggedIn) {
                    widget.onExploreTapped();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthFlowPage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLoggedIn ? 'استكشف الأماكن واحجز الآن' : 'تسجيل الدخول',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
