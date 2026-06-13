import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
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
      _isLoading = true;
    });

    final address = _isPhoneTab ? '${_selectedCountry.dialCode}$value' : value;

    try {
      if (_isPhoneTab) {
        await Supabase.instance.client.auth.signInWithOtp(
          phone: address,
        );
      } else {
        await Supabase.instance.client.auth.signInWithOtp(
          email: address,
        );
      }

      if (mounted) {
        widget.onContinue(address);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorText = e.message;
      });
    } catch (e) {
      setState(() {
        _errorText = 'An unexpected error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.moreapp://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (!kIsWeb && Platform.isIOS) {
        final rawNonce = Supabase.instance.client.auth.generateRawNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final idToken = credential.identityToken;
        if (idToken == null) {
          throw const AuthException(
              'Could not find ID Token from generated credential.');
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );

        // Apple only provides the user's full name on the first sign-in
        // Save it to user metadata if available
        if (credential.givenName != null || credential.familyName != null) {
          final nameParts = <String>[];
          if (credential.givenName != null) nameParts.add(credential.givenName!);
          if (credential.familyName != null) nameParts.add(credential.familyName!);

          final fullName = nameParts.join(' ');

          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName,
                'given_name': credential.givenName,
                'family_name': credential.familyName,
              },
            ),
          );
        }
      } else {
        // Fallback for Android/Web (web-based OAuth)
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: kIsWeb ? null : 'io.supabase.moreapp://login-callback',
          authScreenLaunchMode:
              kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Only show error if the user did not cancel the native Apple sheet
      if (!msg.contains('SignInWithAppleAuthorizationExceptionCode.canceled') &&
          !msg.contains('SignInWithAppleAuthorizationError.canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple Sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                readOnly: _isLoading,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_selectedCountry.code == 'EG' ? 10 : 9),
                ],
                prefixIcon: CountryPicker(
                  selectedCountry: _selectedCountry,
                  onCountryChanged: _isLoading
                      ? (_) {}
                      : (c) {
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
                readOnly: _isLoading,
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
                opacity: (hasValue && !_isLoading) ? 1.0 : 0.7,
                child: ElevatedButton(
                  onPressed: (hasValue && !_isLoading) ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    disabledBackgroundColor: const Color(0xFF7C57FC).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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
              onPressed: _isLoading ? () {} : _handleGoogleSignIn,
            ),
            const SizedBox(height: 16),
            _buildSocialButton(
              logoSvgPath: 'assets/Auth Section/Get started with More/icon/Social icon apple.svg',
              platformName: 'Apple',
              onPressed: _isLoading ? () {} : _handleAppleSignIn,
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
