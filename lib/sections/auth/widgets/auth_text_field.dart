import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextInputType keyboardType;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.autofocus = false,
    this.inputFormatters,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor = isDark ? Colors.white70 : const Color(0xFF262626);
    final Color containerBg = isDark ? const Color(0xFF1E2433) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color hintColor = isDark ? Colors.white30 : const Color(0xFF9CA3AF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Label
        Text(
          widget.labelText,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        // Input Field Container
        GestureDetector(
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              _focusNode.requestFocus();
            }
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : _isFocused
                        ? const Color(0xFF7C57FC)
                        : borderColor,
                width: _isFocused || hasError ? 1.5 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C57FC).withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    readOnly: widget.readOnly,
                    autofocus: widget.autofocus,
                    keyboardType: widget.keyboardType,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: hintColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                  ),
                ),
                if (widget.suffixIcon != null) widget.suffixIcon!,
                // Clear button when focused and text is not empty
                if (widget.controller.text.isNotEmpty && _isFocused && widget.suffixIcon == null)
                  GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      if (widget.onChanged != null) {
                        widget.onChanged!('');
                      }
                    },
                    child: const Icon(
                      Icons.cancel,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }
}
