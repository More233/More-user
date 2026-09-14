import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../providers/delivery_orders_provider.dart';
import 'live_order_tracking_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty || cart.restaurant == null) return;

    final address = ref.read(currentAddressProvider);
    final user = Supabase.instance.client.auth.currentUser;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = Supabase.instance.client;

      // Generate a 4-digit OTP code for secure delivery handover
      final otpCode = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

      // 1. Insert into orders
      final orderRes = await client.from('orders').insert({
        'venue_id': cart.restaurant!.id,
        'user_id': user?.id,
        'items_total': cart.subtotal,
        'delivery_fee': cart.deliveryFee,
        'total_amount': cart.totalAmount,
        'delivery_latitude': address?.latitude ?? 24.7136,
        'delivery_longitude': address?.longitude ?? 46.6753,
        'delivery_address': address?.fullAddress ?? 'الرياض - الموقع الحالي',
        'customer_notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'status': 'received',
        'otp_code': otpCode,
        'estimated_prep_minutes': cart.restaurant!.deliveryTimeMax,
      }).select('id').single();

      final orderId = orderRes['id'];

      // 2. Insert order items
      final List<Map<String, dynamic>> itemsPayload = cart.items.map((ci) {
        return {
          'order_id': orderId,
          'menu_item_id': ci.item.id,
          'name': ci.item.name,
          'quantity': ci.quantity,
          'unit_price': ci.unitPrice,
          'total_price': ci.totalPrice,
          'selected_modifiers': ci.selectedModifiers.map((m) => m.toMap()).toList(),
        };
      }).toList();

      await client.from('order_items').insert(itemsPayload);

      // 3. Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      // 4. Navigate to live tracking screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveOrderTrackingScreen(
            orderId: orderId,
            restaurantName: cart.restaurant!.name,
            totalAmount: cart.totalAmount,
            otpCode: otpCode,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error placing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    final address = ref.watch(currentAddressProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'سلة الطلبات',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: textColor,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'السلة فارغة حالياً',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تصفح المطاعم وأضف وجباتك المفضلة',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Restaurant Header
                  if (cart.restaurant != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              cart.restaurant!.deliveryTimeFormatted,
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: const Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            cart.restaurant!.name,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.storefront_rounded, color: Color(0xFF7C57FC), size: 22),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Cart Items List
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : const Color(0xFFF1F1F1),
                      ),
                      itemBuilder: (context, idx) {
                        final ci = cart.items[idx];
                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity controller
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 16),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(ci.id, ci.quantity + 1);
                                      },
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '${ci.quantity}',
                                        style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 16),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(ci.id, ci.quantity - 1);
                                      },
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Item details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    ci.item.name,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: textColor,
                                    ),
                                  ),
                                  if (ci.selectedModifiers.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      ci.selectedModifiers.map((m) => m.name).join('، '),
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ci.totalPrice.toStringAsFixed(2)} ج.م',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7C57FC),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delivery Address Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'عنوان التوصيل',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_rounded, color: Color(0xFF10B981), size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address?.fullAddress ?? 'الرياض - حي النزهة',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                    ),
                    child: TextField(
                      controller: _notesController,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ملاحظات للمطعم أو المندوب (اختياري)',
                        hintStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 12.5),
                        border: InputBorder.none,
                        isDense: true,
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF7C57FC)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bill Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow('مجموع المنتجات', '${cart.subtotal.toStringAsFixed(2)} ج.م', textColor),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'رسوم التوصيل',
                          cart.deliveryFee == 0 ? 'مجاني' : '${cart.deliveryFee.toStringAsFixed(2)} ج.م',
                          cart.deliveryFee == 0 ? const Color(0xFF10B981) : textColor,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildPriceRow(
                          'المبلغ الإجمالي',
                          '${cart.totalAmount.toStringAsFixed(2)} ج.م',
                          const Color(0xFF7C57FC),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: cart.items.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF95700), // Vibrant Orange
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'تأكيد الطلب (${cart.totalAmount.toStringAsFixed(2)} ج.م)',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildPriceRow(String title, String value, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: isTotal ? 16 : 13.5,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: isTotal ? 15 : 13.5,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? const Color(0xFF1E2022) : Colors.grey,
          ),
        ),
      ],
    );
  }
}
