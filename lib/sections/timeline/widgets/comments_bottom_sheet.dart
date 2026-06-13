import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timeline_post.dart';

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

  List<Map<String, String>> _allProfiles = [
    {
      'username': 'sally.samer.3',
      'avatar_url': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
    },
    {
      'username': 'zackjohn',
      'avatar_url': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
    },
    {
      'username': 'kiero_d',
      'avatar_url': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
    },
    {
      'username': 'craig_love',
      'avatar_url': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
    },
    {
      'username': 'martini_rond',
      'avatar_url': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
    },
    {
      'username': 'jacob_w',
      'avatar_url': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
    },
  ];
  List<Map<String, String>> _mentionSuggestions = [];

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
    _fetchUsernamesFromDatabase();
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

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final comment = TimelineComment(
      authorName: 'sally.samer.3',
      authorAvatar: 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
      commentText: text,
      timeAgo: 'Just now',
    );

    widget.onCommentAdded(comment);
    _commentController.clear();
    setState(() {}); // refresh the sheet view
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
                color: const Color(0xFFC8C8C8),
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
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
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
                        backgroundImage: NetworkImage(avatarUrl),
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
                          'assets/Timeline/Personal Timeline  Default State/image/Element.png',
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
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
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
              'assets/Timeline/Comments  Empty Comments Bottom Sheet/icon/message-multiple-02lg.svg',
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
              color: Colors.black,
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
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(
              'assets/Timeline/Personal Timeline  Default State/image/Element.png',
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
                    Text(
                      comment.authorName,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
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
              color: const Color(0xFF3B3C4F),
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
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Profile avatar
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(
                'assets/Timeline/Personal Timeline  Default State/image/Element.png',
              ),
            ),
            const SizedBox(width: 12),
            // TextField
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF82858C),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Emoji button icon (placeholder)
                    Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: Colors.grey.withValues(alpha: 0.7),
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
    );
  }
}
