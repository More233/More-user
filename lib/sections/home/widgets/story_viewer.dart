import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_story_group.dart';
import '../models/story_view_state.dart';
import '../view_models/story_view_model.dart';

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

  @override
  void initState() {
    super.initState();
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

  void _showViewsBottomSheet(BuildContext context, StoryViewState storyState) {
    _animationController.stop();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Story Views (${storyState.viewsCount})",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (storyState.viewers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      "No views yet",
                      style: GoogleFonts.ibmPlexSansArabic(color: Colors.white38),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: storyState.viewers.length,
                    itemBuilder: (context, index) {
                      final viewer = storyState.viewers[index]['user'];
                      if (viewer == null) return const SizedBox.shrink();
                      final avatarUrl = viewer['avatar_url'] as String?;
                      final username = viewer['username'] as String? ?? 'unknown';
                      final fullName = '${viewer['first_name'] ?? ''} ${viewer['last_name'] ?? ''}'.trim();
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : const AssetImage('assets/home/images/avatar_placeholder.png') as ImageProvider,
                        ),
                        title: Text(
                          username,
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: fullName.isNotEmpty
                            ? Text(
                                fullName,
                                style: GoogleFonts.ibmPlexSansArabic(color: Colors.white54, fontSize: 12),
                              )
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  Future<void> _deleteStory(String storyId) async {
    _animationController.stop();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text("Delete Story", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
        content: Text("Are you sure you want to delete this story?", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: GoogleFonts.ibmPlexSansArabic(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
        await notifier.deleteStory(storyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Story deleted"),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Error deleting story: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete story: $e")),
          );
          _animationController.forward();
        }
      }
    } else {
      _animationController.forward();
    }
  }

  void _addToHighlights() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Added to Highlights!"),
        backgroundColor: Color(0xFF7C57FC),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildOwnerBottomBar(BuildContext context, String currentStoryId, StoryViewState storyState) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => _deleteStory(currentStoryId),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/home/icons/delete_03.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFF5A5D67), BlendMode.srcIn),
                ),
                const SizedBox(height: 6),
                Text(
                  "Delete",
                  style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF5A5D67), fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _addToHighlights,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/home/icons/star_circle.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFF5A5D67), BlendMode.srcIn),
                ),
                const SizedBox(height: 6),
                Text(
                  "Highlight",
                  style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF5A5D67), fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showViewsBottomSheet(context, storyState),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/home/icons/info_circle_large.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFF7C57FC), BlendMode.srcIn),
                ),
                const SizedBox(height: 6),
                Text(
                  "${storyState.viewsCount} Views",
                  style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF7C57FC), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
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
      final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      await notifier.sendDM(text, widget.storyGroups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reply sent to @${widget.storyGroups[state.currentGroupIndex].username}!"),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
      final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      await notifier.sendDM(emoji, widget.storyGroups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reply sent to @${widget.storyGroups[state.currentGroupIndex].username}!"),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
    final topPadding = MediaQuery.of(context).padding.top;

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    final bool isOwner = currentUser != null && currentGroup.userId == currentUser.id;
    final double bottomSpacing = isOwner
        ? (64.0 + MediaQuery.of(context).padding.bottom)
        : (78.0 + MediaQuery.of(context).padding.bottom);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: bottomSpacing,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
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
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                              if (isOwner) {
                                _showViewsBottomSheet(context, storyState);
                              }
                            } else if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            color: Colors.grey[950],
                            child: Image.network(
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
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.65, sigmaY: 2.65),
                        child: Container(
                          color: const Color(0x4D989898),
                          padding: EdgeInsets.fromLTRB(16, topPadding > 0 ? topPadding + 8 : 16, 16, 12),
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
                                            currentGroup.username,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isOwner)
            Positioned(
              left: 16,
              bottom: 78 + MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      width: storyState.isReactionTrayOpen ? 290 : 0,
                      height: 50,
                      margin: EdgeInsets.only(left: storyState.isReactionTrayOpen ? 12 : 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: storyState.isReactionTrayOpen ? 1.0 : 0.0,
                          child: Row(
                            children: [
                              _buildStickerItem('assets/home/images/heart.png', '❤️'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/heart_eyes.png', '😍'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/hands_face.png', '🫣'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/fire.png', '🔥'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/thumbs_up.png', '👍'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/beer.png', '🍻'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/plus_one.png', '+1'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(
                            color: const Color(0xFFEFEFEF),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.only(left: 16, right: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: const Color(0xFF1F1F1F),
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Send Message",
                                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF737373),
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
              child: _buildOwnerBottomBar(context, currentGroup.storyIds[storyState.currentStoryIndex], storyState),
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
