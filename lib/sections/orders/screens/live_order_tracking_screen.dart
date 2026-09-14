import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveOrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final String restaurantName;
  final double totalAmount;
  final String otpCode;

  const LiveOrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.restaurantName,
    required this.totalAmount,
    required this.otpCode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'متابعة الطلب',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: textColor,
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Success animation or icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تم استلام طلبك بنجاح!',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'المطعم يقوم بمراجعة الطلب وتحضيره لك الآن',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 24),

            // OTP Code Card for Safe Handover
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFEDD5), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'كود استلام الطلب من المندوب (OTP)',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF9A3412),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      otpCode,
                      style: GoogleFonts.spaceMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'شارك هذا الكود مع المندوب عند وصوله لاستلام وجبتك',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11,
                      color: const Color(0xFF78350F).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order Status Pipeline Timeline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'حالة الطلب',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildTimelineStep('تم استلام الطلب', 'المطعم استلم تفاصيل الوجبات', true, true, isDark),
                  _buildTimelineStep('قيد التجهيز في المطبخ', 'يتم تحضير المكونات وتغليفها بعناية', true, false, isDark),
                  _buildTimelineStep('المندوب في الطريق إليك', 'سيتواصل معك عند الاقتراب من موقعك', false, false, isDark),
                  _buildTimelineStep('تم التوصيل', 'بالهناء والشفاء!', false, false, isDark, isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${totalAmount.toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                  Text(
                    'مطعم $restaurantName',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Back to Home Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: Text(
                  'العودة للرئيسية',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool isCompleted,
    bool isActive,
    bool isDark, {
    bool isLast = false,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content (RTL)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: isActive || isCompleted ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFFEA580C)
                      : (isCompleted ? textColor : Colors.grey),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // Indicator and Line
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : (isActive ? const Color(0xFFEA580C) : Colors.grey.withValues(alpha: 0.3)),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isActive
                      ? const Center(
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
          ],
        ),
      ],
    );
  }
}
