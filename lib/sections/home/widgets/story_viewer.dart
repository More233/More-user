import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../models/user_story_group.dart';
import '../models/story_view_state.dart';
import '../view_models/story_view_model.dart';
import '../view_models/social_feed_view_model.dart';
import 'story_composer_screen.dart';
import 'story/story_delete_dialog.dart';
import 'story/story_options_sheet.dart';
import 'story/story_highlight_sheet.dart';
import 'story/story_views_sheet.dart';

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
  bool _simulateViews = false;

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
    _textController.addListener(() {
      setState(() {});
    });

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
    super.dispose();
  }

  void _startStory(StoryViewState storyState) {
    _animationController.reset();
    if (!_focusNode.hasFocus && !storyState.isReactionTrayOpen) {
      _animationController.forward();
    }
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).startStory(widget.storyGroups);
  }

  void _nextStory() {
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).nextStory(
      widget.storyGroups,
      () => Navigator.pop(context),
    );
  }

  void _previousStory() {
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).previousStory(widget.storyGroups);
  }

  List<Map<String, dynamic>> _getMockViewers() {
    return [
      {
        'user': {
          'username': 'karennne',
          'first_name': 'Karen',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar_female.png',
        },
        'badge': 'heart',
      },
      {
        'user': {
          'username': 'Sam_TD',
          'first_name': 'Sam',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar_male.png',
        },
        'badge': null,
      },
      {
        'user': {
          'username': 'kieron_d',
          'first_name': 'Kieron',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar.png',
        },
        'badge': 'fire',
      },
      {
        'user': {
          'username': 'craig_love',
          'first_name': 'Craig',
          'last_name': 'Love',
          'avatar_url': 'assets/home/images/profile_image2.png',
        },
        'badge': null,
      },
    ];
  }


  void _showViewsBottomSheet(BuildContext context, StoryViewState storyState, String currentStoryId) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StoryViewsSheet(
          storyState: storyState,
          currentStoryId: currentStoryId,
          simulateViews: _simulateViews,
          onSimulateViewsChanged: (val) {
            setState(() {
              _simulateViews = val;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showViewsBottomSheet(context, storyState, currentStoryId);
            });
          },
          onDeletePressed: () => _confirmDeleteStory(currentStoryId),
          mockViewers: _getMockViewers(),
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  Future<void> _confirmDeleteStory(String storyId) async {
    _animationController.stop();
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const StoryDeleteDialog(),
    );

    if (confirm == true) {
      try {
        final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
        await notifier.deleteStory(storyId);
        if (mounted) {
          ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Error deleting story: $e");
        if (mounted) {
          _animationController.forward();
        }
      }
    } else {
      _animationController.forward();
    }
  }

  void _showMoreOptions(BuildContext context, String storyId) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StoryOptionsSheet(
          onAddToStory: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StoryComposerScreen(),
              ),
            );
          },
          onDeleteStory: () => _confirmDeleteStory(storyId),
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  void _showHighlightBottomSheet(BuildContext context, String currentMediaUrl) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StoryHighlightSheet(
          currentMediaUrl: currentMediaUrl,
          onCompleted: (selectedHighlight) {
            // Completed silently without SnackBar
          },
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  void _showSendBottomSheet(BuildContext context) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StorySendSheetContent(
          onDismissed: () {},
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  void _showMentionBottomSheet(BuildContext context) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StoryMentionSheetContent(
          onDismissed: () {},
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  Widget _buildOverlappingAvatars(List<Map<String, dynamic>> viewers) {
    final list = _simulateViews || viewers.isNotEmpty 
        ? (viewers.isNotEmpty ? viewers : _getMockViewers()) 
        : <Map<String, dynamic>>[];
        
    if (list.isEmpty) {
      return SvgPicture.asset(
        'assets/home/icons/user_multiple.svg',
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }
    
    final displayViewers = list.take(3).toList();
    return SizedBox(
      width: 24.0 + (displayViewers.length - 1) * 12.0,
      height: 24,
      child: Stack(
        children: List.generate(displayViewers.length, (index) {
          final viewer = displayViewers[index]['user'];
          final avatarUrl = viewer != null ? viewer['avatar_url'] as String? : null;
          
          return Positioned(
            left: index * 12.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (avatarUrl.startsWith('http')
                        ? Image.network(avatarUrl, fit: BoxFit.cover)
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOwnerBottomBar(BuildContext context, String currentStoryId, String currentMediaUrl, StoryViewState storyState) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItem(
            icon: _buildOverlappingAvatars(storyState.viewers),
            label: "Activity",
            onTap: () => _showViewsBottomSheet(context, storyState, currentStoryId),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/like_icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: "Highlight",
            onTap: () => _showHighlightBottomSheet(context, currentMediaUrl),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/sent.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: "Send",
            onTap: () => _showSendBottomSheet(context),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/at.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: "Mention",
            onTap: () => _showMentionBottomSheet(context),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.string(
              '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M4 7H20M4 12H20M4 17H20" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round"/>
              </svg>''',
              width: 24,
              height: 24,
            ),
            label: "More",
            onTap: () {
              _showMoreOptions(context, currentStoryId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 26,
              child: Center(
                child: icon,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    try {
      final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
      await notifier.sendDM(text, widget.storyGroups);
    } catch (e) {
      debugPrint("Failed to send message: $e");
    }

    final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
    if (!state.isReactionTrayOpen) {
      _animationController.forward();
    }
  }

  Future<void> _sendEmojiReaction(String emoji) async {
    final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
    notifier.setReactionTrayOpen(false);

    try {
      await notifier.sendDM(emoji, widget.storyGroups);
    } catch (e) {
      debugPrint("Failed to send message: $e");
    }

    if (!_focusNode.hasFocus) {
      _animationController.forward();
    }
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
                                  notifier.nextGroup(widget.storyGroups, () => Navigator.pop(context));
                                }
                              } else if (details.primaryVelocity! > 100) {
                                // Dragged right
                                if (isRtl) {
                                  notifier.nextGroup(widget.storyGroups, () => Navigator.pop(context));
                                } else {
                                  notifier.previousGroup(widget.storyGroups);
                                }
                              }
                            }
                          },
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                              if (isOwner) {
                                _showViewsBottomSheet(
                                  context,
                                  storyState,
                                  currentGroup.storyIds[storyState.currentStoryIndex],
                                );
                              }
                            } else if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            color: Colors.grey[950],
                            child: _isVideoFile(currentMediaUrl)
                                ? _StoryVideoWidget(
                                    videoUrl: currentMediaUrl,
                                    isSelected: true,
                                  )
                                : Image.network(
                                    currentMediaUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                      ),
                                    ),
                                  ),
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
                              Row(
                                children: List.generate(
                                  currentGroup.mediaUrls.length,
                                  (index) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.35),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            index < storyState.currentStoryIndex
                                                ? Container(
                                                    height: 3,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  )
                                                : index == storyState.currentStoryIndex
                                                    ? AnimatedBuilder(
                                                        animation: _animationController,
                                                        builder: (context, child) {
                                                          return FractionallySizedBox(
                                                            alignment: Alignment.centerLeft,
                                                            widthFactor: _animationController.value,
                                                            child: Container(
                                                              height: 3,
                                                              decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                borderRadius: BorderRadius.circular(2),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    : const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[800],
                                    backgroundImage: currentGroup.avatarUrl != null &&
                                            currentGroup.avatarUrl!.isNotEmpty
                                        ? NetworkImage(currentGroup.avatarUrl!) as ImageProvider
                                        : const AssetImage('assets/home/images/avatar_placeholder.png'),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isOwner ? "Your Story" : currentGroup.username,
                                            style: GoogleFonts.ibmPlexSansArabic(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              shadows: [
                                                const Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black45,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (currentGroup.createdTimes.isNotEmpty &&
                                              storyState.currentStoryIndex < currentGroup.createdTimes.length) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                color: Colors.white54,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimeAgo(currentGroup.createdTimes[storyState.currentStoryIndex]),
                                              style: GoogleFonts.ibmPlexSansArabic(
                                                color: const Color(0xFFE1E1E1),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                shadows: [
                                                  const Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.black45,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
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
            // 1. Floating Sticker Reaction Tray (Opens vertically above the smiley button)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              left: 16,
              right: 16,
              bottom: storyState.isReactionTrayOpen
                  ? (78 + MediaQuery.of(context).padding.bottom + 16 + 62)
                  : (78 + MediaQuery.of(context).padding.bottom + 16),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: storyState.isReactionTrayOpen ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !storyState.isReactionTrayOpen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white12, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStickerItem('assets/home/images/heart.png', '❤️'),
                        _buildStickerItem('assets/home/images/heart_eyes.png', '😍'),
                        _buildStickerItem('assets/home/images/hands_face.png', '🫣'),
                        _buildStickerItem('assets/home/images/fire.png', '🔥'),
                        _buildStickerItem('assets/home/images/thumbs_up.png', '👍'),
                        _buildStickerItem('assets/home/images/beer.png', '🍻'),
                        _buildStickerItem('assets/home/images/plus_one.png', '+1'),
                      ],
                    ),
                  ),
                ),
              ),
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
              child: Container(
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
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(27),
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
                                controller: _textController,
                                focusNode: _focusNode,
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
                                onSubmitted: (value) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 58,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C57FC),
                                  borderRadius: BorderRadius.circular(19),
                                ),
                                child: storyState.isSending
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
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildOwnerBottomBar(
                context,
                currentGroup.storyIds[storyState.currentStoryIndex],
                currentMediaUrl,
                storyState,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
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

  Widget _buildStickerItem(String assetPath, String emoji) {
    final bool isSvg = assetPath.endsWith('.svg');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _sendEmojiReaction(emoji);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: isSvg
              ? SvgPicture.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                )
              : Image.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}


class _StorySendSheetContent extends StatefulWidget {
  final VoidCallback onDismissed;
  const _StorySendSheetContent({required this.onDismissed});

  @override
  State<_StorySendSheetContent> createState() => _StorySendSheetContentState();
}

class _StorySendSheetContentState extends State<_StorySendSheetContent> {
  List<Map<String, String>> _allFriends = [];
  List<Map<String, String>> _filteredFriends = [];
  final Set<String> _selectedUsernames = {};
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadRealUsers();
  }

  Future<void> _loadRealUsers() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final followingResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followersResponse = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUserId);

      final List<String> userIds = [];
      for (var row in followingResponse) {
        final id = row['following_id'] as String?;
        if (id != null) userIds.add(id);
      }
      for (var row in followersResponse) {
        final id = row['follower_id'] as String?;
        if (id != null) userIds.add(id);
      }

      final Map<String, Map<String, String>> usersMap = {};

      void addProfile(dynamic row) {
        if (row == null) return;
        final id = row['id'] as String?;
        if (id == null || id == currentUserId) return;
        final username = row['username'] as String? ?? '';
        final firstName = row['first_name'] as String? ?? '';
        final lastName = row['last_name'] as String? ?? '';
        final avatarUrl = row['avatar_url'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        usersMap[id] = {
          'id': id,
          'name': name.isNotEmpty ? name : username,
          'username': username,
          'avatar': avatarUrl,
        };
      }

      if (userIds.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', userIds);

        for (var row in profilesResponse) {
          addProfile(row);
        }
      }

      if (usersMap.length < 5) {
        final fallbackResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .neq('id', currentUserId)
            .limit(20);

        for (var row in fallbackResponse) {
          addProfile(row);
        }
      }

      setState(() {
        _allFriends = usersMap.values.toList();
        _filteredFriends = _allFriends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading real users for story send sheet: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {

      if (query.trim().isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend['name']!.toLowerCase().contains(query.toLowerCase()) ||
                friend['username']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        return AssetImage(avatarUrl);
      }
    }
    return const AssetImage('assets/home/images/avatar_female.png');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + keyboardPadding + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Send",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF82858C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: const Color(0xFF1F242E),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C57FC),
                ),
              ),
            )
          else if (_filteredFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "No friends found",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final f = _filteredFriends[index];
                    final username = f['username']!;
                    final name = f['name']!;
                    final avatar = f['avatar'];
                    final isSelected = _selectedUsernames.contains(username);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarProvider(avatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF1F1F1F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "@$username",
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF7C57FC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUsernames.add(username);
                                } else {
                                  _selectedUsernames.remove(username);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedUsernames.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Send",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: _selectedUsernames.isEmpty ? const Color(0xFF8E8E93) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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

class _StoryMentionSheetContent extends StatefulWidget {
  final VoidCallback onDismissed;
  const _StoryMentionSheetContent({required this.onDismissed});

  @override
  State<_StoryMentionSheetContent> createState() => _StoryMentionSheetContentState();
}

class _StoryMentionSheetContentState extends State<_StoryMentionSheetContent> {
  List<Map<String, String>> _allFriends = [];
  List<Map<String, String>> _filteredFriends = [];
  final Set<String> _selectedUsernames = {};
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadRealUsers();
  }

  Future<void> _loadRealUsers() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final followingResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followersResponse = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUserId);

      final List<String> userIds = [];
      for (var row in followingResponse) {
        final id = row['following_id'] as String?;
        if (id != null) userIds.add(id);
      }
      for (var row in followersResponse) {
        final id = row['follower_id'] as String?;
        if (id != null) userIds.add(id);
      }

      final Map<String, Map<String, String>> usersMap = {};

      void addProfile(dynamic row) {
        if (row == null) return;
        final id = row['id'] as String?;
        if (id == null || id == currentUserId) return;
        final username = row['username'] as String? ?? '';
        final firstName = row['first_name'] as String? ?? '';
        final lastName = row['last_name'] as String? ?? '';
        final avatarUrl = row['avatar_url'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        usersMap[id] = {
          'id': id,
          'name': name.isNotEmpty ? name : username,
          'username': username,
          'avatar': avatarUrl,
        };
      }

      if (userIds.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', userIds);

        for (var row in profilesResponse) {
          addProfile(row);
        }
      }

      if (usersMap.length < 5) {
        final fallbackResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .neq('id', currentUserId)
            .limit(20);

        for (var row in fallbackResponse) {
          addProfile(row);
        }
      }

      setState(() {
        _allFriends = usersMap.values.toList();
        _filteredFriends = _allFriends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading real users for story mention sheet: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {

      if (query.trim().isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend['name']!.toLowerCase().contains(query.toLowerCase()) ||
                friend['username']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        return AssetImage(avatarUrl);
      }
    }
    return const AssetImage('assets/home/images/avatar_female.png');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + keyboardPadding + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Mentions",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF82858C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: const Color(0xFF1F242E),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C57FC),
                ),
              ),
            )
          else if (_filteredFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "No friends found",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final f = _filteredFriends[index];
                    final username = f['username']!;
                    final name = f['name']!;
                    final avatar = f['avatar'];
                    final isSelected = _selectedUsernames.contains(username);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarProvider(avatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF1F1F1F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "@$username",
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF7C57FC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUsernames.add(username);
                                } else {
                                  _selectedUsernames.remove(username);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedUsernames.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Add",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: _selectedUsernames.isEmpty ? const Color(0xFF8E8E93) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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

bool _isVideoFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
}

class _StoryVideoWidget extends StatefulWidget {
  final String videoUrl;
  final bool isSelected;
  const _StoryVideoWidget({required this.videoUrl, required this.isSelected});

  @override
  State<_StoryVideoWidget> createState() => _StoryVideoWidgetState();
}

class _StoryVideoWidgetState extends State<_StoryVideoWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isSelected) {
          _controller!.play();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _StoryVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _isInitialized) {
      if (widget.isSelected && !oldWidget.isSelected) {
        _controller!.play();
      } else if (!widget.isSelected && oldWidget.isSelected) {
        _controller!.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}
