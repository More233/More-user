import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../view_models/social_feed_view_model.dart';

class StoryOverlayItem {
  final UniqueKey id = UniqueKey();
  final String type; // 'music', 'mention', 'sticker', 'text'
  final dynamic data;
  Offset position;
  double scale;
  double rotation;

  StoryOverlayItem({
    required this.type,
    required this.data,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

class StoryEditorScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool isReels;
  const StoryEditorScreen({super.key, required this.imagePath, this.isReels = false});

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  final List<StoryOverlayItem> _overlays = [];
  bool _isPublishing = false;
  List<Map<String, dynamic>> _followedUsers = [];
  List<Map<String, dynamic>> _mentionSuggestions = [];
  
  VideoPlayerController? _videoPlayerController;
  
  // Active text tool controller
  final TextEditingController _textOverlayController = TextEditingController();
  final FocusNode _textOverlayFocus = FocusNode();
  bool _isEditingText = false;
  
  // Active mention controller
  final TextEditingController _mentionController = TextEditingController();
  final FocusNode _mentionFocus = FocusNode();
  bool _isEditingMention = false;

  final List<String> _stickerEmojis = ['❤️', '😍', '🫣', '🔥', '👍', '🍻', '👏', '😂', '🎉', '🌟', '🍿', '💯'];

  UniqueKey? _selectedOverlayId;
  double _startScale = 1.0;
  double _startRotation = 0.0;

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.m4v');
  }

  @override
  void initState() {
    super.initState();
    _fetchFollowedUsers();
    if (_isVideoFile(widget.imagePath)) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.imagePath));
    try {
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      _videoPlayerController!.addListener(_videoListener);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _textOverlayController.dispose();
    _textOverlayFocus.dispose();
    _mentionController.dispose();
    _mentionFocus.dispose();
    super.dispose();
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

  void _addEmojiOverlay(String emoji) {
    final newItem = StoryOverlayItem(
      type: 'sticker',
      data: emoji,
      position: const Offset(150, 250),
    );
    setState(() {
      _overlays.add(newItem);
      _selectedOverlayId = newItem.id;
    });
  }

  void _onTextSubmit() {
    final text = _textOverlayController.text.trim();
    if (text.isNotEmpty) {
      final newItem = StoryOverlayItem(
        type: 'text',
        data: text,
        position: const Offset(120, 300),
      );
      setState(() {
        _overlays.add(newItem);
        _selectedOverlayId = newItem.id;
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
      final newItem = StoryOverlayItem(
        type: 'mention',
        data: '@$mention',
        position: const Offset(120, 150),
      );
      setState(() {
        _overlays.add(newItem);
        _selectedOverlayId = newItem.id;
      });
      _mentionController.clear();
    }
    setState(() {
      _isEditingMention = false;
    });
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
      final isVideo = _isVideoFile(widget.imagePath);
      final extension = isVideo ? 'mp4' : 'jpg';
      final fileName = 'stories/${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Upload file to Supabase storage
      await client.storage.from('post-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

      // Insert record in Supabase depending on mode
      if (widget.isReels) {
        final profileResponse = await client
            .from('profiles')
            .select('username')
            .eq('id', currentUser.id)
            .maybeSingle();
        final username = profileResponse != null ? profileResponse['username'] as String? : 'User';

        String description = "Check out this Reel!";
        final textOverlays = _overlays.where((item) => item.type == 'text').toList();
        if (textOverlays.isNotEmpty) {
          description = textOverlays.map((item) => item.data as String).join(' ');
        }

        await client.from('posts').insert({
          'user_id': currentUser.id,
          'title': 'Reel by $username',
          'category_name': 'Reels',
          'location_address': 'Riyadh, Saudi Arabia',
          'description': description,
          'image_url': publicUrl,
          'is_private': false,
          'sticker_index': -1,
          'tagged_friends': [],
          'latitude': 24.7136,
          'longitude': 46.6753,
        });
      } else {
        final storyResponse = await client.from('stories').insert({
          'user_id': currentUser.id,
          'media_url': publicUrl,
          'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        }).select().single();

        final storyId = storyResponse['id'] as String;

        // Process mentions and generate notifications
        final mentionOverlays = _overlays.where((item) => item.type == 'mention').toList();
        for (final item in mentionOverlays) {
          final targetUser = (item.data as String).replaceAll('@', '').trim();
          if (targetUser.isNotEmpty) {
            try {
              final profile = await client
                  .from('profiles')
                  .select('id')
                  .eq('username', targetUser)
                  .maybeSingle();
              if (profile != null) {
                final receiverId = profile['id'] as String;
                if (receiverId != currentUser.id) {
                  await client.from('notifications').insert({
                    'sender_id': currentUser.id,
                    'receiver_id': receiverId,
                    'type': 'mention',
                    'metadata': {
                      'story_id': storyId,
                      'media_url': publicUrl,
                    },
                  });
                }
              }
            } catch (e) {
              debugPrint("Error creating mention notification for $targetUser: $e");
            }
          }
        }
      }

      if (!mounted) return;

      ref.read(socialFeedViewModelProvider.notifier).refreshFeed();

      // Pop back to feed
      Navigator.pop(context); // Close Editor
      Navigator.pop(context); // Close Composer
    } catch (e) {
      debugPrint("Error publishing story: $e");
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
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Stack(
                children: [
                  // 1. Full screen preview inside the ClipRRect card (Image or Video Player)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOverlayId = null;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _isVideoFile(widget.imagePath)
                          ? (_videoPlayerController != null && _videoPlayerController!.value.isInitialized
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoPlayerController!.value.size.width,
                                    height: _videoPlayerController!.value.size.height,
                                    child: VideoPlayer(_videoPlayerController!),
                                  ),
                                )
                              : const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ))
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),

                  // Video Progress Indicator (Story-style)
                  if (_isVideoFile(widget.imagePath) &&
                      _videoPlayerController != null &&
                      _videoPlayerController!.value.isInitialized)
                    Positioned(
                      top: topPadding + 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final duration = _videoPlayerController!.value.duration.inMilliseconds;
                            final position = _videoPlayerController!.value.position.inMilliseconds;
                            final double progress = duration > 0 ? position / duration : 0.0;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // 2. Overlays Stack (draggable elements)
                  Positioned.fill(
                    child: Stack(
                      children: _overlays.map((item) {
                        final isSelected = _selectedOverlayId == item.id;
                        return Positioned(
                          left: item.position.dx,
                          top: item.position.dy,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedOverlayId = item.id;
                              });
                            },
                            onScaleStart: (details) {
                              setState(() {
                                _selectedOverlayId = item.id;
                                _startScale = item.scale;
                                _startRotation = item.rotation;
                              });
                            },
                            onScaleUpdate: (details) {
                              setState(() {
                                // 1. Translation
                                item.position = item.position + details.focalPointDelta;
                                
                                // 2. Scale
                                if (details.scale != 1.0) {
                                  item.scale = (_startScale * details.scale).clamp(0.5, 8.0);
                                }
                                
                                // 3. Rotation
                                if (details.rotation != 0.0) {
                                  item.rotation = _startRotation + details.rotation;
                                }
                              });
                            },
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(item.scale, item.scale, 1.0)
                                ..rotateZ(item.rotation),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildOverlayWidget(item),
                                  // Remove button on top-right of overlay
                                  if (isSelected)
                                    Positioned(
                                      top: -12,
                                      right: -12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _overlays.removeWhere((o) => o.id == item.id);
                                            if (_selectedOverlayId == item.id) {
                                              _selectedOverlayId = null;
                                            }
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
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // 3. Top left back button
                  Positioned(
                    top: topPadding + 16 + 20,
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
                    top: topPadding + 16 + 20,
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
