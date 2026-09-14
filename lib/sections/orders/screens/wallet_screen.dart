import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 250.00;

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'شحن رصيد عن طريق Apple Pay',
      'amount': '+150.00 ج.م',
      'date': 'اليوم، 02:15 م',
      'isPositive': true,
      'type': 'topup',
    },
    {
      'title': 'طلب من مطعم بلبن',
      'amount': '-85.00 ج.م',
      'date': 'أمس، 09:30 م',
      'isPositive': false,
      'type': 'order',
    },
    {
      'title': 'استرداد نقدي (Cashback 10%)',
      'amount': '+20.00 ج.م',
      'date': '10 سبتمبر 2026',
      'isPositive': true,
      'type': 'cashback',
    },
    {
      'title': 'طلب من بازوكا فاميلي',
      'amount': '-165.00 ج.م',
      'date': '06 سبتمبر 2026',
      'isPositive': false,
      'type': 'order',
    },
    {
      'title': 'شحن رصيد ترحيبي للمحفظة',
      'amount': '+100.00 ج.م',
      'date': '01 سبتمبر 2026',
      'isPositive': true,
      'type': 'topup',
    },
  ];

  void _showTopUpSheet() {
    HapticFeedback.lightImpact();
    double selectedAmount = 100.0;
    String selectedMethod = 'Apple Pay';
    final customCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Text(
                      'شحن رصيد المحفظة',
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'اختر المبلغ المطلوب شحنه',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),

                // Amount presets
                Row(
                  children: [50, 100, 200, 500].map((amt) {
                    final isSel = selectedAmount == amt.toDouble() && customCtrl.text.isEmpty;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedAmount = amt.toDouble();
                            customCtrl.clear();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF7C57FC) : (isDark ? Colors.white10 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel ? const Color(0xFF7C57FC) : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$amt',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isSel ? Colors.white : textColor,
                                ),
                              ),
                              Text(
                                'ج.م',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  color: isSel ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                Text(
                  'طريقة الدفع',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 10),

                _buildPaymentOption(
                  id: 'Apple Pay',
                  title: 'Apple Pay',
                  icon: Icons.apple,
                  isSelected: selectedMethod == 'Apple Pay',
                  onTap: () => setSheetState(() => selectedMethod = 'Apple Pay'),
                  textColor: textColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  id: 'Card',
                  title: 'بطاقة بنكية (Visa / Mastercard)',
                  icon: Icons.credit_card_rounded,
                  isSelected: selectedMethod == 'Card',
                  onTap: () => setSheetState(() => selectedMethod = 'Card'),
                  textColor: textColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  id: 'Vodafone Cash',
                  title: 'محفظة إلكترونية (فودافون كاش / اتصالات / أورنج)',
                  icon: Icons.phone_android_rounded,
                  isSelected: selectedMethod == 'Vodafone Cash',
                  onTap: () => setSheetState(() => selectedMethod = 'Vodafone Cash'),
                  textColor: textColor,
                  isDark: isDark,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final topupAmount = customCtrl.text.isNotEmpty
                          ? (double.tryParse(customCtrl.text) ?? selectedAmount)
                          : selectedAmount;

                      Navigator.pop(ctx);
                      _executeTopup(topupAmount, selectedMethod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'تأكيد وشحن $selectedAmount ج.م',
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _executeTopup(double amount, String method) {
    HapticFeedback.heavyImpact();
    setState(() {
      _balance += amount;
      _transactions.insert(0, {
        'title': 'شحن رصيد عن طريق $method',
        'amount': '+${amount.toStringAsFixed(2)} ج.م',
        'date': 'الآن',
        'isPositive': true,
        'type': 'topup',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم شحن ${amount.toStringAsFixed(2)} ج.م بنجاح إلى محفظتك! 🎉',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Widget _buildPaymentOption({
    required String id,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C57FC) : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFF7C57FC) : Colors.grey,
              size: 20,
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 20, color: const Color(0xFF7C57FC)),
          ],
        ),
      ),
    );
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
          'More Pay',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C57FC), Color(0xFF4C1D95)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'محفظة More',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'الرصيد المتاح',
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ج.م',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _balance.toStringAsFixed(2),
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showTopUpSheet,
                          icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF4C1D95)),
                          label: Text(
                            'شحن الرصيد',
                            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, color: const Color(0xFF4C1D95)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'العمليات الأخيرة (${_transactions.length})',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final tx = _transactions[i];
                  return _buildTxTile(
                    tx['title'] as String,
                    tx['amount'] as String,
                    tx['date'] as String,
                    tx['isPositive'] as bool,
                    textColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTxTile(String title, String amount, String date, bool isPositive, Color textColor) {
    return ListTile(
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 13.5, color: textColor),
      ),
      subtitle: Text(
        date,
        textAlign: TextAlign.right,
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: Colors.grey),
      ),
      leading: Text(
        amount,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48),
        ),
      ),
    );
  }
}
