import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_story_group.dart';
import '../../models/story_view_state.dart';
import '../../view_models/story_view_model.dart';
import '../../helpers/story_preloader.dart';
import 'story_video_widget.dart';

// Viewer Components
import 'components/viewer_progress_bar.dart';
import 'components/viewer_header.dart';
import 'components/viewer_reaction_tray.dart';
import 'components/viewer_message_input.dart';
import 'components/viewer_owner_bottom_bar.dart';
import 'components/story_overlay_renderer.dart';
import 'components/viewer_sheets_helper.dart';

part 'story_viewer_logic.dart';

class StoryViewer extends ConsumerStatefulWidget {
  final List<UserStoryGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
  });

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  
  final ValueNotifier<int> _videoCacheRevisionNotifier = ValueNotifier(0);

  // Cached video player controllers to avoid lag and recreate delays
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Set<String> _initializingUrls = {};

  bool _isPopped = false;
  void _safePop() {
    if (!mounted || _isPopped) return;
    _isPopped = true;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _textController = TextEditingController();

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      final storyState = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      if (_focusNode.hasFocus) {
        _animationController.stop();
      } else {
        if (!storyState.isReactionTrayOpen) {
          _animationController.forward();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storyState = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      _preloadMedia(storyState);
      _startStory(storyState);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _videoCacheRevisionNotifier.dispose();
    // Dispose all preloaded video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    if (widget.storyGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final storyState = ref.watch(storyViewModelProvider(widget.initialGroupIndex));

    ref.listen<StoryViewState>(storyViewModelProvider(widget.initialGroupIndex), (previous, next) {
      if (previous?.currentGroupIndex != next.currentGroupIndex ||
          previous?.currentStoryIndex != next.currentStoryIndex) {
        _preloadMedia(next);
        _startStory(next);
      }
    });

    final currentGroup = widget.storyGroups[storyState.currentGroupIndex];
    final currentMediaUrl = currentGroup.mediaUrls[storyState.currentStoryIndex];

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    final bool isOwner = currentUser != null && currentGroup.userId == currentUser.id;
    final double bottomSpacing = isOwner
        ? (64.0 + MediaQuery.of(context).padding.bottom)
        : (78.0 + MediaQuery.of(context).padding.bottom);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            bottom: bottomSpacing,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardHeight = constraints.maxHeight;
                        return GestureDetector(
                          onTapDown: (details) {
                            if (_isTouchInReactionArea(details.localPosition, cardHeight, storyState.isReactionTrayOpen)) {
                              return;
                            }
                            _animationController.stop();
                          },
                          onTapUp: (details) {
                            if (_isTouchInReactionArea(details.localPosition, cardHeight, storyState.isReactionTrayOpen)) {
                              return;
                            }
                            if (_focusNode.hasFocus) {
                              _focusNode.unfocus();
                              return;
                            }
                            if (storyState.isReactionTrayOpen) {
                              ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).setReactionTrayOpen(false);
                              _animationController.forward();
                              return;
                            }

                            final screenWidth = MediaQuery.of(context).size.width;
                            if (details.globalPosition.dx < screenWidth / 3) {
                              _previousStory();
                            } else {
                              _nextStory();
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              final isRtl = Directionality.of(context) == TextDirection.rtl;
                              final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
                              if (details.primaryVelocity! < -100) {
                                // Dragged left
                                if (isRtl) {
                                  notifier.previousGroup(widget.storyGroups);
                                } else {
                                  notifier.nextGroup(widget.storyGroups, _safePop);
                                }
                              } else if (details.primaryVelocity! > 100) {
                                // Dragged right
                                if (isRtl) {
                                  notifier.nextGroup(widget.storyGroups, _safePop);
                                } else {
                                  notifier.previousGroup(widget.storyGroups);
                                }
                              }
                            }
                          },
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                              if (isOwner) {
                                showViewsBottomSheet(
                                  context: context,
                                  ref: ref,
                                  initialGroupIndex: widget.initialGroupIndex,
                                  animationController: _animationController,
                                  storyState: storyState,
                                  currentStoryId: currentGroup.storyIds[storyState.currentStoryIndex],
                                );
                              }
                            } else if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                              _safePop();
                            }
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final viewerWidth = constraints.maxWidth;
                              final viewerHeight = constraints.maxHeight;

                              final List<dynamic> storyOverlays =
                                  (storyState.currentStoryIndex < currentGroup.overlays.length)
                                      ? currentGroup.overlays[storyState.currentStoryIndex]
                                      : [];

                              return Container(
                                color: Colors.grey[950],
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: isVideoFile(currentMediaUrl)
                                          ? ValueListenableBuilder<int>(
                                              valueListenable: _videoCacheRevisionNotifier,
                                              builder: (context, val, child) {
                                                final controller = _videoControllers[currentMediaUrl];
                                                if (controller != null && controller.value.isInitialized) {
                                                  // Keep the animation controller's duration in sync with the video duration
                                                  if (_animationController.duration != controller.value.duration) {
                                                    _animationController.duration = controller.value.duration;
                                                    if (_animationController.isAnimating) {
                                                      _animationController.forward(from: _animationController.value);
                                                    }
                                                  }
                                                  return StoryVideoWidget(
                                                    controller: controller,
                                                    isSelected: true,
                                                    onBufferingChanged: (isBuffering) {
                                                      if (isBuffering) {
                                                        _animationController.stop();
                                                      } else {
                                                        if (!_focusNode.hasFocus && !storyState.isReactionTrayOpen) {
                                                          _animationController.forward();
                                                        }
                                                      }
                                                    },
                                                    onVideoCompleted: () {
                                                      _nextStory();
                                                    },
                                                  );
                                                } else {
                                                  _animationController.stop();
                                                  return const Center(
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                }
                                              },
                                            )
                                          : (currentMediaUrl.startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl: currentMediaUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  placeholder: (context, url) {
                                                    // Make sure timer runs on image
                                                    if (_animationController.duration != const Duration(seconds: 5)) {
                                                      _animationController.duration = const Duration(seconds: 5);
                                                      if (_animationController.isAnimating) {
                                                        _animationController.forward(from: _animationController.value);
                                                      }
                                                    }
                                                    return const Center(
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                      ),
                                                    );
                                                  },
                                                  errorWidget: (context, url, error) => Container(
                                                    color: Colors.grey[900],
                                                    child: const Center(
                                                      child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                                    ),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(currentMediaUrl),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )),
                                    ),
                                    ...storyOverlays.map((itemMap) {
                                      final item = Map<String, dynamic>.from(itemMap as Map? ?? {});
                                      final type = item['type'] as String? ?? 'text';
                                      final data = item['data'];
                                      final normalizedX = (item['normalizedX'] as num? ?? 0.5).toDouble();
                                      final normalizedY = (item['normalizedY'] as num? ?? 0.5).toDouble();
                                      final scale = (item['scale'] as num? ?? 1.0).toDouble();
                                      final rotation = (item['rotation'] as num? ?? 0.0).toDouble();
                                      final width = (item['width'] as num? ?? 100.0).toDouble();
                                      final height = (item['height'] as num? ?? 40.0).toDouble();

                                      const double stickerPadding = 48.0;
                                      final paddedWidth = (width + 2 * stickerPadding) * scale;
                                      final paddedHeight = (height + 2 * stickerPadding) * scale;

                                      final actualX = normalizedX * viewerWidth;
                                      final actualY = normalizedY * viewerHeight;

                                      return Positioned(
                                        left: actualX - (paddedWidth / 2),
                                        top: actualY - (paddedHeight / 2),
                                        width: paddedWidth,
                                        height: paddedHeight,
                                        child: Transform.rotate(
                                          angle: rotation,
                                          child: FittedBox(
                                            fit: BoxFit.fill,
                                            child: Container(
                                              padding: const EdgeInsets.all(stickerPadding),
                                              color: Colors.transparent,
                                              child: buildStoryOverlayWidget(type, data),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 180,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ViewerProgressBar(
                            mediaUrlsLength: currentGroup.mediaUrls.length,
                            currentStoryIndex: storyState.currentStoryIndex,
                            animationController: _animationController,
                          ),
                          const SizedBox(height: 12),
                          ViewerHeader(
                            avatarUrl: currentGroup.avatarUrl,
                            username: currentGroup.username,
                            isOwner: isOwner,
                            createdTime: currentGroup.createdTimes.isNotEmpty &&
                                    storyState.currentStoryIndex < currentGroup.createdTimes.length
                                ? currentGroup.createdTimes[storyState.currentStoryIndex]
                                : null,
                            onClose: _safePop,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isOwner) ...[
            // 1. Floating Sticker Reaction Tray
            ViewerReactionTray(
              isReactionTrayOpen: storyState.isReactionTrayOpen,
              onReactionSelected: _sendEmojiReaction,
            ),
            
            // 2. Smiley Toggle Button
            Positioned(
              left: 16,
              bottom: 78 + MediaQuery.of(context).padding.bottom + 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
                  final nextState = !storyState.isReactionTrayOpen;
                  notifier.setReactionTrayOpen(nextState);
                  if (nextState) {
                    _animationController.stop();
                  } else {
                    if (!_focusNode.hasFocus) {
                      _animationController.forward();
                    }
                  }
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD3D3D3), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/home/icons/smile.svg',
                      width: 48,
                      height: 48,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ViewerMessageInput(
                textController: _textController,
                focusNode: _focusNode,
                isSending: storyState.isSending,
                onSend: _sendMessage,
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ViewerOwnerBottomBar(
                currentStoryId: currentGroup.storyIds[storyState.currentStoryIndex],
                currentMediaUrl: currentMediaUrl,
                viewers: storyState.viewers,
                onActivityTap: () => showViewsBottomSheet(
                  context: context,
                  ref: ref,
                  initialGroupIndex: widget.initialGroupIndex,
                  animationController: _animationController,
                  storyState: storyState,
                  currentStoryId: currentGroup.storyIds[storyState.currentStoryIndex],
                ),
                onDeleteTap: () => confirmDeleteStory(
                  context: context,
                  ref: ref,
                  initialGroupIndex: widget.initialGroupIndex,
                  animationController: _animationController,
                  storyId: currentGroup.storyIds[storyState.currentStoryIndex],
                ),
              ),
            ),
        ],
      ),
    );
  }


  bool _isTouchInReactionArea(Offset localPosition, double cardHeight, bool isReactionTrayOpen) {
    final double areaLeft = 16;
    final double areaWidth = isReactionTrayOpen ? 352 : 50;
    final double areaHeight = 50;
    
    final double areaBottom = cardHeight - 16;
    final double areaTop = areaBottom - areaHeight;
    final double areaRight = areaLeft + areaWidth;

    final double x = localPosition.dx;
    final double y = localPosition.dy;

    return x >= areaLeft && x <= areaRight && y >= areaTop && y <= areaBottom;
  }

}


