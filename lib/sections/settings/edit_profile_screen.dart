import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _client = Supabase.instance.client;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _hometownController;

  String? _gender;
  String? _avatarUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _hometownController = TextEditingController();

    _fetchProfile();
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

  Future<void> _fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        _firstNameController.text = data['first_name'] as String? ?? '';
        _lastNameController.text = data['last_name'] as String? ?? '';
        _usernameController.text = data['username'] as String? ?? '';
        _emailController.text = data['email'] as String? ?? '';
        _phoneController.text = data['phone'] as String? ?? '';
        _hometownController.text = data['city'] as String? ?? '';
        _avatarUrl = data['avatar_url'] as String?;
        // If gender is in db, populate it, otherwise fallback to null.
        // Profiles might not have gender column originally, let's safe-check or default.
        _gender = data['gender'] as String?;
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching profile for edit: $e');
      setState(() {
        _loading = false;
      });
    }
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
        setState(() {
          _saving = true;
        });

        final user = _client.auth.currentUser;
        if (user == null) return;

        final file = File(image.path);
        final fileName = 'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await _client.storage.from('post-images').upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        final publicUrl = _client.storage.from('post-images').getPublicUrl(fileName);

        await _client.from('profiles').update({
          'avatar_url': publicUrl,
        }).eq('id', user.id);

        setState(() {
          _avatarUrl = publicUrl;
          _saving = false;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      setState(() {
        _saving = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
    });

    try {
      // Proactively support gender column inside profiles table (save check)
      final Map<String, dynamic> updates = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _hometownController.text.trim(),
      };

      try {
        updates['gender'] = _gender;
      } catch (_) {}

      await _client.from('profiles').update(updates).eq('id', user.id);

      setState(() {
        _saving = false;
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile changes: $e');
      setState(() {
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    }
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
        body: _loading
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
                              backgroundImage: _getAvatarProvider(_avatarUrl),
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
                                child: SvgPicture.asset(
                                  'assets/setting/icons/pen_01.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
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
                        iconPath: 'assets/setting/icons/user.svg',
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
                        iconPath: 'assets/setting/icons/user.svg',
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
                        iconPath: 'assets/setting/icons/mail_01.svg',
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
                        iconPath: 'assets/setting/icons/toggle_base.svg', // Fallback or placeholder icon
                        isAr: isAr,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      // Gender Dropdown Field
                      _buildGenderDropdown(isAr),
                      const SizedBox(height: 20),
                      // Hometown Field
                      _buildTextField(
                        controller: _hometownController,
                        label: isAr ? 'المدينة / الموطن' : 'Hometown',
                        hint: isAr ? 'المدينة الحالية' : 'Hometown city',
                        iconPath: 'assets/setting/icons/location_01.svg',
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
                          onPressed: _saving ? null : _saveChanges,
                          child: _saving
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
    String? iconPath,
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
            prefixIcon: iconPath != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      iconPath,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7C57FC),
                        BlendMode.srcIn,
                      ),
                    ),
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

  Widget _buildGenderDropdown(bool isAr) {
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
          initialValue: _gender,
          hint: Text(
            isAr ? 'اختر الجنس' : 'Select gender',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15,
              color: const Color(0xFFBBBBBB),
            ),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                'assets/setting/icons/user.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF7C57FC),
                  BlendMode.srcIn,
                ),
              ),
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
            setState(() {
              _gender = val;
            });
          },
        ),
      ],
    );
  }
}
