import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _userPoints = 350;
  final String _tier = 'الفئة الفضية';

  final List<Map<String, dynamic>> _availableRewards = [
    {
      'id': '1',
      'title': 'خصم 20 ج.م على طلبك القادم',
      'subtitle': 'ساري على جميع المطاعم بحد أدنى 100 ج.م',
      'cost': 150,
      'code': 'REW20',
      'icon': Icons.discount_rounded,
    },
    {
      'id': '2',
      'title': 'توصيل مجاني غير محدود لطلب واحد',
      'subtitle': 'ساري على أي مطعم قريب منك',
      'cost': 120,
      'code': 'FREESHIP',
      'icon': Icons.delivery_dining_rounded,
    },
    {
      'id': '3',
      'title': 'خصم 50 ج.م على وجبات العائلة',
      'subtitle': 'ساري بحد أدنى للطلب 250 ج.م',
      'cost': 300,
      'code': 'FAMILY50',
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'id': '4',
      'title': 'وجبة حلوى مجانية من بلبن',
      'subtitle': 'قشطوطة لوتس أو مانجو مجاناً مع طلبك',
      'cost': 220,
      'code': 'BLABANGIFT',
      'icon': Icons.cake_rounded,
    },
  ];

  final List<Map<String, dynamic>> _pointsHistory = [
    {
      'title': 'طلب من مطعم بلبن',
      'points': '+35 نقطة',
      'date': 'أمس، 09:30 م',
      'isPositive': true,
    },
    {
      'title': 'مكافأة ترحيبية بتسجيل الحساب',
      'points': '+200 نقطة',
      'date': '01 سبتمبر 2026',
      'isPositive': true,
    },
    {
      'title': 'طلب من بازوكا فاميلي',
      'points': '+115 نقطة',
      'date': '28 أغسطس 2026',
      'isPositive': true,
    },
  ];

  void _redeemReward(Map<String, dynamic> reward) {
    final cost = reward['cost'] as int;
    if (_userPoints < cost) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'عذراً، لا تمتلك رصيد نقاط كافي لهذا العرض',
            textAlign: TextAlign.right,
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _userPoints -= cost;
      _pointsHistory.insert(0, {
        'title': 'استبدال: ${reward['title']}',
        'points': '-$cost نقطة',
        'date': 'الآن',
        'isPositive': false,
      });
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تم استبدال المكافأة بنجاح! 🎉',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'حصلت على: ${reward['title']}',
              textAlign: TextAlign.right,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C57FC).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C57FC), size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: reward['code'] as String));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ الرمز: ${reward['code']}', textAlign: TextAlign.right),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  Text(
                    reward['code'] as String,
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'تم حفظ الكود في قائمة القسائم الخاصة بك لتطبيقه عند الشراء.',
              textAlign: TextAlign.right,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C57FC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('رائع', style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
          'مكافآت More',
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
            // Points Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
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
                        child: Text(
                          _tier,
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 30),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'رصيد نقاطك الحالي',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'نقطة',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_userPoints',
                        style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_userPoints / 600).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تبقى ${(600 - _userPoints).clamp(0, 600)} نقطة للوصول للفئة الذهبية',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            Text(
              'استبدل نقاطك بقسائم وخصومات',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableRewards.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final reward = _availableRewards[i];
                final cost = reward['cost'] as int;
                final canAfford = _userPoints >= cost;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _redeemReward(reward),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canAfford ? const Color(0xFF7C57FC) : Colors.grey.shade400,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'استبدال',
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              reward['title'] as String,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 14, color: textColor),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              reward['subtitle'] as String,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.ibmPlexSansArabic(fontSize: 11.5, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$cost نقطة',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEA580C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(reward['icon'] as IconData, color: const Color(0xFF7C57FC), size: 22),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            Text(
              'سجل النقاط',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
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
                itemCount: _pointsHistory.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _pointsHistory[i];
                  final isPos = item['isPositive'] as bool;
                  return ListTile(
                    title: Text(
                      item['title'] as String,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 13.5, color: textColor),
                    ),
                    subtitle: Text(
                      item['date'] as String,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: Colors.grey),
                    ),
                    leading: Text(
                      item['points'] as String,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isPos ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
