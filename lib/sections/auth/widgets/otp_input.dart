import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final VoidCallback onChangeNumber;
  final VoidCallback onResendCode;

  const OtpInput({
    super.key,
    required this.onCompleted,
    required this.onChangeNumber,
    required this.onResendCode,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final int _codeLength = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  
  Timer? _timer;
  int _secondsRemaining = 28;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (index) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (index) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 28;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Focus next if not last
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      // Focus previous if empty and deleted
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    final code = _getOtpCode();
    if (code.length == _codeLength) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color borderColor = isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8);
    final Color fillColor = isDark ? const Color(0xFF1E2433) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 6 code input fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_codeLength, (index) {
            return SizedBox(
              width: 48,
              height: 53,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF7C57FC), width: 1.5),
                  ),
                  fillColor: fillColor,
                  filled: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => _onChanged(val, index),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        // Timer / Resend section
        if (_secondsRemaining > 0)
          Text(
            'Resend code in 00:${_secondsRemaining.toString().padLeft(2, "0")}',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              widget.onResendCode();
              _startTimer();
            },
            child: Text(
              'Resend code',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C57FC),
              ),
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: widget.onChangeNumber,
          child: Text(
            'Change number',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7C57FC),
            ),
          ),
        ),
      ],
    );
  }
}
