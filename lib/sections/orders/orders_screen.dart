import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/widgets/common/custom_loading_indicator.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onExploreTapped;

  const OrdersScreen({
    super.key,
    required this.onExploreTapped,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedSegment = 0; // 0: Active, 1: Past
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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
        .channel('public:orders:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _fetchOrders(showLoader: false),
        )
        .subscribe();
  }

  Future<void> _fetchOrders({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await client
          .from('orders')
          .select('*, venues(name, address), couriers(full_name, phone, vehicle_type)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((o) {
      final status = o['status'] as String? ?? 'pending';
      final isActive = status != 'delivered' && status != 'cancelled';
      return _selectedSegment == 0 ? isActive : !isActive;
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
          'Orders',
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
                  _buildSegmentItem(0, 'Active Orders'),
                  _buildSegmentItem(1, 'Past Orders'),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const CustomLoadingIndicator()
                : _filteredOrders.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        color: const Color(0xFF7C57FC),
                        onRefresh: () => _fetchOrders(showLoader: false),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order, cardBg, borderColor, isDark);
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

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    Color cardBg,
    Color borderColor,
    bool isDark,
  ) {
    final venue = order['venues'] as Map<String, dynamic>? ?? {};
    final venueName = venue['name'] as String? ?? 'More Store';
    final total = order['total_amount']?.toString() ?? '0';
    final status = order['status'] as String? ?? 'pending';
    final otpCode = order['otp_code'] as String?;
    final courier = order['couriers'] as Map<String, dynamic>?;

    Color statusColor = const Color(0xFFF59E0B);
    String statusText = 'Received';
    if (status == 'accepted') {
      statusColor = const Color(0xFF3B82F6);
      statusText = 'Accepted';
    } else if (status == 'preparing') {
      statusColor = const Color(0xFF8B5CF6);
      statusText = 'Preparing...';
    } else if (status == 'ready_for_pickup') {
      statusColor = const Color(0xFF10B981);
      statusText = 'Ready for Pickup';
    } else if (status == 'picked_up') {
      statusColor = const Color(0xFF06B6D4);
      statusText = 'Out for Delivery';
    } else if (status == 'delivered') {
      statusColor = const Color(0xFF10B981);
      statusText = 'Delivered ✓';
    } else if (status == 'cancelled') {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Cancelled';
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$total SAR',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                ],
              ),
              if (otpCode != null && status != 'delivered' && status != 'cancelled')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7C57FC).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF7C57FC)),
                      const SizedBox(width: 6),
                      Text(
                        'Delivery OTP: $otpCode',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (courier != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining, color: Color(0xFF7C57FC), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Courier: ${courier['full_name'] ?? 'Assigned Driver'}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isActive = _selectedSegment == 0;
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
                  'assets/home/icons/order_nav_icon.svg',
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
              isActive ? 'No active orders' : 'No past orders',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Order meals, drinks, and favorites from top restaurants for fast delivery or pickup.'
                  : 'Your past orders and receipt history will appear here.',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isActive)
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
                    'Browse Menus & Order',
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
