import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'edit_profile_provider.dart';
import 'settings_provider.dart';

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
        return NetworkImage(dbUrl);
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

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              isAr ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isAr ? 'تعديل الملف الشخصي' : 'Edit Profile',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: editState.loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C57FC),
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
                              backgroundColor: const Color(0xFFF2F2F2),
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
                        icon: Icons.person_outline,
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
                      // Gender Dropdown Field
                      _buildGenderDropdown(isAr, editState.gender),
                      const SizedBox(height: 20),
                      // Hometown Field
                      _buildTextField(
                        controller: _hometownController,
                        label: isAr ? 'المدينة / الموطن' : 'Hometown',
                        hint: isAr ? 'المدينة الحالية' : 'Hometown city',
                        icon: Icons.home_outlined,
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
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15,
              color: const Color(0xFFBBBBBB),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF7C57FC),
                  )
                : (prefixText != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
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

  Widget _buildGenderDropdown(bool isAr, String? gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الجنس' : 'Gender',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: gender,
          hint: Text(
            isAr ? 'اختر الجنس' : 'Select gender',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15,
              color: const Color(0xFFBBBBBB),
            ),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(
              Icons.person_outline,
              size: 20,
              color: Color(0xFF7C57FC),
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'male',
              child: Text(isAr ? 'ذكر' : 'Male', style: GoogleFonts.ibmPlexSansArabic()),
            ),
            DropdownMenuItem(
              value: 'female',
              child: Text(isAr ? 'أنثى' : 'Female', style: GoogleFonts.ibmPlexSansArabic()),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text(isAr ? 'أخرى' : 'Other', style: GoogleFonts.ibmPlexSansArabic()),
            ),
          ],
          onChanged: (val) {
            ref.read(editProfileProvider.notifier).setGender(val);
          },
        ),
      ],
    );
  }
}
