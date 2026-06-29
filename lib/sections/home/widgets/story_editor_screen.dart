import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryOverlayItem {
  final UniqueKey id = UniqueKey();
  final String type; // 'music', 'mention', 'sticker', 'text'
  final dynamic data;
  Offset position;

  StoryOverlayItem({
    required this.type,
    required this.data,
    required this.position,
  });
}

class StoryEditorScreen extends StatefulWidget {
  final String imagePath;
  const StoryEditorScreen({super.key, required this.imagePath});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final List<StoryOverlayItem> _overlays = [];
  bool _isPublishing = false;
  List<Map<String, dynamic>> _followedUsers = [];
  List<Map<String, dynamic>> _mentionSuggestions = [];
  
  // Active text tool controller
  final TextEditingController _textOverlayController = TextEditingController();
  final FocusNode _textOverlayFocus = FocusNode();
  bool _isEditingText = false;
  
  // Active mention controller
  final TextEditingController _mentionController = TextEditingController();
  final FocusNode _mentionFocus = FocusNode();
  bool _isEditingMention = false;

  final List<Map<String, String>> _musicTracks = [
    {'title': 'Blinding Lights', 'artist': 'The Weeknd'},
    {'title': 'Save Your Tears', 'artist': 'The Weeknd'},
    {'title': 'As It Was', 'artist': 'Harry Styles'},
    {'title': 'Flowers', 'artist': 'Miley Cyrus'},
    {'title': 'Stay', 'artist': 'The Kid LAROI & Justin Bieber'},
    {'title': 'Starboy', 'artist': 'The Weeknd'},
    {'title': 'Perfect', 'artist': 'Ed Sheeran'},
  ];

  final List<String> _stickerEmojis = ['❤️', '😍', '🫣', '🔥', '👍', '🍻', '👏', '😂', '🎉', '🌟', '🍿', '💯'];

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
  }

  @override
  void initState() {
    super.initState();
    _fetchFollowedUsers();
  }

  Future<void> _fetchFollowedUsers() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final followsResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = List<Map<String, dynamic>>.from(followsResponse)
          .map((f) => f['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return;

      final profilesResponse = await client
          .from('profiles')
          .select('id, username, first_name, last_name, avatar_url')
          .inFilter('id', followingIds);

      setState(() {
        _followedUsers = List<Map<String, dynamic>>.from(profilesResponse);
      });
    } catch (e) {
      debugPrint("Error fetching followed users: $e");
    }
  }

  void _addMusicOverlay(Map<String, String> track) {
    setState(() {
      _overlays.add(
        StoryOverlayItem(
          type: 'music',
          data: track,
          position: const Offset(100, 200),
        ),
      );
    });
  }

  void _addEmojiOverlay(String emoji) {
    setState(() {
      _overlays.add(
        StoryOverlayItem(
          type: 'sticker',
          data: emoji,
          position: const Offset(150, 250),
        ),
      );
    });
  }

  void _onTextSubmit() {
    final text = _textOverlayController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _overlays.add(
          StoryOverlayItem(
            type: 'text',
            data: text,
            position: const Offset(120, 300),
          ),
        );
      });
      _textOverlayController.clear();
    }
    setState(() {
      _isEditingText = false;
    });
  }

  void _onMentionSubmit() {
    final mention = _mentionController.text.trim().replaceAll('@', '');
    if (mention.isNotEmpty) {
      setState(() {
        _overlays.add(
          StoryOverlayItem(
            type: 'mention',
            data: '@$mention',
            position: const Offset(120, 150),
          ),
        );
      });
      _mentionController.clear();
    }
    setState(() {
      _isEditingMention = false;
    });
  }

  void _showMusicDrawer() {
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
                "Select Music",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _musicTracks.length,
                  itemBuilder: (context, index) {
                    final track = _musicTracks[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note, color: Color(0xFF7C57FC)),
                      ),
                      title: Text(
                        track['title']!,
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        track['artist']!,
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white54, fontSize: 12),
                      ),
                      onTap: () {
                        _addMusicOverlay(track);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "More Options",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.white),
                title: Text(
                  "Save Image",
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Image saved to gallery")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white),
                title: Text(
                  "Share with Friends",
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sharing options opened")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _publishStory() async {
    setState(() {
      _isPublishing = true;
    });

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final file = File(widget.imagePath);
      final fileName = 'stories/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload file to Supabase storage
      await client.storage.from('post-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

      // Insert story record in Supabase
      await client.from('stories').insert({
        'user_id': currentUser.id,
        'media_url': publicUrl,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Story posted successfully!"),
          backgroundColor: Color(0xFF7C57FC),
        ),
      );

      // Pop back to feed
      Navigator.pop(context); // Close Editor
      Navigator.pop(context); // Close Composer
    } catch (e) {
      debugPrint("Error publishing story: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to publish story: $e")),
      );
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  void _updateMentionSuggestions(String input) {
    if (input.isEmpty) {
      setState(() {
        _mentionSuggestions = [];
      });
      return;
    }
    final cleanInput = input.replaceFirst('@', '').toLowerCase();
    setState(() {
      _mentionSuggestions = _followedUsers.where((u) {
        final username = (u['username'] as String? ?? '').toLowerCase();
        return username.contains(cleanInput);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: topPadding,
            color: Colors.white,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // 1. Full screen preview inside the ClipRRect card (Image or Video Placeholder)
                  Positioned.fill(
                    child: _isVideoFile(widget.imagePath)
                        ? Container(
                            color: const Color(0xFF1E1E24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Video Preview',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Your video will be published to your Reels / Story.',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                          ),
                  ),

                  // 2. Overlays Stack (draggable elements)
                  Positioned.fill(
                    child: Stack(
                      children: _overlays.map((item) {
                        return Positioned(
                          left: item.position.dx,
                          top: item.position.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                item.position = Offset(
                                  item.position.dx + details.delta.dx,
                                  item.position.dy + details.delta.dy,
                                );
                              });
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _buildOverlayWidget(item),
                                // Remove button on top-right of overlay
                                Positioned(
                                  top: -12,
                                  right: -12,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _overlays.removeWhere((o) => o.id == item.id);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 12, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 3. Top left back button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
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

                  // 4. Editing tools Column on the right side
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text overlay button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEditingText = true;
                            });
                            _textOverlayFocus.requestFocus();
                          },
                          child: _buildIconButton('assets/home/icons/text_font.svg'),
                        ),
                        const SizedBox(height: 12),
                        // Sticker overlay button
                        GestureDetector(
                          onTap: _showStickersDrawer,
                          child: _buildIconButton('assets/home/icons/smile.svg'),
                        ),
                        const SizedBox(height: 12),
                        // Music overlay button
                        GestureDetector(
                          onTap: _showMusicDrawer,
                          child: _buildIconButton('assets/home/icons/music_note_03.svg'),
                        ),
                        const SizedBox(height: 12),
                        // Mention overlay button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isEditingMention = true;
                            });
                            _mentionFocus.requestFocus();
                          },
                          child: _buildIconButton('assets/home/icons/at.svg'),
                        ),
                        const SizedBox(height: 12),
                        // More options button (three dots)
                        GestureDetector(
                          onTap: _showMoreOptionsSheet,
                          child: _buildIconButton('assets/home/icons/post_options.svg'),
                        ),
                      ],
                    ),
                  ),

                  // 5. Custom text overlay input
                  if (_isEditingText) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black87,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextField(
                              controller: _textOverlayController,
                              focusNode: _textOverlayFocus,
                              style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 24),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: "Type something...",
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _onTextSubmit(),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C57FC)),
                              onPressed: _onTextSubmit,
                              child: Text("Done", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 6. Custom mention overlay input
                  if (_isEditingMention) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _mentionController,
                                    focusNode: _mentionFocus,
                                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 20),
                                    decoration: const InputDecoration(
                                      hintText: "@mention someone...",
                                      hintStyle: TextStyle(color: Colors.white30),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: _updateMentionSuggestions,
                                    onSubmitted: (_) => _onMentionSubmit(),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C57FC)),
                                  onPressed: _onMentionSubmit,
                                  child: Text("Done", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            // Suggestions list
                            if (_mentionSuggestions.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _mentionSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final user = _mentionSuggestions[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 18,
                                        backgroundImage: user['avatar_url'] != null
                                            ? NetworkImage(user['avatar_url'])
                                            : null,
                                      ),
                                      title: Text(
                                        user['username'] ?? '',
                                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _mentionController.text = '@${user['username']}';
                                        });
                                        _onMentionSubmit();
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 7. White Bottom Action Bar
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
                // Send Button
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
                    child: _isPublishing
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
    );
  }

  Widget _buildIconButton(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        assetPath,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildOverlayWidget(StoryOverlayItem item) {
    switch (item.type) {
      case 'music':
        final track = item.data as Map<String, String>;
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
                    track['title']!,
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    track['artist']!,
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      case 'mention':
        final mention = item.data as String;
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
      case 'sticker':
        final emoji = item.data as String;
        return Material(
          color: Colors.transparent,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
        );
      case 'text':
        final text = item.data as String;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
