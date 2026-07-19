import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/edit_profile_provider.dart';
import '../providers/settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _hometownController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _hometownController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        await ref.read(editProfileProvider.notifier).uploadAvatar(file);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(editProfileProvider.notifier).saveChanges(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      hometown: _hometownController.text.trim(),
    );
  }

  ImageProvider _getAvatarProvider(String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return CachedNetworkImageProvider(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    return const AssetImage('assets/home/images/element.png');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';
    final editState = ref.watch(editProfileProvider);

    ref.listen<EditProfileState>(editProfileProvider, (previous, next) {
      if (previous?.loading == true && !next.loading) {
        _firstNameController.text = next.firstName;
        _lastNameController.text = next.lastName;
        _usernameController.text = next.username;
        _emailController.text = next.email;
        _phoneController.text = next.phone;
        _hometownController.text = next.hometown;
      }
      if (previous != null && !previous.success && next.success) {
        Navigator.pop(context, true);
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.errorMessage}')),
        );
      }
    });

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F1219) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color avatarBgColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF2F2F2);

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
            isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: editState.loading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: Color(0xFF7C57FC),
                  radius: 12,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar Editor
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: avatarBgColor,
                              backgroundImage: _getAvatarProvider(editState.avatarUrl),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C57FC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // First Name Field
                      _buildTextField(
                        controller: _firstNameController,
                        label: isAr ? 'الاسم الأول' : 'First Name',
                        hint: isAr ? 'أدخل اسمك الأول' : 'Enter your first name',
                        icon: Icons.person_outline,
                        isAr: isAr,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isAr ? 'الاسم الأول مطلوب' : 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Last Name Field
                      _buildTextField(
                        controller: _lastNameController,
                        label: isAr ? 'اسم العائلة' : 'Last Name',
                        hint: isAr ? 'أدخل اسم عائلتك' : 'Enter your last name',
                        icon: Icons.people_outline,
                        isAr: isAr,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isAr ? 'اسم العائلة مطلوب' : 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Username Field
                      _buildTextField(
                        controller: _usernameController,
                        label: isAr ? 'اسم المستخدم' : 'Username',
                        hint: isAr ? 'اسم المستخدم' : 'Username',
                        icon: Icons.alternate_email,
                        prefixText: '@',
                        isAr: isAr,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isAr ? 'اسم المستخدم مطلوب' : 'Username is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: isAr ? 'البريد الإلكتروني' : 'Email',
                        hint: isAr ? 'بريدك الإلكتروني' : 'Your email',
                        icon: Icons.mail_outline,
                        isAr: isAr,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isAr ? 'البريد الإلكتروني مطلوب' : 'Email is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Phone Field
                      _buildTextField(
                        controller: _phoneController,
                        label: isAr ? 'رقم الهاتف' : 'Phone',
                        hint: isAr ? 'رقم الهاتف' : 'Phone number',
                        icon: Icons.phone_outlined,
                        isAr: isAr,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      // Gender Selector Field
                      _buildGenderSelector(isAr, editState.gender),
                      const SizedBox(height: 20),
                      // Hometown Field
                      _buildTextField(
                        controller: _hometownController,
                        label: isAr ? 'المدينة / الموطن' : 'Hometown',
                        hint: isAr ? 'المدينة الحالية' : 'Hometown city',
                        icon: Icons.place_outlined,
                        isAr: isAr,
                      ),
                      const SizedBox(height: 40),
                      // Save button
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
                          onPressed: editState.saving ? null : _saveChanges,
                          child: editState.saving
                              ? CupertinoActivityIndicator(
                                  color: Colors.white,
                                  radius: 8,
                                )
                              : Text(
                                  isAr ? 'حفظ التغييرات' : 'Save Changes',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? prefixText,
    required bool isAr,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color labelColor = isDark ? Colors.white : const Color(0xFF333333);
    final Color hintColor = isDark ? Colors.white38 : const Color(0xFFBBBBBB);
    final Color borderSideColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.ibmPlexSansArabic(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15,
              color: hintColor,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 24,
            ),
            prefixIcon: icon != null
                ? Padding(
                    padding: EdgeInsets.only(
                      left: isAr ? 8 : 12,
                      right: isAr ? 12 : 8,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: const Color(0xFF7C57FC),
                    ),
                  )
                : (prefixText != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          left: isAr ? 8 : 12,
                          right: isAr ? 12 : 8,
                        ),
                        child: Text(
                          prefixText,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7C57FC),
                          ),
                        ),
                      )
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderSideColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderSideColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isAr, String? genderValue) {
    String displayedGender = isAr ? 'اختر الجنس' : 'Select gender';
    if (genderValue == 'male') {
      displayedGender = isAr ? 'ذكر' : 'Male';
    } else if (genderValue == 'female') {
      displayedGender = isAr ? 'أنثى' : 'Female';
    } else if (genderValue == 'other') {
      displayedGender = isAr ? 'أخرى' : 'Other';
    }

    final hasSelected = genderValue != null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor = isDark ? Colors.white : const Color(0xFF333333);
    final Color containerBg = isDark ? const Color(0xFF1F2430) : Colors.white;
    final Color borderSideColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color displayedTextColor = hasSelected
        ? (isDark ? Colors.white : const Color(0xFF333333))
        : (isDark ? Colors.white38 : const Color(0xFFBBBBBB));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الجنس' : 'Gender',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showGenderBottomSheet(isAr, genderValue),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSideColor),
              color: containerBg,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: isAr ? 8 : 0,
                    right: isAr ? 0 : 8,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: Color(0xFF7C57FC),
                  ),
                ),
                Expanded(
                  child: Text(
                    displayedGender,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      color: displayedTextColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasSelected ? const Color(0xFF7C57FC) : (isDark ? Colors.white38 : const Color(0xFFBBBBBB)),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGenderBottomSheet(bool isAr, String? currentGender) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color modalBg = isDark ? const Color(0xFF131722) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'اختر الجنس' : 'Select Gender',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildGenderOption('male', isAr ? 'ذكر' : 'Male', currentGender),
              _buildGenderOption('female', isAr ? 'أنثى' : 'Female', currentGender),
              _buildGenderOption('other', isAr ? 'أخرى' : 'Other', currentGender),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderOption(String value, String label, String? currentGender) {
    final isSelected = value == currentGender;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color optionBg = isSelected
        ? (isDark ? const Color(0xFF2A1C54) : const Color(0xFF7C57FC).withValues(alpha: 0.08))
        : Colors.transparent;
    final Color optionTextColor = isSelected
        ? const Color(0xFF7C57FC)
        : (isDark ? Colors.white70 : Colors.black87);

    return InkWell(
      onTap: () {
        ref.read(editProfileProvider.notifier).setGender(value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: optionBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: optionTextColor,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF7C57FC),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
