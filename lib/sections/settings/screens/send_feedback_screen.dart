import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

class SendFeedbackScreen extends ConsumerStatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  ConsumerState<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends ConsumerState<SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  String? _category;
  int _rating = 0;
  File? _screenshotFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _screenshotFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking screenshot: $e');
    }
  }

  Future<String?> _uploadScreenshot() async {
    if (_screenshotFile == null) return null;
    final user = Supabase.instance.client.auth.currentUser;
    final client = Supabase.instance.client;

    try {
      final fileName = 'feedbacks/${user?.id ?? 'anon'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from('post-images').upload(
        fileName,
        _screenshotFile!,
        fileOptions: const FileOptions(cacheControl: '31536000', upsert: true),
      );
      return client.storage.from('post-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading screenshot: $e');
      return null;
    }
  }

  Future<void> _submitFeedback() async {
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(settingsProvider).preferredLanguage == 'ar'
                ? 'يرجى اختيار تصنيف الملاحظة'
                : 'Please select a feedback category',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    final screenshotUrl = await _uploadScreenshot();
    final success = await ref.read(settingsProvider.notifier).submitFeedback(
          category: _category!,
          description: _descriptionController.text.trim(),
          rating: _rating,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          screenshotUrl: screenshotUrl,
        );

    setState(() {
      _submitting = false;
    });

    if (mounted) {
      final isAr = ref.read(settingsProvider).preferredLanguage == 'ar';
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم إرسال ملاحظاتك بنجاح. شكراً لك!'
                  : 'Feedback submitted successfully. Thank you!',
            ),
            backgroundColor: const Color(0xFF7C57FC),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'فشل إرسال الملاحظات. يرجى المحاولة مرة أخرى.'
                  : 'Failed to submit feedback. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color textLabelColor = isDark ? Colors.white : const Color(0xFF333333);
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final Color promoBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFF9F9FA);
    final Color promoBorder = isDark ? const Color(0xFF1E2433) : const Color(0xFFF0F0F2);
    final Color inputBg = isDark ? const Color(0xFF1A1F2C) : Colors.white;
    final Color inputBorder = isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8);
    final Color hintColor = isDark ? Colors.white30 : const Color(0xFFBBBBBB);
    final Color attachmentBg = isDark ? const Color(0xFF1F2430) : const Color(0xFFFAFAFA);
    final Color iconColor = isDark ? Colors.white54 : const Color(0xFF888888);

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
            isAr ? 'إرسال ملاحظاتك' : 'Send Feedback',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promo card banner matching Figma - 320
                Container(
                  decoration: BoxDecoration(
                    color: promoBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: promoBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'يسعدنا سماع رأيك!' : 'We\'d love to hear from you!',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'تساعدنا ملاحظاتك على جعل تطبيق More أفضل.'
                                  : 'Your feedback helps us make More better.',
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
                      // feedback_promo image matching mockup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/setting/images/feedback_promo.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 96,
                            height: 96,
                            color: isDark ? const Color(0xFF131722) : Colors.grey[200],
                            child: Icon(Icons.feedback_outlined, color: iconColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Dropdown select: What's your feedback about?
                Text(
                  isAr ? 'ما هو موضوع ملاحظاتك؟' : 'What\'s your feedback about?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  hint: Text(
                    isAr ? 'اختر تصنيف الملاحظة' : 'Select feedback category',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      color: hintColor,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSansArabic(color: textColor),
                  dropdownColor: isDark ? const Color(0xFF1F2430) : Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'bug',
                      child: Text(isAr ? 'تقرير عن مشكلة' : 'Bug Report', style: GoogleFonts.ibmPlexSansArabic()),
                    ),
                    DropdownMenuItem(
                      value: 'suggestion',
                      child: Text(isAr ? 'اقتراح ميزة' : 'Feature Suggestion', style: GoogleFonts.ibmPlexSansArabic()),
                    ),
                    DropdownMenuItem(
                      value: 'general',
                      child: Text(isAr ? 'رأي عام' : 'General Feedback', style: GoogleFonts.ibmPlexSansArabic()),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(isAr ? 'أخرى' : 'Other', style: GoogleFonts.ibmPlexSansArabic()),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _category = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Text Area: Your feedback
                Text(
                  isAr ? 'ملاحظاتك' : 'Your feedback',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  maxLength: 500,
                  style: GoogleFonts.ibmPlexSansArabic(color: textColor),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isAr ? 'يرجى كتابة تفاصيل الملاحظة' : 'Please describe your feedback';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    hintText: isAr ? 'اكتب ملاحظاتك هنا...' : 'Write your feedback here...',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      color: hintColor,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Rating stars
                Text(
                  isAr ? 'كيف تقيم تجربتك؟' : 'How would you rate your experience?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textLabelColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isFilled = starIndex <= _rating;
                    return IconButton(
                      icon: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFilled ? const Color(0xFFFFC107) : (isDark ? const Color(0xFF2C354A) : const Color(0xFFCCCCCC)),
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = starIndex;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Screenshot Picker
                Text(
                  isAr ? 'إضافة لقطة شاشة (اختياري)' : 'Add screenshots (optional)',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickScreenshot,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: attachmentBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: inputBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _screenshotFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_screenshotFile!, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _screenshotFile = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: iconColor, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                isAr ? 'اضغط لإضافة صورة' : 'Click to add screenshot',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // Your email Field
                Text(
                  isAr ? 'البريد الإلكتروني للرد' : 'Your email',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.ibmPlexSansArabic(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    hintText: isAr ? 'بريدك الإلكتروني' : 'Your email address',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      color: hintColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.mail_outline, color: iconColor),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: _submitting ? null : _submitFeedback,
                    child: _submitting
                        ? const CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 8,
                          )
                        : Text(
                            isAr ? 'إرسال الملاحظات' : 'Submit Feedback',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
