import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../view_models/story_editor_view_model.dart';

class TextEditorPanel extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const TextEditorPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  TextStyle _getFontFamilyStyle(String name) {
    switch (name) {
      case 'Literature':
        return GoogleFonts.playfairDisplay();
      case 'Classic':
        return GoogleFonts.lora();
      case 'Modern':
        return GoogleFonts.montserrat();
      case 'Typewriter':
        return GoogleFonts.courierPrime();
      case 'Elegant':
        return GoogleFonts.dancingScript();
      case 'Directional':
        return GoogleFonts.cinzel();
      default:
        return GoogleFonts.ibmPlexSansArabic();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    if (!state.isEditingText) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: SafeArea(
          child: Column(
            children: [
              // Alignment, background style, bold, and done top actions bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        state.selectedAlignment == TextAlign.center
                            ? Icons.format_align_center_rounded
                            : state.selectedAlignment == TextAlign.left
                                ? Icons.format_align_left_rounded
                                : Icons.format_align_right_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final current = state.selectedAlignment;
                        final nextAlign = current == TextAlign.center
                            ? TextAlign.left
                            : (current == TextAlign.left ? TextAlign.right : TextAlign.center);
                        notifier.updateTextStyling(alignment: nextAlign);
                      },
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          state.selectedBackgroundStyle == 'none'
                              ? 'A'
                              : state.selectedBackgroundStyle == 'normal'
                                  ? 'A▮'
                                  : state.selectedBackgroundStyle == 'neon'
                                      ? 'A*'
                                      : 'A#',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () {
                        final current = state.selectedBackgroundStyle;
                        final nextStyle = current == 'normal'
                            ? 'neon'
                            : (current == 'neon' ? 'pixel' : (current == 'pixel' ? 'none' : 'normal'));
                        notifier.updateTextStyling(backgroundStyle: nextStyle);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.format_bold_rounded,
                        color: state.selectedIsBold ? const Color(0xFF7C57FC) : Colors.white,
                      ),
                      onPressed: () {
                        notifier.updateTextStyling(isBold: !state.selectedIsBold);
                      },
                    ),
                    TextButton(
                      onPressed: onSubmit,
                      child: Text(
                        "Done",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // Center input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: state.selectedBackgroundStyle == 'normal' && state.selectedBgColor != null
                      ? BoxDecoration(
                          color: state.selectedBgColor,
                          borderRadius: BorderRadius.zero,
                        )
                      : state.selectedBackgroundStyle == 'neon'
                          ? BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: state.selectedTextColor.withValues(alpha: 0.5), width: 1.5),
                            )
                          : state.selectedBackgroundStyle == 'pixel'
                              ? BoxDecoration(
                                  color: Colors.black54,
                                  border: Border.all(color: state.selectedTextColor, width: 2),
                                )
                              : null,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    style: _getFontFamilyStyle(state.selectedFontFamily).copyWith(
                      color: state.selectedTextColor,
                      fontSize: 26,
                      fontWeight: state.selectedIsBold ? FontWeight.bold : FontWeight.w500,
                      shadows: state.selectedBackgroundStyle == 'neon'
                          ? [
                              Shadow(
                                color: state.selectedTextColor.withValues(alpha: 0.8),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    textAlign: state.selectedAlignment,
                    decoration: const InputDecoration(
                      hintText: "Type something...",
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ),
              const Spacer(),
              
              // Bottom selectors panel
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Font Family selection list
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          'Literature',
                          'Classic',
                          'Modern',
                          'Typewriter',
                          'Elegant',
                          'Directional',
                          'Default'
                        ].map((fontName) {
                          final isSelected = state.selectedFontFamily == fontName;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              selectedColor: const Color(0xFF7C57FC),
                              backgroundColor: Colors.white10,
                              checkmarkColor: Colors.white,
                              padding: EdgeInsets.zero,
                              label: Text(
                                fontName,
                                style: _getFontFamilyStyle(fontName).copyWith(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  notifier.updateTextStyling(fontFamily: fontName);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Colors selection list
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Colors.white,
                          const Color(0xFFFFB6C1),
                          Colors.black,
                          const Color(0xFF00C8FF),
                          const Color(0xFF2ECC71),
                          const Color(0xFFFFD700),
                          const Color(0xFFFF8C00),
                          const Color(0xFFFF4757),
                          const Color(0xFFFF1493),
                        ].map((color) {
                          final isSelected = state.selectedTextColor == color;
                          return GestureDetector(
                            onTap: () {
                              notifier.updateTextStyling(
                                color: color,
                                bgColor: color == Colors.black ? Colors.white : Colors.black87,
                                clearBgColor: false,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white24,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Effects selection list
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          'None',
                          'Typewriter',
                          'Pop',
                          'Jump'
                        ].map((effect) {
                          final isSelected = state.selectedEffect == effect;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              selectedColor: const Color(0xFFFF4757),
                              backgroundColor: Colors.white10,
                              checkmarkColor: Colors.white,
                              padding: EdgeInsets.zero,
                              label: Text(
                                effect,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  notifier.updateTextStyling(effect: effect);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
