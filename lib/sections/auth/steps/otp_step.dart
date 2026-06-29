import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/otp_input.dart';

class OtpBottomSheet extends StatefulWidget {
  final String targetAddress;
  final VoidCallback onVerified;
  final VoidCallback onChangeNumber;

  const OtpBottomSheet({
    super.key,
    required this.targetAddress,
    required this.onVerified,
    required this.onChangeNumber,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  String _enteredCode = '';
  String? _errorCode;
  bool _isLoading = false;

  void _verifyCode() async {
    if (_enteredCode.length == 6) {
      setState(() {
        _isLoading = true;
        _errorCode = null;
      });
      try {
        final isEmail = widget.targetAddress.contains('@');
        final response = await Supabase.instance.client.auth.verifyOTP(
          type: isEmail ? OtpType.email : OtpType.sms,
          token: _enteredCode,
          phone: isEmail ? null : widget.targetAddress,
          email: isEmail ? widget.targetAddress : null,
        );
        
        if (response.user != null) {
          widget.onVerified();
        } else {
          setState(() {
            _errorCode = 'Verification failed. Please check the code.';
          });
        }
      } on AuthException catch (e) {
        setState(() {
          _errorCode = e.message;
        });
      } catch (e) {
        setState(() {
          _errorCode = 'An unexpected error occurred: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      final isEmail = widget.targetAddress.contains('@');
      if (isEmail) {
        await Supabase.instance.client.auth.signInWithOtp(
          email: widget.targetAddress,
        );
      } else {
        await Supabase.instance.client.auth.signInWithOtp(
          phone: widget.targetAddress,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification code resent successfully!',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
            backgroundColor: const Color(0xFF7C57FC),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to resend code: ${e.message}',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to resend code: $e',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = _enteredCode.length == 6;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Indicator
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
              'Enter Code',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit verification code to\n${widget.targetAddress}',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // OTP Boxes
            OtpInput(
              onCompleted: (code) {
                setState(() {
                  _enteredCode = code;
                  _errorCode = null;
                });
              },
              onChangeNumber: widget.onChangeNumber,
              onResendCode: _resendCode,
            ),
            if (_errorCode != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorCode!,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Opacity(
                opacity: (canVerify && !_isLoading) ? 1.0 : 0.7,
                child: ElevatedButton(
                  onPressed: (canVerify && !_isLoading) ? _verifyCode : null,
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
                          'Verify',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
