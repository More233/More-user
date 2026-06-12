import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _verifyCode() {
    if (_enteredCode.length == 6) {
      if (_enteredCode == '123456' || _enteredCode == '111111') {
        // Success code
        widget.onVerified();
      } else {
        // Validation fails for any other code for demo purposes
        setState(() {
          _errorCode = 'Incorrect verification code. Please try again.';
        });
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
              onResendCode: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Verification code resent successfully!',
                      style: GoogleFonts.ibmPlexSansArabic(),
                    ),
                    backgroundColor: const Color(0xFF7C57FC),
                  ),
                );
              },
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
                opacity: canVerify ? 1.0 : 0.7,
                child: ElevatedButton(
                  onPressed: canVerify ? _verifyCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    disabledBackgroundColor: const Color(0xFF7C57FC).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
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
            const SizedBox(height: 24),
            // Helper note
            Text(
              'For testing: Use code 123456 or 111111',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
