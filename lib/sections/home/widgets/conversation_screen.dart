import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helpers/chat_svgs.dart';
import '../models/conversation_state.dart';
import '../view_models/conversation_view_model.dart';
import 'chat_message_bubble.dart';
import 'chat_recording_overlay.dart';
import '../profile_screen.dart';
import 'custom_loading_indicator.dart';

class ConversationScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(conversationViewModelProvider(widget.threadId).notifier).init(widget.currentUserId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
      await ref.read(conversationViewModelProvider(widget.threadId).notifier).sendMessage(text);
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

      final file = File(image.path);
      await ref.read(conversationViewModelProvider(widget.threadId).notifier).sendImage(file);
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending image: $e");
      final errorString = e.toString().toLowerCase();
      if (errorString.contains("camera_access_denied") || errorString.contains("camera")) {
        _showPermissionSettingsDialog("Camera");
      } else if (errorString.contains("photo_access_denied") ||
          errorString.contains("photo") ||
          errorString.contains("gallery") ||
          errorString.contains("permission")) {
        _showPermissionSettingsDialog("Photos");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to send image: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _showPermissionSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$permissionName Access Required',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF323232),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Please allow access to your $permissionName in settings to send media.',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF737373),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Container(
                    width: 286,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                        bottom: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Open Settings',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C57FC),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF373737),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        return const AssetImage('assets/home/images/profile_image_1.png');
      case 'jordanmarco':
        return const AssetImage('assets/home/images/profile_image2.png');
      case 'avaj':
        return const AssetImage('assets/home/images/avatar.png');
      case 'karennne':
        return const AssetImage('assets/home/images/element.png');
      default:
        return const AssetImage('assets/home/images/element.png');
    }
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

    final state = ref.watch(conversationViewModelProvider(widget.threadId));
    final isRecording = state.isRecording;
    final messages = state.messages;
    final isLoadingMessages = state.isLoadingMessages;

    ref.listen<ConversationState>(
      conversationViewModelProvider(widget.threadId),
      (previous, next) {
        if (previous?.messages.length != next.messages.length) {
          _scrollToBottom();
        }
      },
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          userPosts: const [],
                          userId: widget.otherProfile['id'] as String,
                        ),
                      ),
                    );
                  },
                  child: Row(
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
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: isLoadingMessages
                    ? const CustomLoadingIndicator()
                    : ListView.builder(
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

                          final messageBubble = ChatMessageBubble(
                            threadId: widget.threadId,
                            msg: msg,
                            currentUserId: widget.currentUserId,
                            otherProfile: widget.otherProfile,
                          );

                          if (showDateHeader) {
                            return Column(
                              children: [
                                _buildDateHeader(createdAt),
                                messageBubble,
                              ],
                            );
                          }

                          return messageBubble;
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEF), width: 1),
                  ),
                ),
                child: isRecording
                    ? ChatRecordingOverlay(threadId: widget.threadId)
                    : Row(
                        children: [
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
                                ChatSvgs.cameraIcon,
                                colorFilter: const ColorFilter.mode(Color(0xFF737373), BlendMode.srcIn),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  GestureDetector(
                                    onLongPressStart: (_) => ref
                                        .read(conversationViewModelProvider(widget.threadId).notifier)
                                        .startRecording(),
                                    onLongPressEnd: (_) => ref
                                        .read(conversationViewModelProvider(widget.threadId).notifier)
                                        .stopAndSendRecording(),
                                    onLongPressCancel: () => ref
                                        .read(conversationViewModelProvider(widget.threadId).notifier)
                                        .cancelRecording(),
                                    onTap: () {
                                      final vmState = ref.read(conversationViewModelProvider(widget.threadId));
                                      if (!vmState.isRecording) {
                                        ref
                                            .read(conversationViewModelProvider(widget.threadId).notifier)
                                            .startRecording();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: SvgPicture.string(
                                        ChatSvgs.micIcon,
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
                                ChatSvgs.sendIcon,
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
      ),
    );
  }
}
