import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserStoryGroup {
  final String userId;
  final String username;
  final String? avatarUrl;
  final List<String> mediaUrls;

  UserStoryGroup({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.mediaUrls,
  });
}

class StoryViewer extends StatefulWidget {
  final List<UserStoryGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  late int _currentStoryIndex;
  late AnimationController _animationController;
  
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _isReactionTrayOpen = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _currentStoryIndex = 0;

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
      if (_focusNode.hasFocus) {
        _animationController.stop();
      } else {
        if (!_isReactionTrayOpen) {
          _animationController.forward();
        }
      }
    });

    _startStory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startStory() {
    _animationController.reset();
    if (!_focusNode.hasFocus && !_isReactionTrayOpen) {
      _animationController.forward();
    }
  }

  void _nextStory() {
    if (_isSending) return;

    final currentGroup = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex < currentGroup.mediaUrls.length - 1) {
      // Next story in the same group
      setState(() {
        _currentStoryIndex++;
      });
      _startStory();
    } else {
      // Next story group
      if (_currentGroupIndex < widget.storyGroups.length - 1) {
        setState(() {
          _currentGroupIndex++;
          _currentStoryIndex = 0;
          _isReactionTrayOpen = false;
        });
        _textController.clear();
        _focusNode.unfocus();
        _startStory();
      } else {
        // End of all stories, close
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (_isSending) return;

    if (_currentStoryIndex > 0) {
      // Previous story in the same group
      setState(() {
        _currentStoryIndex--;
      });
      _startStory();
    } else {
      // Previous story group
      if (_currentGroupIndex > 0) {
        setState(() {
          _currentGroupIndex--;
          _currentStoryIndex = widget.storyGroups[_currentGroupIndex].mediaUrls.length - 1;
          _isReactionTrayOpen = false;
        });
        _textController.clear();
        _focusNode.unfocus();
        _startStory();
      } else {
        // At the beginning, restart first story
        _startStory();
      }
    }
  }

  Future<void> _sendDM(String content) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      final currentUserId = currentUser.id;
      final otherUserId = widget.storyGroups[_currentGroupIndex].userId;

      if (currentUserId == otherUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot send a reply to your own story"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Fetch existing threads for current user
      final threadsResponse = await client
          .from('chat_threads')
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId');

      final threads = List<Map<String, dynamic>>.from(threadsResponse);
      final existingThreadIndex = threads.indexWhere(
        (t) => (t['user1_id'] == currentUserId && t['user2_id'] == otherUserId) ||
               (t['user1_id'] == otherUserId && t['user2_id'] == currentUserId),
      );

      String? threadId;
      if (existingThreadIndex != -1) {
        threadId = threads[existingThreadIndex]['id'];
      } else {
        // Create a new thread
        final insertResponse = await client.from('chat_threads').insert({
          'user1_id': currentUserId,
          'user2_id': otherUserId,
        }).select().single();
        threadId = insertResponse['id'];
      }

      if (threadId != null) {
        // Insert message
        await client.from('chat_messages').insert({
          'thread_id': threadId,
          'sender_id': currentUserId,
          'message_type': 'text',
          'content': cleanContent,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Reply sent to @${widget.storyGroups[_currentGroupIndex].username}!"),
              backgroundColor: const Color(0xFF7C3AED),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending story reply: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    await _sendDM(text);

    // Resume story playback
    if (!_isReactionTrayOpen) {
      _animationController.forward();
    }
  }

  Future<void> _sendEmojiReaction(String emoji) async {
    setState(() {
      _isReactionTrayOpen = false;
    });

    await _sendDM(emoji);

    // Resume story playback
    if (!_focusNode.hasFocus) {
      _animationController.forward();
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.storyGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentGroup = widget.storyGroups[_currentGroupIndex];
    final currentMediaUrl = currentGroup.mediaUrls[_currentStoryIndex];
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Top Frame: Story Image card with rounded bottom corners
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: Stack(
                children: [
                  // Story Media (Image)
                  Positioned.fill(
                    child: GestureDetector(
                      onTapDown: (details) {
                        _animationController.stop();
                      },
                      onTapUp: (details) {
                        if (_focusNode.hasFocus) {
                          _focusNode.unfocus();
                          return;
                        }
                        if (_isReactionTrayOpen) {
                          setState(() {
                            _isReactionTrayOpen = false;
                          });
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
                        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
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
                    ),
                  ),

                  // Top gradient shadow to make text and icons readable
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

                  // Progress indicator & Profile header (positioned below device status bar)
                  Positioned(
                    top: topPadding > 0 ? topPadding + 8 : 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress indicators
                        Row(
                          children: List.generate(
                            currentGroup.mediaUrls.length,
                            (index) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: Stack(
                                    children: [
                                      // Background bar
                                      Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      // Active progress bar
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        right: index < _currentStoryIndex
                                            ? 0
                                            : (index == _currentStoryIndex
                                                ? null
                                                : MediaQuery.of(context).size.width),
                                        child: index == _currentStoryIndex
                                            ? AnimatedBuilder(
                                                animation: _animationController,
                                                builder: (context, child) {
                                                  return FractionallySizedBox(
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
                                            : Container(
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Profile header info row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: currentGroup.avatarUrl != null &&
                                      currentGroup.avatarUrl!.isNotEmpty
                                  ? NetworkImage(currentGroup.avatarUrl!) as ImageProvider
                                  : const AssetImage('assets/Timeline/images/avatar_placeholder.png'),
                            ),
                            const SizedBox(width: 10),
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
                ],
              ),
            ),
          ),

          // Bottom Frame: Footer text input & reaction tray
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sliding reaction tray
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isReactionTrayOpen
                    ? Container(
                        margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['❤️', '☀️', '🫣', '👍', '🔥', '😍'].map((emoji) {
                            return GestureDetector(
                              onTap: () => _sendEmojiReaction(emoji),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Bottom input box and Smiley button
              Padding(
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
                    // Text Input Bar
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white24,
                            width: 0.8,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  hintText: "Send Message...",
                                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.white54,
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
                            if (_textController.text.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.purpleAccent,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        color: Colors.purpleAccent,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _sendMessage,
                                    ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Floating purple smiley button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isReactionTrayOpen = !_isReactionTrayOpen;
                        });
                        if (_isReactionTrayOpen) {
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
                          color: const Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
