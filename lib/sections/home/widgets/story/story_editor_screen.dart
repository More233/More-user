import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../models/story_overlay_item.dart';
import '../../view_models/story_editor_view_model.dart';

// Import modular components
import 'components/sidebar_buttons.dart';
import 'components/text_editor_panel.dart';
import 'components/mention_input_panel.dart';
import 'components/trash_can_overlay.dart';
import 'components/overlay_item_widget.dart';

class StoryEditorScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool isReels;
  const StoryEditorScreen({super.key, required this.imagePath, this.isReels = false});

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  
  VideoPlayerController? _videoPlayerController;
  final ValueNotifier<VideoPlayerController?> _videoControllerNotifier = ValueNotifier(null);
  
  // Local controllers for hardware focus/inputs
  final TextEditingController _textOverlayController = TextEditingController();
  final FocusNode _textOverlayFocus = FocusNode();
  final TextEditingController _mentionController = TextEditingController();
  final FocusNode _mentionFocus = FocusNode();

  final List<String> _stickerEmojis = ['❤️', '😍', '🫣', '🔥', '👍', '🍻', '👏', '😂', '🎉', '🌟', '🍿', '💯'];

  double _canvasWidth = 360.0;
  double _canvasHeight = 640.0;

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEditorViewModelProvider.notifier).fetchFollowedUsers();
    });
    
    if (_isVideoFile(widget.imagePath)) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    final controller = VideoPlayerController.file(File(widget.imagePath));
    try {
      final state = ref.read(storyEditorViewModelProvider);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(state.isAudioMuted ? 0.0 : 1.0);
      await controller.play();
      _videoPlayerController = controller;
      _videoControllerNotifier.value = controller;
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
  }

  void _toggleMute() {
    final state = ref.read(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);
    notifier.setAudioMuted(!state.isAudioMuted);
    _videoPlayerController?.setVolume(!state.isAudioMuted ? 0.0 : 1.0);
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _videoControllerNotifier.dispose();
    _textOverlayController.dispose();
    _textOverlayFocus.dispose();
    _mentionController.dispose();
    _mentionFocus.dispose();
    super.dispose();
  }

  void _addEmojiOverlay(String emoji) {
    final newItem = StoryOverlayItem(
      id: UniqueKey().toString(),
      type: 'sticker',
      data: emoji,
      position: Offset(_canvasWidth / 2, _canvasHeight / 2),
    );
    ref.read(storyEditorViewModelProvider.notifier).addOverlay(newItem);
  }

  void _onTextSubmit() {
    final text = _textOverlayController.text.trim();
    final state = ref.read(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    if (text.isNotEmpty) {
      final textData = {
        'text': text,
        'color': state.selectedTextColor.toARGB32(),
        'backgroundColor': state.selectedBgColor?.toARGB32(),
        'fontFamily': state.selectedFontFamily,
        'alignment': state.selectedAlignment == TextAlign.left
            ? 'left'
            : (state.selectedAlignment == TextAlign.right ? 'right' : 'center'),
        'isBold': state.selectedIsBold,
        'backgroundStyle': state.selectedBackgroundStyle,
        'effect': state.selectedEffect,
        'fontSize': state.selectedFontSize,
      };

      final existingIndex = state.overlays.indexWhere((o) => o.id == state.selectedOverlayId && o.type == 'text');
      if (existingIndex != -1) {
        notifier.updateOverlay(StoryOverlayItem(
          id: state.selectedOverlayId!,
          type: 'text',
          data: textData,
          position: state.overlays[existingIndex].position,
          scale: state.overlays[existingIndex].scale,
          rotation: state.overlays[existingIndex].rotation,
          size: state.overlays[existingIndex].size,
        ));
      } else {
        final newItem = StoryOverlayItem(
          id: UniqueKey().toString(),
          type: 'text',
          data: textData,
          position: Offset(_canvasWidth / 2, _canvasHeight / 2),
        );
        notifier.addOverlay(newItem);
      }
      _textOverlayController.clear();
    }
    notifier.setEditingText(false);
  }

  void _onMentionSubmit() {
    final mention = _mentionController.text.trim().replaceAll('@', '');
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    if (mention.isNotEmpty) {
      final newItem = StoryOverlayItem(
        id: UniqueKey().toString(),
        type: 'mention',
        data: '@$mention',
        position: Offset(_canvasWidth / 2, _canvasHeight / 2),
      );
      notifier.addOverlay(newItem);
      _mentionController.clear();
    }
    notifier.setEditingMention(false);
  }

  void _showStickersDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1F1F1F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Sticker",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _stickerEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _stickerEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      _addEmojiOverlay(emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1F1F1F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.music_note, color: Colors.white),
                title: Text("Music (Mock)", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _addMusicOverlay();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.white),
                title: Text("Link (Mock)", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addMusicOverlay() {
    final newItem = StoryOverlayItem(
      id: UniqueKey().toString(),
      type: 'music',
      data: {
        'title': 'Starlight',
        'artist': 'Taylor Swift',
      },
      position: Offset(_canvasWidth / 2, _canvasHeight / 2),
    );
    ref.read(storyEditorViewModelProvider.notifier).addOverlay(newItem);
  }

  Future<void> _publishStory() async {
    final notifier = ref.read(storyEditorViewModelProvider.notifier);
    
    await notifier.publishStory(
      localFilePath: widget.imagePath,
      canvasWidth: _canvasWidth,
      canvasHeight: _canvasHeight,
      onSuccess: () {
        if (mounted) {
          Navigator.pop(context); // Close Editor
          Navigator.pop(context); // Close Composer
        }
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to publish: $err")),
          );
        }
      },
    );
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

  Widget _buildOverlayContentWidget(String type, dynamic data) {
    switch (type) {
      case 'music':
        final track = Map<String, String>.from(data as Map? ?? {});
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_note, color: Color(0xFF7C57FC), size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track['title'] ?? '',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    track['artist'] ?? '',
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      case 'mention':
        final mention = data as String;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C57FC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            mention,
            style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      case 'location':
        final Map locationData = data as Map;
        final name = locationData['name'] as String? ?? 'Location';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C57FC), // brand purple
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                name,
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      case 'sticker':
        final emoji = data as String;
        return Material(
          color: Colors.transparent,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
        );
      case 'text':
        final String text;
        final Color textColor;
        final Color? bgColor;
        final String fontFamily;
        final TextAlign alignment;
        final bool isBold;
        final String backgroundStyle;
        final double fontSize;
        
        if (data is Map) {
          final dataMap = Map<String, dynamic>.from(data);
          text = dataMap['text'] as String? ?? '';
          textColor = Color(dataMap['color'] as int? ?? Colors.white.toARGB32());
          bgColor = dataMap['backgroundColor'] != null ? Color(dataMap['backgroundColor'] as int) : null;
          fontFamily = dataMap['fontFamily'] as String? ?? 'Default';
          final alignStr = dataMap['alignment'] as String? ?? 'center';
          alignment = alignStr == 'left' ? TextAlign.left : (alignStr == 'right' ? TextAlign.right : TextAlign.center);
          isBold = dataMap['isBold'] as bool? ?? false;
          backgroundStyle = dataMap['backgroundStyle'] as String? ?? 'normal';
          fontSize = (dataMap['fontSize'] as num?)?.toDouble() ?? 26.0;
        } else {
          text = data as String? ?? '';
          textColor = Colors.white;
          bgColor = Colors.black87;
          fontFamily = 'Default';
          alignment = TextAlign.center;
          isBold = false;
          backgroundStyle = 'normal';
          fontSize = 26.0;
        }

        TextStyle textStyle = _getFontFamilyStyle(fontFamily).copyWith(
          color: textColor,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          height: 1.2,
        );

        if (backgroundStyle == 'neon') {
          textStyle = textStyle.copyWith(
            shadows: [
              Shadow(
                color: textColor.withValues(alpha: 0.8),
                blurRadius: 10,
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: backgroundStyle == 'normal' && bgColor != null
              ? BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.zero,
                )
              : backgroundStyle == 'neon'
                  ? BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: textColor.withValues(alpha: 0.5), width: 1.5),
                    )
                  : backgroundStyle == 'pixel'
                      ? BoxDecoration(
                          color: Colors.black54,
                          border: Border.all(color: textColor, width: 2),
                        )
                      : null,
          child: Text(
            text,
            textAlign: alignment,
            style: textStyle,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onDoubleTapTextOverlay(StoryOverlayItem item) {
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    notifier.setEditingText(true);
    
    if (item.data is Map) {
      final dataMap = Map<String, dynamic>.from(item.data as Map);
      _textOverlayController.text = dataMap['text'] as String? ?? '';
      
      final textColor = Color(dataMap['color'] as int? ?? Colors.white.toARGB32());
      final bgColor = dataMap['backgroundColor'] != null ? Color(dataMap['backgroundColor'] as int) : null;
      
      notifier.updateTextStyling(
        color: textColor,
        bgColor: bgColor,
        clearBgColor: bgColor == null,
        fontFamily: dataMap['fontFamily'] as String? ?? 'Default',
        alignment: (dataMap['alignment'] as String? ?? 'center') == 'left'
            ? TextAlign.left
            : ((dataMap['alignment'] as String? ?? 'center') == 'right'
                ? TextAlign.right
                : TextAlign.center),
        isBold: dataMap['isBold'] as bool? ?? false,
        backgroundStyle: dataMap['backgroundStyle'] as String? ?? 'normal',
        effect: dataMap['effect'] as String? ?? 'none',
      );
    } else {
      _textOverlayController.text = item.data as String? ?? '';
      notifier.updateTextStyling(
        color: Colors.white,
        bgColor: Colors.black87,
        fontFamily: 'Default',
        alignment: TextAlign.center,
        isBold: false,
        backgroundStyle: 'normal',
        effect: 'none',
      );
    }
    _textOverlayFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Top black spacer for status bar
            Container(
              height: topPadding,
              color: Colors.black,
            ),
            
            // Viewfinder Card (rounded corners, expands to fill space)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _canvasWidth = constraints.maxWidth;
                      _canvasHeight = constraints.maxHeight;

                      return Stack(
                        children: [
                          // 1. Repaint Boundary Canvas
                          RepaintBoundary(
                            key: _repaintKey,
                            child: SizedBox(
                              width: _canvasWidth,
                              height: _canvasHeight,
                              child: Stack(
                                children: [
                                  // Background Video or Image using ValueListenableBuilder (No local setState)
                                  Positioned.fill(
                                    child: ValueListenableBuilder<VideoPlayerController?>(
                                      valueListenable: _videoControllerNotifier,
                                      builder: (context, controller, child) {
                                        if (controller != null && controller.value.isInitialized) {
                                          return SizedBox.expand(
                                            child: FittedBox(
                                              fit: BoxFit.cover,
                                              child: SizedBox(
                                                width: controller.value.size.width,
                                                height: controller.value.size.height,
                                                child: VideoPlayer(controller),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Image.file(
                                            File(widget.imagePath),
                                            fit: BoxFit.cover,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  
                                  // Overlays stack
                                  ...state.overlays.map((item) {
                                    return OverlayItemWidget(
                                      item: item,
                                      canvasWidth: _canvasWidth,
                                      canvasHeight: _canvasHeight,
                                      buildOverlayContent: _buildOverlayContentWidget,
                                      onDoubleTapText: () => _onDoubleTapTextOverlay(item),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                          // 2. Guidelines (Center lines overlay)
                          if (state.showVerticalCenterGuide)
                            Positioned(
                              left: _canvasWidth / 2 - 1,
                              top: 0,
                              bottom: 0,
                              width: 2,
                              child: Container(color: Colors.amber.withValues(alpha: 0.8)),
                            ),
                          if (state.showHorizontalCenterGuide)
                            Positioned(
                              top: _canvasHeight / 2 - 1,
                              left: 0,
                              right: 0,
                              height: 2,
                              child: Container(color: Colors.amber.withValues(alpha: 0.8)),
                            ),
                          if (state.showLeftGuide)
                            Positioned(
                              left: 24,
                              top: 0,
                              bottom: 0,
                              width: 1,
                              child: Container(color: Colors.blue.withValues(alpha: 0.5)),
                            ),
                          if (state.showRightGuide)
                            Positioned(
                              left: _canvasWidth - 24,
                              top: 0,
                              bottom: 0,
                              width: 1,
                              child: Container(color: Colors.blue.withValues(alpha: 0.5)),
                            ),
                          if (state.showTopGuide)
                            Positioned(
                              top: 24,
                              left: 0,
                              right: 0,
                              height: 1,
                              child: Container(color: Colors.blue.withValues(alpha: 0.5)),
                            ),
                          if (state.showBottomGuide)
                            Positioned(
                              top: _canvasHeight - 24,
                              left: 0,
                              right: 0,
                              height: 1,
                              child: Container(color: Colors.blue.withValues(alpha: 0.5)),
                            ),

                          // 3. Floating Back Button (Top Left)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: SvgPicture.asset(
                                  'assets/home/icons/arrow_left_01.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),

                          // 4. Sidebar tools panel Component
                          if (!state.isEditingText && !state.isEditingMention)
                            SidebarButtons(
                              hasVideo: _videoPlayerController != null,
                              onVolumeTap: _toggleMute,
                              onTextTap: () {
                                notifier.selectOverlay(null);
                                notifier.setEditingText(true);
                                _textOverlayController.clear();
                                notifier.updateTextStyling(
                                  color: Colors.white,
                                  bgColor: Colors.black87,
                                  fontFamily: 'Default',
                                  alignment: TextAlign.center,
                                  isBold: false,
                                  backgroundStyle: 'normal',
                                  effect: 'none',
                                );
                                _textOverlayFocus.requestFocus();
                              },
                              onStickerTap: _showStickersDrawer,
                              onMentionTap: () {
                                notifier.setEditingMention(true);
                                _mentionController.clear();
                                _mentionFocus.requestFocus();
                              },
                              onMoreTap: _showMoreOptionsSheet,
                            ),

                          // 5. Rich Text Editor Panel Component (No local setState)
                          TextEditorPanel(
                            controller: _textOverlayController,
                            focusNode: _textOverlayFocus,
                            onSubmit: _onTextSubmit,
                            canvasKey: _repaintKey,
                          ),

                          // 6. Mention Input Panel Component (No local setState)
                          MentionInputPanel(
                            controller: _mentionController,
                            focusNode: _mentionFocus,
                            onSubmit: _onMentionSubmit,
                          ),

                          // 7. Loading publisher overlay spinner
                          if (state.isPublishing)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(color: Color(0xFF7C57FC)),
                              ),
                            ),

                          // 8. Trash can overlay at bottom center Component
                          const TrashCanOverlay(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // 9. White Bottom Action Bar (Same design as original)
            if (!state.isEditingText && !state.isEditingMention && MediaQuery.of(context).viewInsets.bottom == 0)
              Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: bottomPadding > 0 ? bottomPadding + 12 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Friends Button
                    GestureDetector(
                      onTap: _publishStory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/home/icons/star_circle.svg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Close Friends",
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: const Color(0xFF464646),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Send Button (Purple circular icon with sent.svg)
                    GestureDetector(
                      onTap: _publishStory,
                      child: Container(
                        width: 52,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: state.isPublishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : SvgPicture.asset(
                                'assets/home/icons/sent.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
