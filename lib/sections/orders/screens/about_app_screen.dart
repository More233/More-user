import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
          'حول تطبيق More',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Logo container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C57FC), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'More Delivery',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'الإصدار 2.4.0 (Build 2026.09)',
              style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'عن التطبيق',
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق More هو المنصة الرائدة لتوصيل الطعام والمأكولات في مصر والشرق الأوسط. نوفر لك تجربة طلب سريعة وذكية تجمع أشهر المطاعم العالمية والمحلية في مكان واحد مع تتبع حي ومباشر للمندوب حتى باب منزلك.',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, height: 1.6, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  _buildAboutTile(
                    icon: Icons.verified_user_outlined,
                    title: 'سياسة الخصوصية وأمان البيانات',
                    subtitle: 'كيف نحمي بياناتك ومعلوماتك',
                    textColor: textColor,
                    onTap: () {
                      _showPolicyDialog(
                        context,
                        'سياسة الخصوصية',
                        'نحن في More نلتزم بحماية خصوصيتك ومعلوماتك الشخصية. بيانات الدفع والموقع لا تتم مشاركتها إلا مع المندوب والمطعم لتوصيل طلبك بأمان.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildAboutTile(
                    icon: Icons.description_outlined,
                    title: 'شروط وأحكام الاستخدام',
                    subtitle: 'حقوق وواجبات المستخدم والمنصة',
                    textColor: textColor,
                    onTap: () {
                      _showPolicyDialog(
                        context,
                        'شروط الاستخدام',
                        'باستخدامك لتطبيق More، توافق على شروط الطلب والإلغاء والاسترجاع المعتمدة لضمان جودة وسرعة التوصيل للجميع.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildAboutTile(
                    icon: Icons.email_outlined,
                    title: 'تواصل معنا للدعم والاستفسارات',
                    subtitle: 'support@more.app',
                    textColor: textColor,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'جميع الحقوق محفوظة © 2026 More Inc.',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static void _showPolicyDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, textAlign: TextAlign.right, style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        content: Text(body, textAlign: TextAlign.right, style: GoogleFonts.ibmPlexSansArabic(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF7C57FC), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.grey),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF7C57FC).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF7C57FC), size: 18),
      ),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 13.5, color: textColor),
      ),
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.right,
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 11.5, color: Colors.grey),
      ),
    );
  }
}
