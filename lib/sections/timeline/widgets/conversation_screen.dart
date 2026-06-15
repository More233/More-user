import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_svg/flutter_svg.dart';

const String _cameraIconSvg = '''<svg viewBox="0 0 21.5 21.5" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M10.7186 2.77886e-07H10.7814H10.7814C11.3855 -8.53559e-06 11.8856 -1.58288e-05 12.2985 0.0351516C12.7312 0.0720082 13.1223 0.150687 13.4994 0.337418C14.1713 0.670086 14.5961 1.19877 14.8943 1.729C15.1255 2.14004 15.305 2.60182 15.4571 2.99318C15.493 3.08553 15.5274 3.17396 15.5605 3.25689L15.7079 3.62534C15.7804 3.8066 15.8167 3.89722 15.8916 3.94869C15.9666 4.00016 16.0653 4.00145 16.2626 4.00403C17.1838 4.01608 17.8801 4.06819 18.4914 4.32479C19.4392 4.72261 20.2085 5.45632 20.6571 6.38547C20.8573 6.80002 20.9592 7.24536 21.0267 7.76254C21.0925 8.26676 21.1308 8.88894 21.1788 9.66739L21.3389 12.2623C21.4587 14.2057 21.5535 15.7415 21.465 16.946C21.3742 18.1829 21.0842 19.1918 20.3362 19.9986C19.5868 20.8071 18.6069 21.1654 17.3895 21.3351C16.2067 21.5 14.6866 21.5 12.767 21.5H8.73273C6.81311 21.5 5.29301 21.5 4.11028 21.3351C2.89282 21.1654 1.91298 20.8071 1.16353 19.9986C0.415552 19.1918 0.125514 18.1829 0.0346929 16.946C-0.0537454 15.7415 0.0409821 14.2057 0.160852 12.2623L0.320901 9.66721C0.3689 8.88885 0.407265 8.26672 0.47303 7.76254C0.540491 7.24536 0.642414 6.80002 0.842585 6.38547C1.29124 5.45632 2.06053 4.72261 3.00833 4.32479C3.61974 4.06817 4.31607 4.01607 5.23741 4.00403C5.43475 4.00145 5.53341 4.00016 5.60838 3.94869C5.68334 3.89722 5.71959 3.8066 5.79209 3.62534L5.93947 3.25689C5.97264 3.17397 6.00701 3.08554 6.0429 2.9932L6.04291 2.99317C6.19503 2.60181 6.37451 2.14003 6.60567 1.729C6.90388 1.19877 7.32866 0.670086 8.00059 0.337418C8.37775 0.150687 8.76879 0.0720082 9.20153 0.0351516C9.61444 -1.58288e-05 10.1145 -8.53558e-06 10.7186 2.77886e-07H10.7186ZM9.75195 4.75C9.75195 4.19772 10.1977 3.75 10.7475 3.75C11.2934 3.75 11.752 4.19791 11.752 4.75C11.752 5.30209 11.2934 5.75 10.7475 5.75C10.1977 5.75 9.75195 5.30229 9.75195 4.75ZM10.752 8.75C8.54281 8.75 6.75195 10.5409 6.75195 12.75C6.75195 14.9591 8.54281 16.75 10.752 16.75C12.9611 16.75 14.752 14.9591 14.752 12.75C14.752 10.5409 12.9611 8.75 10.752 8.75Z" fill="currentColor"/>
</svg>''';

const String _micIconSvg = '''<svg viewBox="0 0 17.5 21.5" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path opacity="0.4" d="M13.75 5.75V9.75C13.75 12.5114 11.5114 14.75 8.75 14.75C5.98858 14.75 3.75 12.5114 3.75 9.75V5.75C3.75 2.98858 5.98858 0.75 8.75 0.75C11.5114 0.75 13.75 2.98858 13.75 5.75Z" fill="currentColor"/>
  <path d="M16.75 9C17.1642 9 17.5 9.33579 17.5 9.75C17.5 14.3298 13.9814 18.0883 9.5 18.4688V20H11.75C12.1642 20 12.5 20.3358 12.5 20.75C12.5 21.1642 12.1642 21.5 11.75 21.5H5.75C5.33579 21.5 5 21.1642 5 20.75C5 20.3358 5.33579 20 5.75 20H8V18.4688C3.5186 18.0883 0 14.3298 0 9.75C0 9.33579 0.335786 9 0.75 9C1.16421 9 1.5 9.33579 1.5 9.75C1.5 13.7541 4.74594 17 8.75 17C12.7541 17 16 13.7541 16 9.75C16 9.33579 16.3358 9 16.75 9ZM8.75 0C11.9256 0 14.5 2.57436 14.5 5.75V9.75C14.5 12.9256 11.9256 15.5 8.75 15.5C5.57436 15.5 3 12.9256 3 9.75V5.75C3 2.57436 5.57436 0 8.75 0ZM8.75 1.5C6.40279 1.5 4.5 3.40279 4.5 5.75V9.75C4.5 12.0972 6.40279 14 8.75 14C10.8412 14 12.5783 12.4894 12.9326 10.5H10.75C10.3358 10.5 10 10.1642 10 9.75C10 9.33579 10.3358 9 10.75 9H13V6.5H10.75C10.3358 6.5 10 6.16421 10 5.75C10 5.33579 10.3358 5 10.75 5H12.9326C12.5783 3.01061 10.8412 1.5 8.75 1.5Z" fill="currentColor"/>
</svg>''';

const String _sendIconSvg = '''<svg viewBox="0 0 20.5 20.5" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M19.8473 0.792568C19.3799 0.289178 18.647 0.100627 17.9468 0.0331413C17.2111 -0.0377692 16.33 0.0093918 15.3813 0.133817C13.4788 0.383368 11.1802 0.961019 8.97221 1.67176C6.76281 2.38295 4.60914 3.23865 2.99626 4.05847C2.19355 4.46648 1.49734 4.87932 0.991214 5.27586C0.73919 5.47331 0.509223 5.686 0.33623 5.91237C0.171234 6.12829 -0.00236335 6.43549 2.43545e-05 6.80582C0.00629184 7.7779 0.668287 8.4649 1.37327 8.92603C2.09284 9.3967 3.02998 9.75137 3.96161 10.0292C4.90324 10.31 5.89346 10.5276 6.74473 10.704C6.80052 10.7155 6.91203 10.7386 7.04867 10.7668C7.56323 10.8731 7.82051 10.9263 8.06237 10.8539C8.30422 10.7815 8.49015 10.5956 8.86202 10.2237L12.5429 6.54289C12.9334 6.15237 13.5666 6.15237 13.9571 6.54289C14.3476 6.93342 14.3476 7.56659 13.9571 7.95711L10.5245 11.3897C10.1454 11.7688 9.95589 11.9583 9.88416 12.2043C9.81243 12.4503 9.87027 12.7114 9.98595 13.2337C10.4344 15.2584 10.8238 16.9315 11.2123 18.0571C11.4392 18.7145 11.6945 19.2836 12.0178 19.7033C12.3552 20.1413 12.8142 20.4722 13.4183 20.4989C13.7944 20.5155 14.1071 20.3438 14.3215 20.1844C14.5475 20.0166 14.76 19.7914 14.9571 19.5453C15.3531 19.0505 15.7692 18.3659 16.1832 17.5747C17.0152 15.9847 17.8962 13.8528 18.6417 11.6596C19.3868 9.46729 20.0077 7.1806 20.3068 5.2801C20.456 4.3323 20.5298 3.45207 20.4888 2.71477C20.4499 2.01556 20.3009 1.28106 19.8473 0.792568Z" fill="currentColor"/>
</svg>''';

const String _playIconSvg = '''<svg viewBox="0 0 15.5 16.5" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9.69054 2.58706C11.3235 3.51475 12.6067 4.24375 13.5209 4.91154C14.4413 5.58392 15.1221 6.2867 15.3659 7.21321C15.5447 7.89269 15.5447 8.60743 15.3659 9.28691C15.1221 10.2134 14.4413 10.9162 13.5209 11.5886C12.6067 12.2564 11.3235 12.9854 9.69059 13.913L9.69058 13.913C8.11319 14.8092 6.78303 15.5649 5.77322 15.9944C4.7553 16.4274 3.82729 16.6468 2.92536 16.3912C2.26252 16.2034 1.65941 15.8469 1.17356 15.3567C0.514188 14.6914 0.24951 13.772 0.124288 12.6654C-1.76951e-05 11.567 -9.82927e-06 10.129 1.79089e-07 8.30017V8.30016V8.19997V8.19996C-9.82927e-06 6.37108 -1.76951e-05 4.93315 0.124288 3.8347C0.249511 2.72816 0.514188 1.80867 1.17356 1.14341C1.65941 0.653232 2.26252 0.296724 2.92536 0.108895C3.82729 -0.146689 4.7553 0.0727526 5.77322 0.505712C6.78303 0.93522 8.11316 1.6909 9.69054 2.58706Z" fill="currentColor"/>
</svg>''';

const String _pauseIconSvg = '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="4" width="4" height="16" rx="1" fill="currentColor"/>
  <rect x="14" y="4" width="4" height="16" rx="1" fill="currentColor"/>
</svg>''';

const String _deleteIconSvg = '''<svg viewBox="0 0 28 28" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M14.1425 1.45992C14.681 1.4605 15.1661 1.46104 15.5705 1.49722C16.2298 1.55618 16.8494 1.75737 17.3816 2.15421C17.7751 2.44771 18.0484 2.80697 18.282 3.19607C18.4984 3.55663 18.7163 4.00617 18.9634 4.51612L19.4609 5.54232L24.4987 5.54313C25.143 5.54313 25.6654 6.06547 25.6654 6.7098C25.6654 7.35414 25.143 7.87647 24.4987 7.87647H23.4808L22.8449 18.2665C22.7555 19.7285 22.6844 20.8888 22.5389 21.8155C22.3896 22.7659 22.1507 23.5574 21.6727 24.2497C21.2354 24.8831 20.6725 25.4177 20.0196 25.8193C19.306 26.2585 18.5091 26.4505 17.5606 26.5423H10.414C9.46445 26.4502 8.6667 26.2578 7.95256 25.8178C7.29927 25.4154 6.73613 24.8799 6.29902 24.2455C5.82122 23.552 5.58302 22.7594 5.43486 21.8076C5.29039 20.8796 5.22097 19.7177 5.13345 18.2535L4.51321 7.87647H3.4987C2.85437 7.87647 2.33203 7.35414 2.33203 6.7098C2.33203 6.06547 2.85437 5.54313 3.4987 5.54313L8.64379 5.54232L9.05852 4.6325C9.29951 4.10377 9.51173 3.63811 9.72492 3.26445C9.95488 2.8614 10.2271 2.48842 10.6254 2.18285C11.1641 1.76962 11.7961 1.56012 12.4702 1.49876C12.9294 1.45695 13.3919 1.45818 13.8531 1.45939L14.1425 1.45992ZM15.7487 18.0658H12.2487C11.7655 18.0658 11.3737 18.4576 11.3737 18.9408C11.3737 19.424 11.7655 19.8158 12.2487 19.8158H15.7487C16.2319 19.8158 16.6237 19.424 16.6237 18.9408C16.6237 18.4576 16.2319 18.0658 15.7487 18.0658ZM17.4987 13.4948H10.4987C10.0155 13.4948 9.6237 13.8866 9.6237 14.3698C9.6237 14.853 10.0155 15.2448 10.4987 15.2448H17.4987C17.9819 15.2448 18.3737 14.853 18.3737 14.3698C18.3737 13.8866 17.9819 13.4948 17.4987 13.4948ZM14.2634 3.79323L14.0389 3.79313C13.3963 3.79313 12.9919 3.79425 12.6818 3.82248C12.2453 3.86221 11.9732 4.03228 11.7516 4.42075C11.6064 4.6752 11.4484 5.01577 11.2081 5.54232H16.8679C16.6037 4.9975 16.4346 4.6521 16.2814 4.39688C16.057 4.02317 15.7882 3.85934 15.3626 3.82127C15.0979 3.7976 14.763 3.79381 14.2634 3.79323Z" fill="currentColor"/>
</svg>''';

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
  bool _isPaused = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  List<double> _recordingWaveforms = List.filled(17, 4.0);
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
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('thread_id', widget.threadId)
          .neq('sender_id', widget.currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
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
    _amplitudeTimer?.cancel();
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
          _isPaused = false;
          _recordingSeconds = 0;
          _recordingWaveforms = List.filled(17, 4.0);
        });

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
        _startAmplitudeTimer();
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

  void _startAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording || _isPaused) return;
      try {
        final amp = await _audioRecorder.getAmplitude();
        final db = amp.current; // usually from -160 to 0 (dB)
        
        // Normalize volume from [-60, 0] to [0.15, 1.0]
        double volumeFactor = 0.15;
        if (db > -60) {
          volumeFactor = 0.15 + (60 + db) * (0.85 / 60.0);
        }
        if (volumeFactor > 1.0) volumeFactor = 1.0;
        
        setState(() {
          for (int i = 0; i < _recordingWaveforms.length; i++) {
            // Generate a natural-looking bouncing wave using sine and random offsets
            final time = DateTime.now().millisecondsSinceEpoch / 120.0;
            final base = math.sin(time + i * 0.7).abs();
            final noise = math.cos(time * 1.8 + i).abs() * 0.3;
            double height = 4.0 + (base + noise) * 20.0 * volumeFactor;
            if (height > 24.0) height = 24.0;
            if (height < 4.0) height = 4.0;
            _recordingWaveforms[i] = height;
          }
        });
      } catch (e) {
        // Ignored
      }
    });
  }

  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _amplitudeTimer?.cancel();
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingSeconds = 0;
      });
    } catch (e) {
      debugPrint("Error cancelling recording: $e");
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    if (!_isRecording) return;

    final duration = _recordingSeconds;
    setState(() {
      _isRecording = false;
      _isPaused = false;
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

      // No upload SnackBar shown as per request

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

  Future<void> _toggleRecordingPause() async {
    if (!_isRecording) return;
    try {
      if (_isPaused) {
        await _audioRecorder.resume();
        setState(() {
          _isPaused = false;
        });
        // Resume timer
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        await _audioRecorder.pause();
        _recordingTimer?.cancel();
        setState(() {
          _isPaused = true;
        });
      }
    } catch (e) {
      debugPrint("Error toggling record pause: $e");
    }
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
  Widget _buildAudioWaveform(Map<String, dynamic> msg, bool isSent) {
    final msgId = msg['id'] as String;
    final url = msg['content'] as String;
    final duration = msg['media_duration'] as int? ?? 0;
    
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
              color: isSent ? Colors.white : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(7),
            child: isCurrentPlaying
                ? SvgPicture.string(
                    _pauseIconSvg,
                    colorFilter: ColorFilter.mode(
                      isSent ? const Color(0xFF7C57FC) : Colors.black,
                      BlendMode.srcIn,
                    ),
                  )
                : SvgPicture.string(
                    _playIconSvg,
                    colorFilter: ColorFilter.mode(
                      isSent ? const Color(0xFF7C57FC) : Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),

        // Waveform stack (widened from 110 to 160)
        SizedBox(
          width: 160,
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
                  left: _playbackProgress * 160,
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

        // Duration text & speed pill & checkmark
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
            const SizedBox(height: 2),
            Opacity(
              opacity: isSent ? 1.0 : 0.0,
              child: Icon(
                msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                size: 13,
                color: isSent ? (msg['is_read'] == true ? Colors.white : Colors.white.withValues(alpha: 0.6)) : Colors.transparent,
              ),
            ),
            const SizedBox(height: 2),
            Opacity(
              opacity: isCurrentPlaying ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !isCurrentPlaying,
                child: GestureDetector(
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteMessageSheet(Map<String, dynamic> msg) {
    final isMyMessage = msg['sender_id'] == widget.currentUserId;

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
                'Delete Message',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: SvgPicture.string(
                  _deleteIconSvg,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
                ),
                title: Text(
                  'Delete for me',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF303030),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final client = Supabase.instance.client;
                    final List<dynamic> currentDeleted = msg['deleted_by'] as List<dynamic>? ?? [];
                    if (!currentDeleted.contains(widget.currentUserId)) {
                      final updatedDeleted = List<String>.from(currentDeleted)..add(widget.currentUserId);
                      await client
                          .from('chat_messages')
                          .update({'deleted_by': updatedDeleted})
                          .eq('id', msg['id']);
                    }
                  } catch (e) {
                    debugPrint("Error deleting message for me: $e");
                  }
                },
              ),
              if (isMyMessage)
                ListTile(
                  leading: SvgPicture.string(
                    _deleteIconSvg,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
                  ),
                  title: Text(
                    'Delete for everyone',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF303030),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final client = Supabase.instance.client;
                      await client
                          .from('chat_messages')
                          .delete()
                          .eq('id', msg['id']);
                    } catch (e) {
                      debugPrint("Error deleting message for everyone: $e");
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isSent = msg['sender_id'] == widget.currentUserId;
    final type = msg['message_type'] ?? 'text';
    final content = msg['content'] ?? '';

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
            child: GestureDetector(
              onLongPress: () => _showDeleteMessageSheet(msg),
              child: Container(
                padding: type == 'text'
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    : type == 'image'
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              content,
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: isSent ? Colors.white : const Color(0xFF303030),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (isSent) ...[
                            const SizedBox(width: 6),
                            Icon(
                              msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 14,
                              color: msg['is_read'] == true ? Colors.white : Colors.white.withValues(alpha: 0.6),
                            ),
                          ],
                        ],
                      )
                    : type == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
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
                                if (isSent)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        msg['is_read'] == true ? Icons.done_all_rounded : Icons.done_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : _buildAudioWaveform(msg, isSent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGroupDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Widget _buildDateHeader(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          _getGroupDateLabel(date),
          style: GoogleFonts.ibmPlexSansArabic(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
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
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 8),
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

                  final rawMessages = snapshot.data!;
                  final messages = rawMessages.where((msg) {
                    final List<dynamic>? deletedBy = msg['deleted_by'] as List<dynamic>?;
                    if (deletedBy == null) return true;
                    return !deletedBy.contains(widget.currentUserId);
                  }).toList();
                  
                  _markMessagesAsRead();
                  
                  // Trigger scroll to bottom on new message
                  _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final DateTime createdAt = DateTime.parse(msg['created_at'] as String).toLocal();
                      
                      bool showDateHeader = false;
                      if (index == 0) {
                        showDateHeader = true;
                      } else {
                        final prevMsg = messages[index - 1];
                        final DateTime prevCreatedAt = DateTime.parse(prevMsg['created_at'] as String).toLocal();
                        if (createdAt.year != prevCreatedAt.year ||
                            createdAt.month != prevCreatedAt.month ||
                            createdAt.day != prevCreatedAt.day) {
                          showDateHeader = true;
                        }
                      }

                      if (showDateHeader) {
                        return Column(
                          children: [
                            _buildDateHeader(createdAt),
                            _buildMessageBubble(msg),
                          ],
                        );
                      }

                      return _buildMessageBubble(msg);
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
                              color: Color(0xFFEFEFEF),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(9),
                            child: SvgPicture.string(
                              _cameraIconSvg,
                              colorFilter: const ColorFilter.mode(Color(0xFF737373), BlendMode.srcIn),
                            ),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SvgPicture.string(
                                      _micIconSvg,
                                      width: 24,
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(Color(0xFF7C57FC), BlendMode.srcIn),
                                    ),
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
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.string(
                              _sendIconSvg,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Cancel/Delete Button (Left)
          IconButton(
            icon: SvgPicture.string(
              _deleteIconSvg,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
            ),
            tooltip: 'Discard',
            onPressed: _cancelRecording,
          ),
          
          const SizedBox(width: 8),
          
          // Recording duration & waveform visualizer (Center)
          Expanded(
            child: Row(
              children: [
                Text(
                  '${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF737373),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                // Custom Waveform indicator (Figma theme purple)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_recordingWaveforms.length, (idx) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 2.5,
                        height: _isPaused ? 4 : _recordingWaveforms[idx],
                        decoration: BoxDecoration(
                          color: _isPaused ? const Color(0xFFC1C1C1) : const Color(0xFF7C57FC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          
          // Pause/Resume Button (Center-Right)
          GestureDetector(
            onTap: _toggleRecordingPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              ),
              padding: const EdgeInsets.all(8),
              child: SvgPicture.string(
                _isPaused ? _playIconSvg : _pauseIconSvg,
                colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Send Button (Far Right)
          GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF7C57FC),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: SvgPicture.string(
                _sendIconSvg,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
