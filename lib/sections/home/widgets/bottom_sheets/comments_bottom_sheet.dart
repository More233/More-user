import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/timeline_post.dart';
import '../../profile_screen.dart';

class CommentsBottomSheet extends StatefulWidget {
  final TimelinePost post;
  final Function(TimelineComment) onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.post,
    required this.onCommentAdded,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  String? _currentUserAvatar;
  bool _showEmojiPicker = false;

  List<Map<String, String>> _allProfiles = [
    {
      'username': 'sally.samer.3',
      'avatar_url': 'assets/home/images/element.png',
    },
    {
      'username': 'zackjohn',
      'avatar_url': 'assets/home/images/element.png',
    },
    {
      'username': 'kiero_d',
      'avatar_url': 'assets/home/images/element.png',
    },
    {
      'username': 'craig_love',
      'avatar_url': 'assets/home/images/element.png',
    },
    {
      'username': 'martini_rond',
      'avatar_url': 'assets/home/images/element.png',
    },
    {
      'username': 'jacob_w',
      'avatar_url': 'assets/home/images/element.png',
    },
  ];
  List<Map<String, String>> _mentionSuggestions = [];

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
    _fetchUsernamesFromDatabase();
    _fetchCurrentUserProfile();
    _fetchComments();
  }

  Future<void> _fetchCurrentUserProfile() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final data = await client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _currentUserAvatar = data['avatar_url'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching current user profile: $e");
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await Supabase.instance.client
          .from('post_comments')
          .select('*, author:profiles(username, avatar_url)')
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);

      final List<TimelineComment> fetched = [];
      for (final row in response) {
        final author = row['author'];
        final authorName = author?['username'] as String? ?? 'unknown';
        final authorAvatar = author?['avatar_url'] as String? ?? 'assets/home/images/element.png';
        final text = row['content'] as String? ?? '';
        final createdAtStr = row['created_at'] as String?;
        final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

        String timeAgo = 'Just now';
        if (createdAt != null) {
          final difference = DateTime.now().difference(createdAt.toLocal());
          if (difference.inMinutes < 1) {
            timeAgo = 'Just now';
          } else if (difference.inMinutes < 60) {
            timeAgo = '${difference.inMinutes}m ago';
          } else if (difference.inHours < 24) {
            timeAgo = '${difference.inHours}h ago';
          } else {
            timeAgo = '${difference.inDays}d ago';
          }
        }

        fetched.add(TimelineComment(
          authorName: authorName,
          authorAvatar: authorAvatar,
          commentText: text,
          timeAgo: timeAgo,
          authorId: row['user_id'] as String?,
        ));
      }

      if (mounted) {
        setState(() {
          widget.post.comments.clear();
          widget.post.comments.addAll(fetched);
          widget.post.commentsCount = fetched.length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    }
  }

  Future<void> _fetchUsernamesFromDatabase() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url');
      final List<Map<String, String>> fetched = [];
      for (final p in response) {
        final u = p['username'] as String?;
        final avatar = p['avatar_url'] as String?;
        if (u != null && u.isNotEmpty) {
          fetched.add({
            'username': u,
            'avatar_url': avatar ?? '',
          });
        }
      }
      if (fetched.isNotEmpty && mounted) {
        setState(() {
          final merged = <String, Map<String, String>>{};
          for (final p in _allProfiles) {
            merged[p['username']!] = p;
          }
          for (final p in fetched) {
            merged[p['username']!] = p;
          }
          _allProfiles = merged.values.toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching usernames: $e");
    }
  }

  void _onTextChanged() {
    final text = _commentController.text;
    final cursorPosition = _commentController.selection.baseOffset;
    if (cursorPosition < 0) return;

    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpace = textBeforeCursor.lastIndexOf(' ');
    final currentWord = textBeforeCursor.substring(lastSpace + 1);

    if (currentWord.startsWith('@')) {
      final query = currentWord.substring(1).toLowerCase();
      setState(() {
        _mentionSuggestions = _allProfiles
            .where((p) => p['username']!.toLowerCase().contains(query))
            .toList();
      });
    } else {
      if (_mentionSuggestions.isNotEmpty) {
        setState(() {
          _mentionSuggestions = [];
        });
      }
    }
  }

  void _selectMention(String username) {
    final text = _commentController.text;
    final cursorPosition = _commentController.selection.baseOffset;
    if (cursorPosition < 0) return;

    final textBeforeCursor = text.substring(0, cursorPosition);
    final textAfterCursor = text.substring(cursorPosition);
    final lastSpace = textBeforeCursor.lastIndexOf(' ');

    final newTextBeforeCursor = '${textBeforeCursor.substring(0, lastSpace + 1)}@$username ';

    _commentController.text = '$newTextBeforeCursor$textAfterCursor';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: newTextBeforeCursor.length),
    );

    setState(() {
      _mentionSuggestions = [];
    });
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return;

    final profileResponse = await client
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', currentUser.id)
        .maybeSingle();

    final username = profileResponse?['username'] as String? ?? 'unknown';
    final avatar = profileResponse?['avatar_url'] as String? ?? 'assets/home/images/element.png';

    final comment = TimelineComment(
      authorName: username,
      authorAvatar: avatar,
      commentText: text,
      timeAgo: 'Just now',
      authorId: currentUser.id,
    );

    widget.onCommentAdded(comment);
    _commentController.clear();
    setState(() {});

    try {
      await client.from('post_comments').insert({
        'post_id': widget.post.id,
        'user_id': currentUser.id,
        'content': text,
      });

      final postResponse = await client
          .from('posts')
          .select('user_id')
          .eq('id', widget.post.id)
          .maybeSingle();

      if (postResponse != null) {
        final authorId = postResponse['user_id'] as String;
        if (authorId != currentUser.id) {
          await client.from('notifications').insert({
            'sender_id': currentUser.id,
            'receiver_id': authorId,
            'type': 'comment',
            'post_id': widget.post.id,
            'metadata': {'comment': text},
          });
        }
      }

      // Parse mentions
      final RegExp mentionRegex = RegExp(r'@([a-zA-Z0-9_\.]+)');
      final matches = mentionRegex.allMatches(text);
      final Set<String> mentionedUsernames = {};
      for (final match in matches) {
        final u = match.group(1);
        if (u != null) {
          mentionedUsernames.add(u);
        }
      }

      if (mentionedUsernames.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username')
            .inFilter('username', mentionedUsernames.toList());

        for (final profile in profilesResponse) {
          final receiverId = profile['id'] as String;
          if (receiverId != currentUser.id) {
            await client.from('notifications').insert({
              'sender_id': currentUser.id,
              'receiver_id': receiverId,
              'type': 'comment_mention',
              'post_id': widget.post.id,
              'metadata': {'comment': text},
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error saving comment: $e");
    }
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen height and push sheet upwards when keyboard is open
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF131722) : Colors.white;
    final Color dragHandleColor = isDark ? const Color(0xFF323A4E) : const Color(0xFFC8C8C8);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drag handle slider
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: dragHandleColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Comments (${widget.post.comments.length})',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: dividerColor),
            // List of comments
            Expanded(
              child: widget.post.comments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: widget.post.comments.length,
                      itemBuilder: (context, index) {
                        final comment = widget.post.comments[index];
                        return _buildCommentItem(comment);
                      },
                    ),
            ),
            if (_mentionSuggestions.isNotEmpty) ...[
              Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _mentionSuggestions.length,
                  itemBuilder: (context, index) {
                    final profile = _mentionSuggestions[index];
                    final username = profile['username']!;
                    final avatarUrl = profile['avatar_url']!;
  
                    Widget avatarWidget;
                    if (avatarUrl.startsWith('http')) {
                      avatarWidget = CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(avatarUrl),
                      );
                    } else if (avatarUrl.isNotEmpty) {
                      avatarWidget = CircleAvatar(
                        radius: 12,
                        backgroundImage: AssetImage(avatarUrl),
                      );
                    } else {
                      avatarWidget = const CircleAvatar(
                        radius: 12,
                        backgroundImage: AssetImage(
                          'assets/home/images/element.png',
                        ),
                      );
                    }
  
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: avatarWidget,
                        backgroundColor: const Color(0xFFF6F6F6),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        label: Text(
                          '@$username',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: const Color(0xFF7C57FC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _selectMention(username),
                      ),
                    );
                  },
                ),
              ),
            ],
            Divider(height: 1, color: dividerColor),
            // Bottom Input bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x335D5D5D), // rgba(93, 93, 93, 0.2)
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/home/icons/message_multiple_02lg.svg',
              width: 64,
              height: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No comments yet',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(TimelineComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              if (comment.authorId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: comment.authorId),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: comment.authorAvatar.startsWith('http')
                  ? CachedNetworkImageProvider(comment.authorAvatar) as ImageProvider
                  : (comment.authorAvatar.isNotEmpty
                      ? AssetImage(comment.authorAvatar)
                      : const AssetImage('assets/home/images/element.png')) as ImageProvider,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (comment.authorId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(userId: comment.authorId),
                            ),
                          );
                        }
                      },
                      child: Text(
                        comment.authorName,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: const Color(0xFF82858C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildCommentText(comment.commentText),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // reply action mock
                  },
                  child: Text(
                    'Reply',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C57FC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Heart icon
          GestureDetector(
            onTap: () {
              setState(() {
                comment.isLiked = !comment.isLiked;
                if (comment.isLiked) {
                  comment.likesCount += 1;
                } else {
                  comment.likesCount -= 1;
                }
              });
            },
            child: Column(
              children: [
                Icon(
                  comment.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: comment.isLiked ? Colors.red : const Color(0xFF5A5D67),
                ),
                if (comment.likesCount > 0)
                  Text(
                    '${comment.likesCount}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 10,
                      color: const Color(0xFF5A5D67),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentText(String text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white70 : const Color(0xFF3B3C4F);
    final List<TextSpan> spans = [];
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final spacing = i == words.length - 1 ? '' : ' ';
      if (word.startsWith('@') && word.length > 1) {
        spans.add(
          TextSpan(
            text: '$word$spacing',
            style: GoogleFonts.ibmPlexSansArabic(
              color: const Color(0xFF7C57FC),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$word$spacing',
            style: GoogleFonts.ibmPlexSansArabic(
              color: textColor,
            ),
          ),
        );
      }
    }
    return RichText(
      text: TextSpan(
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
        children: spans,
      ),
    );
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emojis = ['😊', '😂', '❤️', '👍', '🔥', '😍', '🙌', '✨', '👏'];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showEmojiPicker)
            Container(
              height: 48,
              color: const Color(0xFFF9F9F9),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  return GestureDetector(
                    onTap: () {
                      final currentText = _commentController.text;
                      final selection = _commentController.selection;
                      
                      // Append emoji to text and keep cursor position intact
                      String newText;
                      int newCursorPosition;
                      
                      if (selection.start >= 0) {
                        newText = currentText.replaceRange(selection.start, selection.end, emoji);
                        newCursorPosition = selection.start + emoji.length;
                      } else {
                        newText = currentText + emoji;
                        newCursorPosition = newText.length;
                      }
                      
                      _commentController.text = newText;
                      _commentController.selection = TextSelection.fromPosition(
                        TextPosition(offset: newCursorPosition),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            color: isDark ? const Color(0xFF131722) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Profile avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _currentUserAvatar != null && _currentUserAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider(_currentUserAvatar!) as ImageProvider
                      : const AssetImage('assets/home/images/element.png'),
                ),
                const SizedBox(width: 12),
                // TextField
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2430) : const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : const Color(0xFF82858C),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: (_) => _submitComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Emoji button icon (interactive)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                          child: Icon(
                            Icons.sentiment_satisfied_alt_outlined,
                            color: _showEmojiPicker ? const Color(0xFF7C57FC) : Colors.grey.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C57FC),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.send,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
