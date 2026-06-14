import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ConversationScreen extends StatefulWidget {
  final String threadId;
  final Map<String, dynamic> otherProfile;
  final String currentUserId;

  const ConversationScreen({
    super.key,
    required this.threadId,
    required this.otherProfile,
    required this.currentUserId,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Real Audio playback & recording states
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<Duration>? _playerDurationSubscription;
  StreamSubscription<Duration>? _playerPositionSubscription;

  String? _activeAudioId;
  int _activeAudioDuration = 14;
  double _playbackProgress = 0.0;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  bool _hasMicPermission = false;

  @override
  void initState() {
    super.initState();
    _checkMicPermission();
    // Listen to audio player events to update progress dynamically
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _playbackProgress = 1.0;
        _activeAudioId = null;
      });
    });
    _playerPositionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (_activeAudioId != null && _activeAudioDuration > 0) {
        setState(() {
          _playbackProgress = pos.inMilliseconds / (_activeAudioDuration * 1000);
          if (_playbackProgress > 1.0) _playbackProgress = 1.0;
        });
      }
    });
  }

  Future<void> _checkMicPermission() async {
    try {
      _hasMicPermission = await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint("Error checking mic permission: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _playbackTimer?.cancel();
    _recordingTimer?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerDurationSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final client = Supabase.instance.client;
      await client.from('chat_messages').insert({
        'thread_id': widget.threadId,
        'sender_id': widget.currentUserId,
        'message_type': 'text',
        'content': text,
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _pickAndSendImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1C1C1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Send a Photo',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF7C57FC)),
                title: const Text('Take Photo (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _processImagePick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF7C57FC)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _processImagePick(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading image...")),
      );

      final client = Supabase.instance.client;
      final file = File(image.path);
      final fileName = 'chat_images/${widget.threadId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await client.storage.from('post-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

      await client.from('chat_messages').insert({
        'thread_id': widget.threadId,
        'sender_id': widget.currentUserId,
        'message_type': 'image',
        'content': publicUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error sending image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send image: $e")),
        );
      }
    }
  }

  // Recording handlers using record package
  Future<void> _startRecording() async {
    try {
      if (_hasMicPermission || await _audioRecorder.hasPermission()) {
        _hasMicPermission = true;

        if (!mounted) return;
        // Unfocus text fields to close keyboard
        FocusScope.of(context).unfocus();

        final tempDir = await getTemporaryDirectory();
        final path = p.join(tempDir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voice message discarded"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error cancelling recording: $e");
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    if (!_isRecording) return;

    final duration = _recordingSeconds;
    setState(() {
      _isRecording = false;
    });

    try {
      final path = await _audioRecorder.stop();
      if (duration < 1 || path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Voice message too short")),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploading voice message...")),
        );
      }

      final client = Supabase.instance.client;
      final file = File(path);
      final fileName = 'chat_audio/${widget.threadId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await client.storage.from('post-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final publicUrl = client.storage.from('post-images').getPublicUrl(fileName);

      await client.from('chat_messages').insert({
        'thread_id': widget.threadId,
        'sender_id': widget.currentUserId,
        'message_type': 'audio',
        'content': publicUrl,
        'media_duration': duration,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error sending audio message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload voice message: $e")),
        );
      }
    }
  }

  // Simulation Menu options (✨ replies)
  Future<void> _simulateIncomingMessage(String type) async {
    try {
      final client = Supabase.instance.client;
      final otherId = widget.otherProfile['id'];

      String content = '';
      int? duration;

      if (type == 'text') {
        final List<String> textOptions = [
          "I'll be there in 2 mins ⏰",
          "just ideas for next time",
          "Coffee sounds amazing today! ☕️",
          "Haha that's terrifying 😂",
          "Great design! Let's catch up later.",
        ];
        textOptions.shuffle();
        content = textOptions.first;
      } else if (type == 'image') {
        content = "https://images.unsplash.com/photo-1541167760496-1628856ab772?q=80&w=600&auto=format&fit=crop";
      } else if (type == 'audio') {
        content = "mock_audio_url";
        duration = 14; // Matches Figma audio length
      }

      await client.from('chat_messages').insert({
        'thread_id': widget.threadId,
        'sender_id': otherId,
        'message_type': type,
        'content': content,
        'media_duration': duration,
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error simulating reply: $e");
    }
  }

  void _showSimulationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1C1C1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Simulate Reply from ${widget.otherProfile['first_name']}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Color(0xFF7C57FC)),
                title: const Text('Simulate Text Message'),
                onTap: () {
                  Navigator.pop(context);
                  _simulateIncomingMessage('text');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Color(0xFF7C57FC)),
                title: const Text('Simulate Image Message'),
                onTap: () {
                  Navigator.pop(context);
                  _simulateIncomingMessage('image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none_outlined, color: Color(0xFF7C57FC)),
                title: const Text('Simulate Audio Message (14s)'),
                onTap: () {
                  Navigator.pop(context);
                  _simulateIncomingMessage('audio');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Waveform player timer controller using AudioPlayer
  Future<void> _toggleAudioPlay(String msgId, String url, int durationSeconds) async {
    if (_activeAudioId == msgId) {
      // Pause
      await _audioPlayer.pause();
      setState(() {
        _activeAudioId = null;
      });
    } else {
      // Stop current playing
      await _audioPlayer.stop();

      setState(() {
        if (_activeAudioId != msgId) {
          _playbackProgress = 0.0;
        }
        _activeAudioId = msgId;
        _activeAudioDuration = durationSeconds;
        if (_playbackProgress >= 1.0) {
          _playbackProgress = 0.0;
        }
      });

      try {
        if (url == 'mock_audio_url') {
          // Simulation fallback for mock replies
          _playbackTimer?.cancel();
          _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
            setState(() {
              _playbackProgress += (0.1 * _playbackSpeed) / durationSeconds;
              if (_playbackProgress >= 1.0) {
                _playbackProgress = 1.0;
                _playbackTimer?.cancel();
                _activeAudioId = null;
              }
            });
          });
        } else {
          // Play real audio file from Supabase Storage
          await _audioPlayer.setPlaybackRate(_playbackSpeed);
          await _audioPlayer.play(UrlSource(url));
        }
      } catch (e) {
        debugPrint("Error playing audio: $e");
      }
    }
  }

  Future<void> _togglePlaybackSpeed() async {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });

    if (_activeAudioId != null) {
      try {
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
      } catch (e) {
        debugPrint("Error setting playback speed: $e");
      }
    }
  }

  ImageProvider _getAvatarProvider(String username, String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return NetworkImage(dbUrl);
      } else {
        return AssetImage(dbUrl);
      }
    }
    switch (username.toLowerCase()) {
      case 'mayat':
        return const AssetImage('assets/Timeline/images/profile_image_1.png');
      case 'jordanmarco':
        return const AssetImage('assets/Timeline/images/profile_image2.png');
      case 'avaj':
        return const AssetImage('assets/Timeline/images/avatar.png');
      case 'karennne':
        return const AssetImage('assets/Timeline/images/element.png');
      default:
        return const AssetImage('assets/Timeline/images/element.png');
    }
  }

  // Audio waveform UI builder (Figma vertical bars matching exact proportions)
  Widget _buildAudioWaveform(String msgId, String url, int duration, bool isSent) {
    final isCurrentPlaying = _activeAudioId == msgId;
    final List<double> barHeights = [11.8, 19.7, 25.0, 25.0, 9.2, 14.5, 22.3, 9.2, 9.2, 3.9, 3.9, 27.6, 19.7, 25.0, 19.7, 9.2, 14.0];
    final activeColor = isSent ? Colors.white : const Color(0xFF101010);
    final inactiveColor = isSent ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF878787);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: () => _toggleAudioPlay(msgId, url, duration),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSent ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCurrentPlaying ? Icons.pause : Icons.play_arrow,
              color: isSent ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Waveform stack
        SizedBox(
          width: 110,
          height: 30,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Waveform bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(barHeights.length, (idx) {
                  final progressLimit = idx / barHeights.length;
                  final isActive = isCurrentPlaying && _playbackProgress >= progressLimit;

                  return Container(
                    width: 3.5,
                    height: barHeights[idx],
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              // Playback scrub line
              if (isCurrentPlaying)
                Positioned(
                  left: _playbackProgress * 110,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: isSent ? Colors.white : const Color(0xFF7C57FC),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Duration text & speed pill
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isCurrentPlaying
                  ? '${(duration * _playbackProgress).toInt()}s'
                  : '${duration}s',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 11,
                color: isSent ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isCurrentPlaying) ...[
              const SizedBox(height: 2),
              GestureDetector(
                onTap: _togglePlaybackSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSent ? Colors.white : const Color(0xFF7C57FC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_playbackSpeed.toStringAsFixed(1).replaceAll('.0', '')}x',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 9,
                      color: isSent ? const Color(0xFF7C57FC) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isSent = msg['sender_id'] == widget.currentUserId;
    final type = msg['message_type'] ?? 'text';
    final content = msg['content'] ?? '';
    final duration = msg['media_duration'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: _getAvatarProvider(
                widget.otherProfile['username'] ?? '',
                widget.otherProfile['avatar_url'] as String?,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: type == 'text'
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSent
                    ? const Color(0xFF7C57FC) // Sent purple bubble
                    : const Color(0xFFF1F1F1), // Received grey bubble
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: type == 'text'
                  ? Text(
                      content,
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: isSent ? Colors.white : const Color(0xFF303030),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    )
                  : type == 'image'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Image.network(
                              content,
                              width: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 150,
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        )
                      : _buildAudioWaveform(msg['id'], content, duration, isSent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherName = '${widget.otherProfile['first_name'] ?? ''} ${widget.otherProfile['last_name'] ?? ''}'.trim();
    final otherUsername = widget.otherProfile['username'] ?? '';
    final otherAvatar = widget.otherProfile['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _getAvatarProvider(otherUsername, otherAvatar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    otherName,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '@$otherUsername',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: const Color(0xFF545763),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ✨ Simulation menu trigger icon
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C57FC), size: 24),
            onPressed: _showSimulationBottomSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages stream list view
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('chat_messages')
                    .stream(primaryKey: ['id'])
                    .eq('thread_id', widget.threadId)
                    .order('created_at', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  
                  // Trigger scroll to bottom on new message
                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(messages[index]);
                    },
                  );
                },
              ),
            ),

            // Footer input bar or active recording UI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEF), width: 1),
                ),
              ),
              child: _isRecording
                  ? _buildRecordingOverlay()
                  : Row(
                      children: [
                        // Left camera action button inside rounded circle
                        GestureDetector(
                          onTap: _pickAndSendImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6E6E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF737373), size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Message input field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      hintText: 'Send Message',
                                      hintStyle: GoogleFonts.ibmPlexSansArabic(
                                        color: const Color(0xFF737373),
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (val) => _sendMessage(),
                                  ),
                                ),
                                // Right voice mic recorder inside message field
                                GestureDetector(
                                  onLongPressStart: (_) => _startRecording(),
                                  onLongPressEnd: (_) => _stopAndSendRecording(),
                                  onLongPressCancel: () => _cancelRecording(),
                                  onTap: () {
                                    if (!_isRecording) {
                                      _startRecording();
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.mic, color: Color(0xFF7C57FC), size: 24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Far right send message trigger button
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C57FC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildRecordingOverlay() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FB), // Ultra soft lavender/purple tinted background
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5DFFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C57FC).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Cancel/Delete Button (Left)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 24),
            tooltip: 'Discard',
            onPressed: _cancelRecording,
          ),
          
          const SizedBox(width: 8),
          
          // Recording indicator and timer (Center)
          Expanded(
            child: Row(
              children: [
                // Pulsing dot
                const _RecordingDotPulse(),
                const SizedBox(width: 10),
                Text(
                  'Recording: ${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF1E1E24),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Send Button (Right)
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF7C57FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _RecordingDotPulse extends StatefulWidget {
  const _RecordingDotPulse();

  @override
  State<_RecordingDotPulse> createState() => _RecordingDotPulseState();
}

class _RecordingDotPulseState extends State<_RecordingDotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
