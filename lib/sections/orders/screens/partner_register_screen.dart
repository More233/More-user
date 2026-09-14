import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();

  String _selectedCategory = 'مطعم ومأكولات سريعة';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'مطعم ومأكولات سريعة',
    'حلويات ومخبوزات',
    'كافيه ومشروبات',
    'سوبرماركت وبقالة',
    'أسماك ومأكولات بحرية',
    'مشويات وشاورما',
  ];

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      // Save application ticket into reports/feedbacks table so it appears in dashboard
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': user?.id,
        'reporter_name': _ownerNameCtrl.text.trim(),
        'reported_name': _businessNameCtrl.text.trim(),
        'reported_type': 'partner_application',
        'reason': 'طلب انضمام شريك جديد: النشاط: $_selectedCategory | هاتف: ${_phoneCtrl.text.trim()} | بريد: ${_emailCtrl.text.trim()} | مدينة: ${_cityCtrl.text.trim()}',
        'status': 'pending',
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'تم استلام طلبك بنجاح! 🚀',
                style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            ],
          ),
          content: Text(
            'شكراً لاهتمامك بالانضمام لمنصة More. سيقوم فريق الشركاء والعمليات بالتواصل معك هاتفياً خلال 24 ساعة لاستكمال إجراءات التعاقد واستلام حساب الدخول للوحة تحكم المطعم.',
            textAlign: TextAlign.right,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('حسناً', style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الطلب: $e', textAlign: TextAlign.right),
          backgroundColor: Colors.red,
        ),
      );
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'انضم كشريك في More',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C57FC), Color(0xFF4C1D95)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'زد من مبيعات مطعمك مع More',
                      style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'انضم لآلاف المطاعم والمتاجر التي تثق بمنصة More للوصول إلى عملاء جدد وإدارة الطلبات بسلاسة عبر لوحة تحكم متطورة.',
                      style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 12.5),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'بيانات المنشأة والمطعم',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 12),

              _buildInputField(
                label: 'اسم المطعم أو المنشأة التجارية',
                controller: _businessNameCtrl,
                icon: Icons.restaurant_rounded,
                cardBg: cardBg,
                textColor: textColor,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المطعم' : null,
              ),

              const SizedBox(height: 12),

              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    alignment: Alignment.centerRight,
                    dropdownColor: cardBg,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.ibmPlexSansArabic(color: textColor, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'بيانات التواصل والمسؤول',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
              ),
              const SizedBox(height: 12),

              _buildInputField(
                label: 'اسم المسؤول / مالك المطعم',
                controller: _ownerNameCtrl,
                icon: Icons.person_outline_rounded,
                cardBg: cardBg,
                textColor: textColor,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المسؤول' : null,
              ),

              const SizedBox(height: 12),

              _buildInputField(
                label: 'رقم الهاتف للتواصل',
                controller: _phoneCtrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputKeyData.phone,
                cardBg: cardBg,
                textColor: textColor,
                validator: (v) => (v == null || v.trim().length < 8) ? 'يرجى إدخال رقم هاتف صحيح' : null,
              ),

              const SizedBox(height: 12),

              _buildInputField(
                label: 'البريد الإلكتروني التجاري',
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputKeyData.email,
                cardBg: cardBg,
                textColor: textColor,
                validator: (v) => (v == null || !v.contains('@')) ? 'يرجى إدخال بريد إلكتروني صالح' : null,
              ),

              const SizedBox(height: 12),

              _buildInputField(
                label: 'المدينة والمنطقة (مثال: القاهرة، المعادي)',
                controller: _cityCtrl,
                icon: Icons.location_on_outlined,
                cardBg: cardBg,
                textColor: textColor,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال موقع المطعم' : null,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'تقديم طلب الانضمام كشريك',
                          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color cardBg,
    required Color textColor,
    TextInputKeyData? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: keyboardType == TextInputKeyData.phone
          ? TextInputType.phone
          : (keyboardType == TextInputKeyData.email ? TextInputType.emailAddress : TextInputType.text),
      validator: validator,
      style: GoogleFonts.ibmPlexSansArabic(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 13),
        suffixIcon: Icon(icon, color: const Color(0xFF7C57FC), size: 20),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 2)),
      ),
    );
  }
}

enum TextInputKeyData {
  text,
  phone,
  email,
}
