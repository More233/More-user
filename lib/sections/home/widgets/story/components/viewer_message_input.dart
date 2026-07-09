import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewerMessageInput extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const ViewerMessageInput({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom + 12
            : MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.only(left: 16, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      focusNode: focusNode,
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: "Send Message",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 58,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C57FC),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: isSending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Center(
                              child: SvgPicture.asset(
                                'assets/home/icons/sent.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
