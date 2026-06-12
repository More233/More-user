import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/country_picker.dart';

class LoginStep extends StatefulWidget {
  final ValueChanged<String> onContinue;
  final VoidCallback onSignUpPressed;

  const LoginStep({
    super.key,
    required this.onContinue,
    required this.onSignUpPressed,
  });

  @override
  State<LoginStep> createState() => _LoginStepState();
}

class _LoginStepState extends State<LoginStep> {
  bool _isPhoneTab = true;
  final TextEditingController _inputController = TextEditingController();
  CountryInfo _selectedCountry = CountryPicker.countries[0]; // Default SA
  String? _errorText;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final value = _inputController.text.trim();
    if (value.isEmpty) return;

    if (_isPhoneTab) {
      final expectedLength = _selectedCountry.code == 'EG' ? 10 : 9;
      if (value.length != expectedLength) {
        setState(() {
          _errorText = 'Phone number must be $expectedLength digits';
        });
        return;
      }
      final expectedStart = _selectedCountry.code == 'EG' ? '1' : '5';
      if (!value.startsWith(expectedStart)) {
        setState(() {
          _errorText = 'Phone number must start with $expectedStart';
        });
        return;
      }
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        setState(() {
          _errorText = 'Enter a valid email address';
        });
        return;
      }
    }

    setState(() {
      _errorText = null;
    });

    // Show Detected Account bottom sheet for testing specific email/numbers to wow the user
    if (!_isPhoneTab && value.contains('abdelrahman')) {
      _showAccountDetectedBottomSheet(context, value);
    } else {
      widget.onContinue(_isPhoneTab ? '${_selectedCountry.dialCode} $value' : value);
    }
  }

  void _showAccountDetectedBottomSheet(BuildContext context, String enteredEmail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider Indicator
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Text(
                'Account Detected',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'An account is already linked to this email address. Let’s sign you in directly.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Account Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE6FC),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        'assets/Auth Section/Basic information  Default/icon/user-multiple.svg',
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF7C57FC),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abdel-rahman Mohammed',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            enteredEmail,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Actions
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onContinue(enteredEmail);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Sign in to this account',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE8E8E8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Use a different email',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Need help?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _inputController.text.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Splash main logo
            SvgPicture.asset(
              'assets/Splash/logo.svg',
              width: 154,
              height: 48.79,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Color(0xFF7C57FC),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            // Header Text
            Text(
              'Get started with More',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use your phone or email to continue.',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Tabs Capsule Switcher
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFC),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Phone Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPhoneTab = true;
                          _inputController.clear();
                          _errorText = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isPhoneTab ? const Color(0xFFEDE6FC) : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/Auth Section/Get started with More/icon/call.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                _isPhoneTab ? const Color(0xFF7C57FC) : const Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Phone',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: _isPhoneTab ? FontWeight.w600 : FontWeight.w400,
                                color: _isPhoneTab ? const Color(0xFF7C57FC) : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Email Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPhoneTab = false;
                          _inputController.clear();
                          _errorText = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isPhoneTab ? const Color(0xFFEDE6FC) : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/Auth Section/Get started with More/icon/mail-01.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                !_isPhoneTab ? const Color(0xFF7C57FC) : const Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Email',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: !_isPhoneTab ? FontWeight.w600 : FontWeight.w400,
                                color: !_isPhoneTab ? const Color(0xFF7C57FC) : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Dynamic Input Text Field
            if (_isPhoneTab)
              AuthTextField(
                key: const ValueKey('phone_field'),
                controller: _inputController,
                labelText: 'Phone Number',
                hintText: '${_selectedCountry.dialCode}  ${_selectedCountry.hintFormat}',
                keyboardType: TextInputType.phone,
                errorText: _errorText,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_selectedCountry.code == 'EG' ? 10 : 9),
                ],
                prefixIcon: CountryPicker(
                  selectedCountry: _selectedCountry,
                  onCountryChanged: (c) {
                    setState(() {
                      _selectedCountry = c;
                      _inputController.clear();
                      _errorText = null;
                    });
                  },
                ),
                onChanged: (val) {
                  setState(() {
                    if (_errorText != null) _errorText = null;
                  });
                },
              )
            else
              AuthTextField(
                key: const ValueKey('email_field'),
                controller: _inputController,
                labelText: 'Email Address',
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _errorText,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: SvgPicture.asset(
                    'assets/Auth Section/Get started with More/icon/mail-01.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF9CA3AF),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    if (_errorText != null) _errorText = null;
                  });
                },
              ),
            const SizedBox(height: 32),
            // Continue Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Opacity(
                opacity: hasValue ? 1.0 : 0.7,
                child: ElevatedButton(
                  onPressed: hasValue ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    disabledBackgroundColor: const Color(0xFF7C57FC).withOpacity(0.5),
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
            ),
            const SizedBox(height: 48),
            // Social Divider
            Row(
              children: [
                Expanded(child: Container(height: 1, color: const Color(0xFFE8E8E8))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or Sign in with',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB0B0B0),
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: const Color(0xFFE8E8E8))),
              ],
            ),
            const SizedBox(height: 32),
            // Social Action Buttons
            _buildSocialButton(
              logoSvgPath: 'assets/Auth Section/Get started with More/icon/Social icon.svg',
              platformName: 'Google',
              onPressed: () {
                // Pre-populate with testing email to showcase Bottom Sheet account detection
                setState(() {
                  _isPhoneTab = false;
                  _inputController.text = 'abdelrahmanOfficial@gmail.com';
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSocialButton(
              logoSvgPath: 'assets/Auth Section/Get started with More/icon/Social icon apple.svg',
              platformName: 'Apple',
              onPressed: () {},
            ),
            const SizedBox(height: 48),
            // Sign Up Switcher Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF4F4F4F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onSignUpPressed,
                  child: Text(
                    'Sign up',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      color: const Color(0xFF7C57FC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String logoSvgPath,
    required String platformName,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE8E8E8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              logoSvgPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Sign in with $platformName',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF414651),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
