import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'live_order_tracking_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    try {
      final client = Supabase.instance.client;
      List<dynamic> data;
      if (user != null) {
        data = await client
            .from('orders')
            .select('*, venue:venues(id, name, logo_url)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(20);
      } else {
        data = await client
            .from('orders')
            .select('*, venue:venues(id, name, logo_url)')
            .order('created_at', ascending: false)
            .limit(20);
      }

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'received':
        return 'تم استلام الطلب';
      case 'preparing':
        return 'قيد التجهيز بالمطبخ';
      case 'on_the_way':
        return 'المندوب في الطريق';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'جاري المتابعة';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFFEA580C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'طلباتك',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C57FC)))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 14),
                      Text(
                        'لا توجد طلبات سابقة',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جميع طلباتك وتتبع مسارها ستظهر هنا',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: const Color(0xFF7C57FC),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final order = _orders[idx];
                      final venue = order['venue'] as Map<String, dynamic>?;
                      final restaurantName = venue?['name'] ?? 'المطعم';
                      final status = order['status']?.toString() ?? 'received';
                      final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                      final otp = order['otp_code']?.toString() ?? '1234';

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveOrderTrackingScreen(
                                orderId: order['id'],
                                restaurantName: restaurantName,
                                totalAmount: totalAmount,
                                otpCode: otp,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    restaurantName,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${totalAmount.toStringAsFixed(2)} ج.م',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7C57FC),
                                    ),
                                  ),
                                  Text(
                                    'كود الاستلام: $otp',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
