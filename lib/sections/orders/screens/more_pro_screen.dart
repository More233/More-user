import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MoreProScreen extends StatefulWidget {
  final bool initialIsPro;
  final ValueChanged<bool>? onProStatusChanged;

  const MoreProScreen({
    super.key,
    this.initialIsPro = false,
    this.onProStatusChanged,
  });

  @override
  State<MoreProScreen> createState() => _MoreProScreenState();
}

class _MoreProScreenState extends State<MoreProScreen> {
  int _selectedPlanIndex = 0; // 0: Monthly, 1: Annual
  bool _isProActive = false;

  @override
  void initState() {
    super.initState();
    _isProActive = widget.initialIsPro;
  }

  void _handleSubscribe() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isProActive = true;
    });
    widget.onProStatusChanged?.call(true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'أهلاً بك في عالم More Pro! 👑',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'تم تفعيل اشتراكك بنجاح. استمتع الآن بتوصيل مجاني غير محدود وخصومات حصرية 20% على طلباتك القادمة.',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C57FC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('ابدأ الطلب الآن', style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold)),
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
          onPressed: () => Navigator.pop(context, _isProActive),
        ),
        title: Text(
          'عضوية More Pro',
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
            // Hero VIP Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C57FC), Color(0xFF4338CA), Color(0xFF312E81)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MORE PRO',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 36),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isProActive ? 'أنت مشترك في More Pro 👑' : 'تجربة توصيل استثنائية بلا حدود',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'وفر أكثر من 300 ج.م شهرياً مع باقات التوصيل المجاني والخصومات الحصرية من أشهر المطاعم.',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'مميزات عضوية More Pro',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 14),

            _buildBenefitItem(
              icon: Icons.delivery_dining_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'توصيل مجاني غير محدود',
              subtitle: 'على جميع الطلبات بقيمة 80 ج.م أو أكثر من المطاعم المميزة',
              cardBg: cardBg,
              textColor: textColor,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildBenefitItem(
              icon: Icons.percent_rounded,
              iconColor: const Color(0xFFEA580C),
              title: 'خصم إضافي حتى 20%',
              subtitle: 'أسعار مخفضة حصرياً لأعضاء Pro تظهر باللون البنفسجي',
              cardBg: cardBg,
              textColor: textColor,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildBenefitItem(
              icon: Icons.flash_on_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'أولوية في التجهيز والتوصيل',
              subtitle: 'يصلك طلبك ساخناً وفي وقت أسرع مع أفضل المناديب',
              cardBg: cardBg,
              textColor: textColor,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildBenefitItem(
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFF7C57FC),
              title: 'ضعف نقاط المكافآت (2X)',
              subtitle: 'اجمع نقاطاً مضاعفة مع كل طلب لاستبدالها بقسائم وهدايا',
              cardBg: cardBg,
              textColor: textColor,
              isDark: isDark,
            ),

            const SizedBox(height: 30),

            if (!_isProActive) ...[
              Text(
                'اختر خطة الاشتراك المناسبة',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  // Monthly
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlanIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _selectedPlanIndex == 0 ? const Color(0xFF7C57FC) : (isDark ? Colors.white12 : Colors.grey.shade300),
                            width: _selectedPlanIndex == 0 ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('شهري', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                            const SizedBox(height: 6),
                            Text('49 ج.م', style: GoogleFonts.spaceMono(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF7C57FC))),
                            const SizedBox(height: 4),
                            Text('شهرياً تجدد تلقائياً', style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Annual
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlanIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _selectedPlanIndex == 1 ? const Color(0xFF7C57FC) : (isDark ? Colors.white12 : Colors.grey.shade300),
                            width: _selectedPlanIndex == 1 ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'توفير 35%',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text('سنوي', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                                const SizedBox(height: 6),
                                Text('399 ج.م', style: GoogleFonts.spaceMono(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF7C57FC))),
                                const SizedBox(height: 4),
                                Text('33 ج.م / شهر فقط', style: GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'اشترك الآن واستمتع بخصومات Pro',
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('اشتراكك نشط حالياً', style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF065F46))),
                          Text('التجديد القادم في 14 أكتوبر 2026', style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: const Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 14.5, color: textColor), textAlign: TextAlign.right),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: Colors.grey), textAlign: TextAlign.right),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }
}
