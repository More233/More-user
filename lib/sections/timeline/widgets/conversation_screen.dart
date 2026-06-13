import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
  
  // Audio playback simulation states
  String? _activeAudioId;
  double _playbackProgress = 0.0;
  double _playbackSpeed = 1.0;
  Timer? _playbackTimer;

  // Voice recording simulation states
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _playbackTimer?.cancel();
    _recordingTimer?.cancel();
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
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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

  // Recording Simulation handlers
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    if (!_isRecording) return;

    final duration = _recordingSeconds;
    setState(() {
      _isRecording = false;
    });

    if (duration < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hold to record voice message")),
      );
      return;
    }

    try {
      final client = Supabase.instance.client;
      await client.from('chat_messages').insert({
        'thread_id': widget.threadId,
        'sender_id': widget.currentUserId,
        'message_type': 'audio',
        'content': 'mock_audio_url',
        'media_duration': duration,
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending audio message: $e");
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

  // Waveform player timer controller
  void _toggleAudioPlay(String msgId, int durationSeconds) {
    if (_activeAudioId == msgId) {
      // Pause
      _playbackTimer?.cancel();
      setState(() {
        _activeAudioId = null;
      });
    } else {
      // Start/Resume
      _playbackTimer?.cancel();
      setState(() {
        _activeAudioId = msgId;
        if (_playbackProgress >= 1.0) {
          _playbackProgress = 0.0;
        }
      });

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
    }
  }

  void _togglePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });

    // If actively playing, restart timer with new speed
    if (_activeAudioId != null) {
      _playbackTimer?.cancel();
      // Find the message in DB to get correct duration is skipped for simplicity as we keep the timer running
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _playbackProgress += (0.1 * _playbackSpeed) / 14; // Assumed max 14s duration fallback
          if (_playbackProgress >= 1.0) {
            _playbackProgress = 1.0;
            _playbackTimer?.cancel();
            _activeAudioId = null;
          }
        });
      });
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
        return const AssetImage('assets/Timeline/Story/image/Profile Image.png');
      case 'jordanmarco':
        return const AssetImage('assets/Timeline/Story/image/Profile Image2.png');
      case 'avaj':
        return const AssetImage('assets/Timeline/Story/image/Avatar.png');
      case 'karennne':
        return const AssetImage('assets/Timeline/Personal Timeline  Default State/image/Element.png');
      default:
        return const AssetImage('assets/Timeline/Personal Timeline  Default State/image/Element.png');
    }
  }

  // Audio waveform UI builder (Figma vertical bars matching exact proportions)
  Widget _buildAudioWaveform(String msgId, int duration, bool isSent) {
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
          onTap: () => _toggleAudioPlay(msgId, duration),
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
                      : _buildAudioWaveform(msg['id'], duration, isSent),
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
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFB8B8), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recording: ${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'Release to Send',
            style: GoogleFonts.ibmPlexSansArabic(
              color: Colors.red.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
