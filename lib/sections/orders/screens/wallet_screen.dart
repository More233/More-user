import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

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
                        '150.00',
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
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('شحن المحفظة قريباً', textAlign: TextAlign.right, style: GoogleFonts.ibmPlexSansArabic()),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF4C1D95)),
                          label: Text(
                            'شحن الرصيد',
                            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, color: const Color(0xFF4C1D95)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
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
              'العمليات الأخيرة',
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
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTxTile('شحن رصيد عن طريق Apple Pay', '+150.00 ج.م', 'اليوم، 02:15 م', true, textColor),
                  const Divider(height: 1),
                  _buildTxTile('طلب من مطعم بلبن', '-85.00 ج.م', 'أمس، 09:30 م', false, textColor),
                  const Divider(height: 1),
                  _buildTxTile('استرداد نقدي (Cashback)', '+20.00 ج.م', '10 سبتمبر 2026', true, textColor),
                ],
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
