import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../view_models/story_editor_view_model.dart';
import '../../../models/story_overlay_item.dart';
import '../../bottom_sheets/location_search_sheet.dart';

class TextEditorPanel extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final GlobalKey canvasKey;

  const TextEditorPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.canvasKey,
  });

  @override
  ConsumerState<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends ConsumerState<TextEditorPanel> {
  late final PageController _pageController;
  int _activeColorPage = 0;
  String _activeTool = 'font'; // 'font', 'color', 'effect'

  // Eye dropper state
  bool _isEyeDropping = false;
  Offset _dropperPosition = Offset.zero;
  Color _dropperColor = Colors.white;
  ui.Image? _screenshotImage;
  Uint8List? _screenshotBytes;

  final List<List<Color>> _colorPages = [
    [
      Colors.white,
      const Color(0xFFFFB6C1),
      Colors.black,
      const Color(0xFF00C8FF),
      const Color(0xFF2ECC71),
      const Color(0xFFFFD700),
      const Color(0xFFFF8C00),
      const Color(0xFFFF4757),
      const Color(0xFFFF1493),
    ],
    [
      const Color(0xFFE8D7FF), // Lavender
      const Color(0xFFD4EDDA), // Sage
      const Color(0xFFFFF3CD), // Sand
      const Color(0xFFF8D7DA), // Peach
      const Color(0xFFD1ECF1), // Pale Cyan
      const Color(0xFFCCE5FF), // Pale Blue
      const Color(0xFFF5C6CB), // Rose
      const Color(0xFFFFEECC), // Cream
      const Color(0xFFE2E3E5), // Light Gray
    ],
    [
      const Color(0xFF00FFCC), // Neon turquoise
      const Color(0xFFFF007F), // Neon pink
      const Color(0xFF7B00FF), // Electric violet
      const Color(0xFF39FF14), // Lime green
      const Color(0xFFFF5F1F), // Neon orange
      const Color(0xFFCCFF00), // Acid green
      const Color(0xFFE0B0FF), // Mauve
      const Color(0xFFFFD700), // Gold
      const Color(0xFF4D4DFF), // Royal Blue
    ],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.contains('@')) {
      final lastAt = text.lastIndexOf('@');
      final query = text.substring(lastAt);
      ref.read(storyEditorViewModelProvider.notifier).updateMentionSuggestions(query);
    } else {
      ref.read(storyEditorViewModelProvider.notifier).updateMentionSuggestions('');
    }
  }

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

  Future<void> _startEyeDropper() async {
    setState(() {
      _isEyeDropping = true;
      _dropperPosition = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );
    });

    try {
      final boundary = widget.canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) {
          setState(() {
            _screenshotImage = image;
            _screenshotBytes = byteData.buffer.asUint8List();
          });
          _updateColorAtPosition(_dropperPosition);
        }
      }
    } catch (e) {
      debugPrint("Error capturing screenshot for eye dropper: $e");
    }
  }

  void _updateColorAtPosition(Offset position) {
    if (_screenshotBytes == null || _screenshotImage == null) return;

    final imageWidth = _screenshotImage!.width;
    final imageHeight = _screenshotImage!.height;

    // Convert local position to image coordinates
    final x = position.dx.clamp(0.0, imageWidth - 1.0).toInt();
    final y = position.dy.clamp(0.0, imageHeight - 1.0).toInt();

    final index = (y * imageWidth + x) * 4;
    if (index >= 0 && index + 3 < _screenshotBytes!.length) {
      final r = _screenshotBytes![index];
      final g = _screenshotBytes![index + 1];
      final b = _screenshotBytes![index + 2];
      final a = _screenshotBytes![index + 3];
      final color = Color.fromARGB(a, r, g, b);

      setState(() {
        _dropperColor = color;
        _dropperPosition = position;
      });

      final notifier = ref.read(storyEditorViewModelProvider.notifier);
      final state = ref.read(storyEditorViewModelProvider);

      if (state.selectedBackgroundStyle == 'normal') {
        notifier.updateTextStyling(
          bgColor: color,
          clearBgColor: false,
        );
      } else {
        notifier.updateTextStyling(
          color: color,
          bgColor: null,
          clearBgColor: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    if (!state.isEditingText) return const SizedBox.shrink();

    final text = widget.controller.text;
    final showSuggestions = text.contains('@');
    final suggestions = state.mentionSuggestions;

    return Positioned.fill(
      child: Container(
        color: _isEyeDropping ? Colors.transparent : Colors.black.withValues(alpha: 0.9),
        child: Stack(
          children: [
            // Standard Text Editor Panel (Hidden during eye dropping)
            if (!_isEyeDropping) ...[
              // Center input field and vertical font size slider
              SafeArea(
                child: Stack(
                  children: [
                    // Vertical slider on the left
                    Positioned(
                      left: 12,
                      top: MediaQuery.of(context).size.height * 0.2,
                      bottom: MediaQuery.of(context).size.height * 0.45,
                      child: VerticalFontSizeSlider(
                        value: state.selectedFontSize,
                        min: 12.0,
                        max: 60.0,
                        onChanged: (newSize) {
                          notifier.updateTextStyling(fontSize: newSize);
                        },
                      ),
                    ),

                    // Center Textfield
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 64, right: 32),
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
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            autofocus: true,
                            maxLines: null,
                            style: _getFontFamilyStyle(state.selectedFontFamily).copyWith(
                              color: state.selectedTextColor,
                              fontSize: state.selectedFontSize,
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
                            onSubmitted: (_) => widget.onSubmit(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom controls panel anchored directly above the keyboard
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ROW 1: Active selection view (Font family list, Color page, Effects list)
                      if (_activeTool == 'font') ...[
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
                                child: GestureDetector(
                                  onTap: () {
                                    notifier.updateTextStyling(fontFamily: fontName);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF7C57FC) : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF7C57FC) : Colors.white24,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        fontName,
                                        style: _getFontFamilyStyle(fontName).copyWith(
                                          fontSize: 13,
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else if (_activeTool == 'color') ...[
                        // Color selection swiping view
                        SizedBox(
                          height: 36,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (pageIndex) {
                              setState(() {
                                _activeColorPage = pageIndex;
                              });
                            },
                            itemCount: _colorPages.length,
                            itemBuilder: (context, pageIndex) {
                              final pageColors = _colorPages[pageIndex];
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: pageColors.length + (pageIndex == 0 ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (pageIndex == 0 && index == 0) {
                                    // Dropper Button (rounded square, 1:1 ratio)
                                    return Center(
                                      child: GestureDetector(
                                        onTap: _startEyeDropper,
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white12,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white38, width: 1.5),
                                          ),
                                          child: const Icon(Icons.colorize_rounded, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    );
                                  }

                                  final color = pageColors[pageIndex == 0 ? index - 1 : index];
                                  final isSelected = state.selectedBackgroundStyle == 'normal'
                                      ? state.selectedBgColor == color
                                      : state.selectedTextColor == color;

                                  // Wrapped in Center to ensure exactly 1:1 aspect ratio (no stretch)
                                  return Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (state.selectedBackgroundStyle == 'normal') {
                                          final textCol = (color == Colors.white || 
                                                           color == const Color(0xFFFFB6C1) || 
                                                           color == const Color(0xFFFFD700))
                                              ? Colors.black
                                              : Colors.white;
                                          notifier.updateTextStyling(
                                            color: textCol,
                                            bgColor: color,
                                            clearBgColor: false,
                                          );
                                        } else {
                                          notifier.updateTextStyling(
                                            color: color,
                                            bgColor: null,
                                            clearBgColor: true,
                                          );
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF7C57FC) : Colors.white24,
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Page Indicator Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_colorPages.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _activeColorPage == index ? Colors.white : Colors.white30,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                      ] else if (_activeTool == 'effect') ...[
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
                                child: GestureDetector(
                                  onTap: () {
                                    notifier.updateTextStyling(effect: effect);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFF4757) : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFF4757) : Colors.white24,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        effect,
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ROW 2: Core formatting icon buttons bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Font selector Aa toggle
                            IconButton(
                              icon: Icon(
                                Icons.text_fields_rounded,
                                color: _activeTool == 'font' ? const Color(0xFF7C57FC) : Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _activeTool = 'font';
                                });
                              },
                            ),

                            // Color selector wheel toggle
                            IconButton(
                              icon: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.cyan,
                                      Colors.blue,
                                      Color(0xFFFF00FF),
                                      Colors.red,
                                    ],
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _activeTool = 'color';
                                });
                              },
                            ),

                            // Alignment cycles
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

                            // Text Background bubble style (A▮)
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
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onPressed: () {
                                final current = state.selectedBackgroundStyle;
                                final nextStyle = current == 'normal'
                                    ? 'neon'
                                    : (current == 'neon' ? 'pixel' : (current == 'pixel' ? 'none' : 'normal'));
                                
                                Color textColor = state.selectedTextColor;
                                Color? bgColor = state.selectedBgColor;
                                bool clearBg = false;
                                
                                if (nextStyle == 'normal') {
                                  bgColor = (state.selectedTextColor == Colors.white && state.selectedBgColor == null)
                                      ? Colors.black87
                                      : state.selectedTextColor;
                                  textColor = (bgColor == Colors.white || 
                                               bgColor == const Color(0xFFFFB6C1) || 
                                               bgColor == const Color(0xFFFFD700)) 
                                      ? Colors.black 
                                      : Colors.white;
                                } else if (nextStyle == 'none') {
                                  if (state.selectedBgColor != null) {
                                    textColor = state.selectedBgColor!;
                                  }
                                  bgColor = null;
                                  clearBg = true;
                                } else if (nextStyle == 'neon' || nextStyle == 'pixel') {
                                  if (state.selectedBgColor != null) {
                                    textColor = state.selectedBgColor!;
                                  }
                                  bgColor = null;
                                  clearBg = true;
                                }
                                
                                notifier.updateTextStyling(
                                  backgroundStyle: nextStyle,
                                  color: textColor,
                                  bgColor: bgColor,
                                  clearBgColor: clearBg,
                                );
                              },
                            ),

                            // Bold B toggle
                            IconButton(
                              icon: Icon(
                                Icons.format_bold_rounded,
                                color: state.selectedIsBold ? const Color(0xFF7C57FC) : Colors.white,
                              ),
                              onPressed: () {
                                notifier.updateTextStyling(isBold: !state.selectedIsBold);
                              },
                            ),

                            // Effects toggle A+
                            IconButton(
                              icon: Icon(
                                Icons.star_purple500_rounded,
                                color: _activeTool == 'effect' ? const Color(0xFFFF4757) : Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _activeTool = 'effect';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ROW 3: Mention user list OR Mention/Location tab buttons
                      if (showSuggestions && suggestions.isNotEmpty) ...[
                        // Horizontally scrollable user avatars suggestion row
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final user = suggestions[index];
                              final username = user['username'] as String? ?? '';
                              return GestureDetector(
                                onTap: () {
                                  final text = widget.controller.text;
                                  final lastAt = text.lastIndexOf('@');
                                  final newText = '${text.substring(0, lastAt)}@$username ';
                                  widget.controller.text = newText;
                                  widget.controller.selection = TextSelection.fromPosition(
                                    TextPosition(offset: newText.length),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: user['avatar_url'] != null
                                            ? NetworkImage(user['avatar_url'])
                                            : null,
                                        child: user['avatar_url'] == null
                                            ? const Icon(Icons.person, color: Colors.white, size: 20)
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        username,
                                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        // Static @ Mention | Location tab bar directly above keyboard
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white10, width: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // Mention button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final currentText = widget.controller.text;
                                    final nextText = currentText.endsWith(' ') || currentText.isEmpty
                                        ? '$currentText@'
                                        : '$currentText @';
                                    widget.controller.text = nextText;
                                    widget.controller.selection = TextSelection.fromPosition(
                                      TextPosition(offset: nextText.length),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("@", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Mention",
                                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 0.5, height: 20, color: Colors.white24),
                              // Location button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final mediaSize = MediaQuery.of(context).size;
                                    final loc = await showModalBottomSheet<Map<String, dynamic>>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const LocationSearchSheet(),
                                    );
                                    if (loc != null && mounted) {
                                      notifier.addOverlay(
                                        StoryOverlayItem(
                                          id: UniqueKey().toString(),
                                          type: 'location',
                                          data: loc,
                                          position: Offset(
                                            mediaSize.width / 2,
                                            mediaSize.height / 2,
                                          ),
                                        ),
                                      );
                                      widget.onSubmit();
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Location",
                                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Absolutely positioned Done button at the very top right
              Positioned(
                top: 12,
                right: 16,
                child: TextButton(
                  onPressed: widget.onSubmit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Done",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // Real Interactive Eye Dropper Layer
            if (_isEyeDropping)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (details) {
                    _updateColorAtPosition(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    _updateColorAtPosition(details.localPosition);
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _isEyeDropping = false;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // Magnifying Dropper Pin pointing down, offset upward so finger doesn't block it
                        Positioned(
                          left: _dropperPosition.dx - 25,
                          top: _dropperPosition.dy - 72,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Visual magnifier preview circle
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _dropperColor,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.colorize_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              // Tip pointer triangle
                              CustomPaint(
                                size: const Size(10, 15),
                                painter: PinTipPainter(),
                              ),
                            ],
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
    );
  }
}

class PinTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerticalFontSizeSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const VerticalFontSizeSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 200,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final pct = (1.0 - (localPos.dy / 200)).clamp(0.0, 1.0);
            final newValue = min + (pct * (max - min));
            onChanged(newValue);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vertical track
            Container(
              width: 5,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white12,
                    Colors.white60,
                  ],
                ),
              ),
            ),
            // Thumb positioned dynamically
            Positioned(
              bottom: ((value - min) / (max - min) * 170).clamp(0.0, 170.0),
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
