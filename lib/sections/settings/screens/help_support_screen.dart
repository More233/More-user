import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(settingsProvider).preferredLanguage == 'ar'
                ? 'يرجى ملء جميع الحقول المطلوبة واختيار نوع المشكلة'
                : 'Please fill in all required fields and select the problem type',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      String reporterName = 'Anonymous User';
      if (user != null) {
        final profileRes = await client
            .from('profiles')
            .select('first_name, last_name, username')
            .eq('id', user.id)
            .maybeSingle();
            
        if (profileRes != null) {
          final String firstName = profileRes['first_name'] ?? '';
          final String lastName = profileRes['last_name'] ?? '';
          final String username = profileRes['username'] ?? '';
          
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            reporterName = '$firstName $lastName'.trim();
          } else if (username.isNotEmpty) {
            reporterName = username;
          } else {
            reporterName = user.email ?? 'User';
          }
        } else {
          reporterName = user.email ?? 'User';
        }
      }

      await client.from('reports').insert({
        'reporter_id': user?.id,
        'reporter_name': reporterName,
        'reported_name': _subjectController.text.trim(),
        'reported_type': _selectedType,
        'reason': _descriptionController.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final isAr = ref.read(settingsProvider).preferredLanguage == 'ar';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F2430)
              : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                isAr ? 'تم الإرسال بنجاح!' : 'Submitted Successfully!',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          content: Text(
            isAr
                ? 'تم تسجيل تذكرتك بنظام الدعم. سيتم مراجعتها من قبل الإدارة في أقرب وقت.'
                : 'Your ticket has been registered in our support system. It will be reviewed by the admin team shortly.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to settings
              },
              child: Text(
                isAr ? 'حسناً' : 'Okay',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C57FC),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error submitting support ticket: $e");
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(settingsProvider).preferredLanguage == 'ar'
                ? 'حدث خطأ أثناء إرسال التذكرة. يرجى المحاولة مرة أخرى.'
                : 'An error occurred while submitting the ticket. Please try again.',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    }
  }

  void _showProblemTypeBottomSheet(
    BuildContext context,
    List<Map<String, String>> problemTypes,
    bool isAr,
    bool isDark,
    Color dividerColor,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2430) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'اختر نوع المشكلة' : 'Select Problem Type',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: dividerColor),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: problemTypes.length,
                    itemBuilder: (context, index) {
                      final type = problemTypes[index];
                      final isSelected = type['value'] == _selectedType;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(
                          isAr ? type['ar']! : type['en']!,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF7C57FC) : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF7C57FC))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedType = type['value'];
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final Color cardBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFF9F9FA);
    final Color cardBorder = isDark ? const Color(0xFF1E2433) : const Color(0xFFF0F0F2);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    final List<Map<String, String>> problemTypes = [
      {'value': 'Check-in', 'en': 'Check-ins', 'ar': 'تسجيلات الوصول'},
      {'value': 'Friends', 'en': 'Friends & Connections', 'ar': 'الأصدقاء والتواصل'},
      {'value': 'Saved Places', 'en': 'Saved Places', 'ar': 'الأماكن المحفوظة'},
      {'value': 'Technical Bug', 'en': 'Technical Bug / App Error', 'ar': 'مشكلة تقنية / عطل بالتطبيق'},
      {'value': 'Account Settings', 'en': 'Account Settings', 'ar': 'إعدادات الحساب'},
      {'value': 'Other', 'en': 'Other', 'ar': 'أخرى'},
    ];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'تقديم تذكرة دعم' : 'Submit Support Ticket',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: dividerColor),
                const SizedBox(height: 16),
                
                // Info Banner Card
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'نظام تذاكر الدعم والشكاوى' : 'Support & Complaints Ticket',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'يرجى تحديد نوع المشكلة وتوضيح التفاصيل، وسيقوم فريق الدعم بمراجعة تذكرتك قريباً.'
                                  : 'Please select the problem type and describe the details. Our support team will review your ticket shortly.',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: textMutedColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/setting/images/help_promo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: isDark ? const Color(0xFF1F2430) : Colors.grey[200],
                            child: const Icon(Icons.support_agent_outlined, color: Colors.grey, size: 36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Problem Type Dropdown
                Text(
                  isAr ? 'نوع المشكلة' : 'Problem Type',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showProblemTypeBottomSheet(
                    context,
                    problemTypes,
                    isAr,
                    isDark,
                    dividerColor,
                    textColor,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedType == null ? dividerColor : const Color(0xFF7C57FC),
                        width: _selectedType == null ? 1.0 : 1.5,
                      ),
                      color: isDark ? const Color(0xFF131722) : Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedType == null
                              ? (isAr ? 'اختر نوع المشكلة' : 'Select problem type')
                              : problemTypes.firstWhere((t) => t['value'] == _selectedType)[isAr ? 'ar' : 'en']!,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: _selectedType == null
                                ? (isDark ? Colors.white38 : const Color(0xFFBBBBBB))
                                : textColor,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: _selectedType == null
                              ? (isDark ? Colors.white38 : const Color(0xFF888888))
                              : const Color(0xFF7C57FC),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Subject / Issue title
                Text(
                  isAr ? 'ما هي المشكلة بالتحديد؟' : 'What is the problem exactly?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  style: GoogleFonts.ibmPlexSansArabic(color: textColor),
                  decoration: InputDecoration(
                    hintText: isAr ? 'مثال: لا يمكنني تسجيل الوصول...' : 'e.g. Cannot check-in at a place...',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white38 : const Color(0xFFBBBBBB)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? (isAr ? 'يرجى تحديد تفاصيل المشكلة' : 'Please specify the issue')
                      : null,
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  isAr ? 'وصف المشكلة بالتفصيل' : 'Description & Details',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  style: GoogleFonts.ibmPlexSansArabic(color: textColor),
                  decoration: InputDecoration(
                    hintText: isAr
                        ? 'يرجى كتابة وصف بسيط وواضح للمشكلة لكي نتمكن من مساعدتك...'
                        : 'Please write a simple and clear description of the issue to help us resolve it...',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(color: isDark ? Colors.white38 : const Color(0xFFBBBBBB)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? (isAr ? 'يرجى إدخال وصف المشكلة' : 'Please enter description')
                      : null,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: const Color(0xFF7C57FC).withValues(alpha: 0.6),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isAr ? 'جاري الإرسال...' : 'Submitting...',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            isAr ? 'إرسال التذكرة' : 'Submit Ticket',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
