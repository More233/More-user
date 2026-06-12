import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/auth_text_field.dart';

class BasicInfoStep extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onCompleted;

  const BasicInfoStep({
    super.key,
    required this.onBack,
    required this.onCompleted,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();

  String? _firstNameError;
  String? _usernameError;
  String? _cityError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty ? 'First Name is required' : null;
      _usernameError = _usernameController.text.trim().isEmpty ? 'Username is required' : null;
      _cityError = _cityController.text.trim().isEmpty ? 'City is required' : null;
    });

    if (_firstNameError == null && _usernameError == null && _cityError == null) {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/Auth Section/Basic information  Birthday/icon/arrow-left.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A2E),
              BlendMode.srcIn,
            ),
          ),
          onPressed: widget.onBack,
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/Splash/logo.svg',
          width: 120,
          height: 38,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Color(0xFF7C57FC),
            BlendMode.srcIn,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Basic information',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us a bit about yourself.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 32),
              // Fields
              AuthTextField(
                controller: _firstNameController,
                labelText: 'First Name',
                hintText: 'Enter your first name',
                errorText: _firstNameError,
                onChanged: (val) {
                  if (_firstNameError != null) setState(() => _firstNameError = null);
                },
              ),
              const SizedBox(height: 20),
              AuthTextField(
                controller: _lastNameController,
                labelText: 'Last Name (Optional)',
                hintText: 'Enter your last name',
              ),
              const SizedBox(height: 20),
              AuthTextField(
                controller: _usernameController,
                labelText: 'Username',
                hintText: 'Choose a username',
                errorText: _usernameError,
                onChanged: (val) {
                  if (_usernameError != null) setState(() => _usernameError = null);
                },
              ),
              const SizedBox(height: 20),
              AuthTextField(
                controller: _cityController,
                labelText: 'City',
                hintText: 'Enter your city',
                errorText: _cityError,
                onChanged: (val) {
                  if (_cityError != null) setState(() => _cityError = null);
                },
              ),
              const SizedBox(height: 32),
              // Username Tip Banner (Styled premium matching Figma)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE9FE)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE6FC),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/Auth Section/Basic information  Default/icon/user-multiple.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF7C57FC),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your username helps friends to find you on More',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5B4FB3),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
