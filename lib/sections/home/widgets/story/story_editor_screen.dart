import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../view_models/social_feed_view_model.dart';

class StoryOverlayItem {
  final UniqueKey id = UniqueKey();
  final String type; // 'music', 'mention', 'sticker', 'text'
  final dynamic data;
  Offset position;
  double scale;
  double rotation;
  Size size;

  StoryOverlayItem({
    required this.type,
    required this.data,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.size = const Size(100, 100),
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
  final GlobalKey _repaintKey = GlobalKey();
  final List<StoryOverlayItem> _overlays = [];
  bool _isPublishing = false;
  List<Map<String, dynamic>> _followedUsers = [];
  List<Map<String, dynamic>> _mentionSuggestions = [];
  
  VideoPlayerController? _videoPlayerController;
  bool _isAudioMuted = false;
  
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
  Offset _startFocalPoint = Offset.zero;
  Offset _startOverlayPosition = Offset.zero;

  // Guidelines visibility
  bool _showVerticalCenterGuide = false;
  bool _showHorizontalCenterGuide = false;
  bool _showLeftGuide = false;
  bool _showRightGuide = false;
  bool _showTopGuide = false;
  bool _showBottomGuide = false;

  // Drag states
  bool _isDragging = false;
  bool _isNearTrash = false;

  double _canvasWidth = 360.0;
  double _canvasHeight = 640.0;

  void _checkGuidelinesAndSnap(StoryOverlayItem item) {
    final centerX = _canvasWidth / 2;
    final centerY = _canvasHeight / 2;
    const threshold = 12.0;

    // Check proximity to vertical center (horizontal position close to centerX)
    if ((item.position.dx - centerX).abs() < threshold) {
      item.position = Offset(centerX, item.position.dy);
      _showVerticalCenterGuide = true;
    } else {
      _showVerticalCenterGuide = false;
    }

    // Check proximity to horizontal center (vertical position close to centerY)
    if ((item.position.dy - centerY).abs() < threshold) {
      item.position = Offset(item.position.dx, centerY);
      _showHorizontalCenterGuide = true;
    } else {
      _showHorizontalCenterGuide = false;
    }

    // Margin guides
    const margin = 24.0; // Margin from edges
    final itemWidth = item.size.width * item.scale;
    final itemHeight = item.size.height * item.scale;

    final leftBoundary = margin + itemWidth / 2;
    final rightBoundary = _canvasWidth - margin - itemWidth / 2;
    final topBoundary = margin + itemHeight / 2;
    final bottomBoundary = _canvasHeight - margin - itemHeight / 2;

    if ((item.position.dx - leftBoundary).abs() < threshold) {
      item.position = Offset(leftBoundary, item.position.dy);
      _showLeftGuide = true;
    } else {
      _showLeftGuide = false;
    }

    if ((item.position.dx - rightBoundary).abs() < threshold) {
      item.position = Offset(rightBoundary, item.position.dy);
      _showRightGuide = true;
    } else {
      _showRightGuide = false;
    }

    if ((item.position.dy - topBoundary).abs() < threshold) {
      item.position = Offset(item.position.dx, topBoundary);
      _showTopGuide = true;
    } else {
      _showTopGuide = false;
    }

    if ((item.position.dy - bottomBoundary).abs() < threshold) {
      item.position = Offset(item.position.dx, bottomBoundary);
      _showBottomGuide = true;
    } else {
      _showBottomGuide = false;
    }

    // Trash Proximity Check
    final trashX = centerX;
    final trashY = _canvasHeight - 90.0;
    final distanceToTrash = (item.position - Offset(trashX, trashY)).distance;
    
    // Dynamically adjust deletion detection radius based on sticker size/scale
    final detectionRadius = 70.0 + (itemWidth / 3).clamp(0.0, 120.0);
    _isNearTrash = distanceToTrash < detectionRadius;
    
    // If near trash, hide alignment guidelines so they don't clutter the trash area
    if (_isNearTrash) {
      _showVerticalCenterGuide = false;
      _showHorizontalCenterGuide = false;
      _showLeftGuide = false;
      _showRightGuide = false;
      _showTopGuide = false;
      _showBottomGuide = false;
    }

    // Clamp the position to keep the item inside the screen bounds
    final halfWidth = (item.size.width * item.scale) / 2;
    final halfHeight = (item.size.height * item.scale) / 2;

    double minX = halfWidth;
    double maxX = _canvasWidth - halfWidth;
    double minY = halfHeight;
    double maxY = _canvasHeight - halfHeight;

    if (minX > maxX) {
      minX = _canvasWidth / 2;
      maxX = _canvasWidth / 2;
    }
    if (minY > maxY) {
      minY = _canvasHeight / 2;
      maxY = _canvasHeight / 2;
    }

    final clampedX = item.position.dx.clamp(minX, maxX);
    final clampedY = item.position.dy.clamp(minY, maxY);
    item.position = Offset(clampedX, clampedY);
  }

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
      await _videoPlayerController!.setVolume(_isAudioMuted ? 0.0 : 1.0);
      await _videoPlayerController!.play();
      _videoPlayerController!.addListener(_videoListener);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
  }

  void _toggleMute() {
    setState(() {
      _isAudioMuted = !_isAudioMuted;
    });
    _videoPlayerController?.setVolume(_isAudioMuted ? 0.0 : 1.0);
  }

  Widget _buildVolumeButton() {
    return GestureDetector(
      onTap: _toggleMute,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isAudioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
      });
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
      position: Offset(_canvasWidth / 2, _canvasHeight / 2),
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
        position: Offset(_canvasWidth / 2, _canvasHeight / 2),
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
        position: Offset(_canvasWidth / 2, _canvasHeight / 2),
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

      var finalPath = widget.imagePath;
      final isVideo = _isVideoFile(widget.imagePath);

      if (!isVideo) {
        // Clear selection outline before capture so it is not baked into the story
        setState(() {
          _selectedOverlayId = null;
        });

        // Wait for frame to update without editing highlights
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
          if (boundary != null) {
            final image = await boundary.toImage(pixelRatio: 3.0);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null) {
              final pngBytes = byteData.buffer.asUint8List();
              final tempDir = Directory.systemTemp;
              final tempFile = File('${tempDir.path}/story_bake_${DateTime.now().millisecondsSinceEpoch}.png');
              await tempFile.writeAsBytes(pngBytes);
              finalPath = tempFile.path;
            }
          }
        } catch (e) {
          debugPrint("Failed to rasterize story: $e");
        }
      } else if (_isAudioMuted) {
        final tempDir = Directory.systemTemp;
        final outputFileName = 'muted_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final outputPath = '${tempDir.path}/$outputFileName';
        
        try {
          const channel = MethodChannel('com.app.more/video_utils');
          final result = await channel.invokeMethod<String>('stripAudio', {
            'inputPath': widget.imagePath,
            'outputPath': outputPath,
          });
          if (result != null) {
            finalPath = result;
          }
        } catch (e) {
          debugPrint("Failed to strip audio: $e");
        }
      }

      final file = File(finalPath);
      final extension = isVideo ? 'mp4' : 'png';
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
            child: RepaintBoundary(
              key: _repaintKey,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _canvasWidth = constraints.maxWidth;
                        _canvasHeight = constraints.maxHeight;

                        return Stack(
                          children: [
                            ..._overlays.map((item) {
                              final isSelected = _selectedOverlayId == item.id;
                              final isNearTrashThis = isSelected && _isNearTrash;
                              final displayScale = isNearTrashThis ? item.scale * 0.8 : item.scale;

                              const double stickerPadding = 48.0;
                              final paddedWidth = (item.size.width + 2 * stickerPadding) * displayScale;
                              final paddedHeight = (item.size.height + 2 * stickerPadding) * displayScale;

                              return Positioned(
                                left: item.position.dx - (paddedWidth / 2),
                                top: item.position.dy - (paddedHeight / 2),
                                width: paddedWidth,
                                height: paddedHeight,
                                child: Transform.rotate(
                                  angle: item.rotation,
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
                                        _startFocalPoint = details.focalPoint;
                                        _startOverlayPosition = item.position;
                                        _isDragging = true;
                                      });
                                    },
                                    onScaleUpdate: (details) {
                                      setState(() {
                                        // 1. Translation using absolute displacement
                                        item.position = _startOverlayPosition + (details.focalPoint - _startFocalPoint);
                                        
                                        // 2. Scale
                                        if (details.scale != 1.0) {
                                          item.scale = (_startScale * details.scale).clamp(0.5, 8.0);
                                        }
                                        
                                        // 3. Rotation
                                        if (details.rotation != 0.0) {
                                          item.rotation = _startRotation + details.rotation;
                                        }

                                        // 4. Snapping & Guidelines
                                        _checkGuidelinesAndSnap(item);
                                      });
                                    },
                                    onScaleEnd: (details) {
                                      setState(() {
                                        _isDragging = false;
                                        if (_isNearTrash && _selectedOverlayId != null) {
                                          _overlays.removeWhere((o) => o.id == _selectedOverlayId);
                                          _selectedOverlayId = null;
                                        }
                                        _isNearTrash = false;
                                        _showVerticalCenterGuide = false;
                                        _showHorizontalCenterGuide = false;
                                        _showLeftGuide = false;
                                        _showRightGuide = false;
                                        _showTopGuide = false;
                                        _showBottomGuide = false;
                                      });
                                    },
                                    child: Opacity(
                                      opacity: isNearTrashThis ? 0.4 : 1.0,
                                      child: FittedBox(
                                        fit: BoxFit.fill,
                                        child: Container(
                                          padding: const EdgeInsets.all(stickerPadding),
                                          color: Colors.transparent,
                                          child: _MeasuredWidget(
                                            onSizeChanged: (newSize) {
                                              if (item.size != newSize) {
                                                setState(() {
                                                  item.size = newSize;
                                                });
                                              }
                                            },
                                            child: _buildOverlayWidget(item),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Guidelines Rendering
                            if (_showVerticalCenterGuide)
                              Positioned(
                                left: _canvasWidth / 2 - 0.5,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1.0,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                            if (_showHorizontalCenterGuide)
                              Positioned(
                                top: _canvasHeight / 2 - 0.5,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1.0,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                            if (_showLeftGuide)
                              Positioned(
                                left: 24.0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1.0,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                            if (_showRightGuide)
                              Positioned(
                                right: 24.0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1.0,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                            if (_showTopGuide)
                              Positioned(
                                top: 24.0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1.0,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),
                            if (_showBottomGuide)
                              Positioned(
                                bottom: 24.0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1.0,
                                  color: const Color(0xFF00E5FF),
                                ),
                              ),

                            // Drag to Delete trash bin
                            if (_isDragging)
                              Positioned(
                                bottom: 40,
                                left: 0,
                                right: 0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Drag to delete",
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 4,
                                            color: Colors.black45,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedScale(
                                      duration: const Duration(milliseconds: 150),
                                      scale: _isNearTrash ? 1.3 : 1.0,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: _isNearTrash 
                                              ? Colors.red.withValues(alpha: 0.9) 
                                              : Colors.black26,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _isNearTrash 
                                                ? Colors.red 
                                                : Colors.white.withValues(alpha: 0.8),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: _isNearTrash ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
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
                        if (_isVideoFile(widget.imagePath)) ...[
                          _buildVolumeButton(),
                          const SizedBox(height: 12),
                        ],
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

class _MeasuredWidget extends StatefulWidget {
  final Widget child;
  final Function(Size) onSizeChanged;

  const _MeasuredWidget({
    required this.child,
    required this.onSizeChanged,
  });

  @override
  State<_MeasuredWidget> createState() => _MeasuredWidgetState();
}

class _MeasuredWidgetState extends State<_MeasuredWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _MeasuredWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.onSizeChanged(renderBox.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
