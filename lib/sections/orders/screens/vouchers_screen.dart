import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final TextEditingController _voucherController = TextEditingController();

  final List<Map<String, dynamic>> _vouchers = [
    {
      'code': 'MORE50',
      'title': 'خصم 50% على طلبك الأول',
      'discount': '50% خصم',
      'expiry': 'صالحة حتى 30 سبتمبر 2026',
      'minOrder': 'بحد أدنى 60 ج.م للطلب',
      'isNew': true,
      'color': const Color(0xFF7C57FC),
    },
    {
      'code': 'FREEDEL',
      'title': 'توصيل مجاني لطلبك القادم',
      'discount': 'توصيل مجاني',
      'expiry': 'صالحة حتى 20 سبتمبر 2026',
      'minOrder': 'بحد أدنى 80 ج.م للطلب',
      'isNew': false,
      'color': const Color(0xFF10B981),
    },
    {
      'code': 'WEEKEND25',
      'title': 'عرض الويكند - خصم 25%',
      'discount': '25% خصم',
      'expiry': 'ساري أيام الجمعة والسبت',
      'minOrder': 'على المطاعم المختارة',
      'isNew': false,
      'color': const Color(0xFFEA580C),
    },
    {
      'code': 'BLABAN15',
      'title': 'خصم خاص 15% من حلويات بلبن',
      'discount': '15% خصم',
      'expiry': 'صالحة حتى 15 أكتوبر 2026',
      'minOrder': 'على جميع فروع بلبن',
      'isNew': false,
      'color': const Color(0xFFEC4899),
    },
  ];

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    HapticFeedback.mediumImpact();
    // Check if code exists or add it
    final existingIndex = _vouchers.indexWhere((v) => v['code'] == code);
    if (existingIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('القسيمة $code مفعلة وموجودة بالفعل في قائمتك!', textAlign: TextAlign.right, style: GoogleFonts.ibmPlexSansArabic()),
          backgroundColor: const Color(0xFF7C57FC),
        ),
      );
    } else {
      setState(() {
        _vouchers.insert(0, {
          'code': code,
          'title': 'قسيمة خصم مخصصة: $code',
          'discount': '20% خصم',
          'expiry': 'صالحة حتى 31 أكتوبر 2026',
          'minOrder': 'صالحة على جميع المأكولات',
          'isNew': true,
          'color': const Color(0xFF7C57FC),
        });
        _voucherController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة القسيمة $code بنجاح! 🎉', textAlign: TextAlign.right, style: GoogleFonts.ibmPlexSansArabic()),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _copyCode(String code) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ رمز القسيمة: $code', textAlign: TextAlign.right, style: GoogleFonts.ibmPlexSansArabic()),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E2022),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'قسائم الخصم والكوبونات',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Voucher Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'تطبيق',
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _voucherController,
                      textAlign: TextAlign.right,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'أدخل رمز القسيمة (مثال: MORE50)',
                        hintStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.confirmation_number_outlined, color: Color(0xFF7C57FC), size: 24),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'القسائم المتاحة بحسابك (${_vouchers.length})',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vouchers.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) {
                final v = _vouchers[i];
                final color = v['color'] as Color;

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                v['discount'] as String,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: color,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (v['isNew'] == true) ...[
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEA580C),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'جديد',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                      Text(
                                        v['title'] as String,
                                        style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 14.5, color: textColor),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    v['minOrder'] as String,
                                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    v['expiry'] as String,
                                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFBFBFB),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _copyCode(v['code'] as String),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF7C57FC)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'نسخ الرمز',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C57FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                v['code'] as String,
                                style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
