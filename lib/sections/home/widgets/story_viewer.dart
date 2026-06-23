import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_story_group.dart';
import '../models/story_view_state.dart';
import '../view_models/story_view_model.dart';
import 'story_composer_screen.dart';

class StoryViewer extends ConsumerStatefulWidget {
  final List<UserStoryGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewer({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
  });

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  bool _simulateViews = false;

  @override
  void initState() {
    super.initState();
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
      final storyState = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      if (_focusNode.hasFocus) {
        _animationController.stop();
      } else {
        if (!storyState.isReactionTrayOpen) {
          _animationController.forward();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storyState = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      _startStory(storyState);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startStory(StoryViewState storyState) {
    _animationController.reset();
    if (!_focusNode.hasFocus && !storyState.isReactionTrayOpen) {
      _animationController.forward();
    }
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).startStory(widget.storyGroups);
  }

  void _nextStory() {
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).nextStory(
      widget.storyGroups,
      () => Navigator.pop(context),
    );
  }

  void _previousStory() {
    ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).previousStory(widget.storyGroups);
  }

  List<Map<String, dynamic>> _getMockViewers() {
    return [
      {
        'user': {
          'username': 'karennne',
          'first_name': 'Karen',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar_female.png',
        },
        'badge': 'heart',
      },
      {
        'user': {
          'username': 'Sam_TD',
          'first_name': 'Sam',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar_male.png',
        },
        'badge': null,
      },
      {
        'user': {
          'username': 'kieron_d',
          'first_name': 'Kieron',
          'last_name': '',
          'avatar_url': 'assets/home/images/avatar.png',
        },
        'badge': 'fire',
      },
      {
        'user': {
          'username': 'craig_love',
          'first_name': 'Craig',
          'last_name': 'Love',
          'avatar_url': 'assets/home/images/profile_image2.png',
        },
        'badge': null,
      },
    ];
  }

  Widget _buildAvatarWithBadge(Map<String, dynamic> viewer) {
    final user = viewer['user'];
    final avatarUrl = user != null ? user['avatar_url'] as String? : null;
    final badge = viewer['badge'] as String?;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? (avatarUrl.startsWith('http')
                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                    : Image.asset(avatarUrl, fit: BoxFit.cover))
                : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Center(
                child: badge == 'heart'
                    ? Image.asset('assets/home/images/heart.png', fit: BoxFit.contain)
                    : Image.asset('assets/home/images/fire.png', fit: BoxFit.contain),
              ),
            ),
          ),
      ],
    );
  }

  void _showViewsBottomSheet(BuildContext context, StoryViewState storyState, String currentStoryId) {
    _animationController.stop();
    final showMock = _simulateViews && storyState.viewers.isEmpty;
    final listToShow = storyState.viewers.isNotEmpty 
        ? storyState.viewers 
        : (showMock ? _getMockViewers() : <Map<String, dynamic>>[]);
        
    final displayViewsCount = storyState.viewers.isNotEmpty 
        ? storyState.viewsCount 
        : listToShow.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/home/icons/user_multiple.svg',
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(Color(0xFF1F1F1F), BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$displayViewsCount",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF1F1F1F),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDeleteStory(currentStoryId);
                    },
                    child: SvgPicture.asset(
                      'assets/home/icons/delete_03.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(Color(0xFFE53935), BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFEFEFEF), thickness: 1),
              const SizedBox(height: 10),
              // Viewers list
              if (listToShow.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      "No views yet",
                      style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey[400]),
                    ),
                  ),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _simulateViews = true;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showViewsBottomSheet(context, storyState, currentStoryId);
                      });
                    },
                    icon: const Icon(Icons.bolt, color: Color(0xFF7C57FC)),
                    label: Text(
                      "Simulate Views (Figma Demo)",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: const Color(0xFF7C57FC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listToShow.length,
                    itemBuilder: (context, index) {
                      final item = listToShow[index];
                      final viewer = item['user'];
                      if (viewer == null) return const SizedBox.shrink();
                      
                      final username = viewer['username'] as String? ?? 'unknown';
                      final fullName = '${viewer['first_name'] ?? ''} ${viewer['last_name'] ?? ''}'.trim();
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            _buildAvatarWithBadge(item),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: const Color(0xFF1F1F1F),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (fullName.isNotEmpty)
                                    Text(
                                      fullName,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, color: Color(0xFF8E8E93)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Options for @$username")),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_simulateViews && storyState.viewers.isEmpty)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _simulateViews = false;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showViewsBottomSheet(context, storyState, currentStoryId);
                        });
                      },
                      child: Text(
                        "Reset Simulation",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  Future<void> _confirmDeleteStory(String storyId) async {
    _animationController.stop();
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    children: [
                      Text(
                        "Delete this photo?",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You can restore unarchived stories for 24 hours, or 30 days for archived stories, from Recently deleted in Your activity. After that, it will be permanently deleted.",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF333333),
                          fontSize: 13,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFD1D1D6), thickness: 0.5),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      "Delete",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: const Color(0xFFD32F2F),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFD1D1D6), thickness: 0.5),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    alignment: Alignment.center,
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
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

    if (confirm == true) {
      try {
        final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
        await notifier.deleteStory(storyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Story deleted"),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Error deleting story: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete story: $e")),
          );
          _animationController.forward();
        }
      }
    } else {
      _animationController.forward();
    }
  }

  void _showMoreOptions(BuildContext context, String storyId) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1F1F1F)),
                  title: Text(
                    "Add to Story",
                    style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF1F1F1F), fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoryComposerScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    "Delete Story",
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteStory(storyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: Text(
                    "Cancel",
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  void _showHighlightBottomSheet(BuildContext context, String currentMediaUrl) {
    _animationController.stop();
    String selectedHighlight = "Highlight";
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Add to highlight",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedHighlight = "Highlight";
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedHighlight == "Highlight"
                                      ? const Color(0xFF7C57FC)
                                      : Colors.grey[300]!,
                                  width: 2.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                ),
                                child: ClipOval(
                                  child: currentMediaUrl.startsWith('http')
                                      ? Image.network(currentMediaUrl, fit: BoxFit.cover)
                                      : Image.asset(currentMediaUrl, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Highlight",
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: const Color(0xFF1F1F1F),
                                fontSize: 13,
                                fontWeight: selectedHighlight == "Highlight"
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {
                          _showCreateHighlightDialog(context, (newName) {
                            setSheetState(() {
                              selectedHighlight = newName;
                            });
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedHighlight != "Highlight"
                                      ? const Color(0xFF7C57FC)
                                      : Colors.grey[300]!,
                                  width: 2.0,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, color: Color(0xFF7C57FC), size: 28),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedHighlight != "Highlight" ? selectedHighlight : "New",
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: const Color(0xFF1F1F1F),
                                fontSize: 13,
                                fontWeight: selectedHighlight != "Highlight"
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Added to highlight \"$selectedHighlight\"!"),
                          backgroundColor: const Color(0xFF7C57FC),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C57FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Continue",
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  void _showCreateHighlightDialog(BuildContext context, Function(String) onCreate) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("New Highlight", style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: "Enter highlight name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  onCreate(name);
                }
                Navigator.pop(context);
              },
              child: Text("Create", style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF7C57FC))),
            ),
          ],
        );
      },
    );
  }

  void _showSendBottomSheet(BuildContext context) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StorySendSheetContent(
          onDismissed: () {},
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  void _showMentionBottomSheet(BuildContext context) {
    _animationController.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _StoryMentionSheetContent(
          onDismissed: () {},
        );
      },
    ).then((_) {
      _animationController.forward();
    });
  }

  Widget _buildOverlappingAvatars(List<Map<String, dynamic>> viewers) {
    final list = _simulateViews || viewers.isNotEmpty 
        ? (viewers.isNotEmpty ? viewers : _getMockViewers()) 
        : <Map<String, dynamic>>[];
        
    if (list.isEmpty) {
      return SvgPicture.asset(
        'assets/home/icons/user_multiple.svg',
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(Color(0xFF5A5D67), BlendMode.srcIn),
      );
    }
    
    final displayViewers = list.take(3).toList();
    return SizedBox(
      width: 24.0 + (displayViewers.length - 1) * 12.0,
      height: 24,
      child: Stack(
        children: List.generate(displayViewers.length, (index) {
          final viewer = displayViewers[index]['user'];
          final avatarUrl = viewer != null ? viewer['avatar_url'] as String? : null;
          
          return Positioned(
            left: index * 12.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (avatarUrl.startsWith('http')
                        ? Image.network(avatarUrl, fit: BoxFit.cover)
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOwnerBottomBar(BuildContext context, String currentStoryId, String currentMediaUrl, StoryViewState storyState) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomBarItem(
            icon: _buildOverlappingAvatars(storyState.viewers),
            label: "Activity",
            onTap: () => _showViewsBottomSheet(context, storyState, currentStoryId),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/like_icon.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFF5A5D67), BlendMode.srcIn),
            ),
            label: "Highlight",
            onTap: () => _showHighlightBottomSheet(context, currentMediaUrl),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/sent.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFF5A5D67), BlendMode.srcIn),
            ),
            label: "Send",
            onTap: () => _showSendBottomSheet(context),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.asset(
              'assets/home/icons/at.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Color(0xFF5A5D67), BlendMode.srcIn),
            ),
            label: "Mention",
            onTap: () => _showMentionBottomSheet(context),
          ),
          _buildBottomBarItem(
            icon: SvgPicture.string(
              '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M4 7H20M4 12H20M4 17H20" stroke="#5A5D67" stroke-width="2.2" stroke-linecap="round"/>
              </svg>''',
              width: 24,
              height: 24,
            ),
            label: "More",
            onTap: () {
              _showMoreOptions(context, currentStoryId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarItem({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 26,
              child: Center(
                child: icon,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                color: const Color(0xFF5A5D67),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();

    try {
      final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
      final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      await notifier.sendDM(text, widget.storyGroups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reply sent to @${widget.storyGroups[state.currentGroupIndex].username}!"),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
    if (!state.isReactionTrayOpen) {
      _animationController.forward();
    }
  }

  Future<void> _sendEmojiReaction(String emoji) async {
    final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
    notifier.setReactionTrayOpen(false);

    try {
      final state = ref.read(storyViewModelProvider(widget.initialGroupIndex));
      await notifier.sendDM(emoji, widget.storyGroups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reply sent to @${widget.storyGroups[state.currentGroupIndex].username}!"),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send message: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (!_focusNode.hasFocus) {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.storyGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final storyState = ref.watch(storyViewModelProvider(widget.initialGroupIndex));

    ref.listen<StoryViewState>(storyViewModelProvider(widget.initialGroupIndex), (previous, next) {
      if (previous?.currentGroupIndex != next.currentGroupIndex ||
          previous?.currentStoryIndex != next.currentStoryIndex) {
        _startStory(next);
      }
    });

    final currentGroup = widget.storyGroups[storyState.currentGroupIndex];
    final currentMediaUrl = currentGroup.mediaUrls[storyState.currentStoryIndex];

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    final bool isOwner = currentUser != null && currentGroup.userId == currentUser.id;
    final double bottomSpacing = isOwner
        ? (64.0 + MediaQuery.of(context).padding.bottom)
        : (78.0 + MediaQuery.of(context).padding.bottom);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            bottom: bottomSpacing + 8,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardHeight = constraints.maxHeight;
                        return GestureDetector(
                          onTapDown: (details) {
                            if (_isTouchInReactionArea(details.localPosition, cardHeight, storyState.isReactionTrayOpen)) {
                              return;
                            }
                            _animationController.stop();
                          },
                          onTapUp: (details) {
                            if (_isTouchInReactionArea(details.localPosition, cardHeight, storyState.isReactionTrayOpen)) {
                              return;
                            }
                            if (_focusNode.hasFocus) {
                              _focusNode.unfocus();
                              return;
                            }
                            if (storyState.isReactionTrayOpen) {
                              ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier).setReactionTrayOpen(false);
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
                            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                              if (isOwner) {
                                _showViewsBottomSheet(
                                  context,
                                  storyState,
                                  currentGroup.storyIds[storyState.currentStoryIndex],
                                );
                              }
                            } else if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
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
                        );
                      },
                    ),
                  ),
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
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.65, sigmaY: 2.65),
                        child: Container(
                          color: const Color(0x4D989898),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: List.generate(
                                  currentGroup.mediaUrls.length,
                                  (index) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 3,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.35),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            index < storyState.currentStoryIndex
                                                ? Container(
                                                    height: 3,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  )
                                                : index == storyState.currentStoryIndex
                                                    ? AnimatedBuilder(
                                                        animation: _animationController,
                                                        builder: (context, child) {
                                                          return FractionallySizedBox(
                                                            alignment: Alignment.centerLeft,
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
                                                    : const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[800],
                                    backgroundImage: currentGroup.avatarUrl != null &&
                                            currentGroup.avatarUrl!.isNotEmpty
                                        ? NetworkImage(currentGroup.avatarUrl!) as ImageProvider
                                        : const AssetImage('assets/home/images/avatar_placeholder.png'),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isOwner ? "Your Story" : currentGroup.username,
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
                                          if (currentGroup.createdTimes.isNotEmpty &&
                                              storyState.currentStoryIndex < currentGroup.createdTimes.length) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: const BoxDecoration(
                                                color: Colors.white54,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimeAgo(currentGroup.createdTimes[storyState.currentStoryIndex]),
                                              style: GoogleFonts.ibmPlexSansArabic(
                                                color: const Color(0xFFE1E1E1),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                shadows: [
                                                  const Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.black45,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isOwner)
            Positioned(
              left: 16,
              bottom: 78 + MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final notifier = ref.read(storyViewModelProvider(widget.initialGroupIndex).notifier);
                        final nextState = !storyState.isReactionTrayOpen;
                        notifier.setReactionTrayOpen(nextState);
                        if (nextState) {
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
                          color: const Color(0xFF7C57FC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD3D3D3), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/home/icons/smile.svg',
                            width: 48,
                            height: 48,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      width: storyState.isReactionTrayOpen ? 290 : 0,
                      height: 50,
                      margin: EdgeInsets.only(left: storyState.isReactionTrayOpen ? 12 : 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: storyState.isReactionTrayOpen ? 1.0 : 0.0,
                          child: Row(
                            children: [
                              _buildStickerItem('assets/home/images/heart.png', '❤️'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/heart_eyes.png', '😍'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/hands_face.png', '🫣'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/fire.png', '🔥'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/thumbs_up.png', '👍'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/beer.png', '🍻'),
                              const SizedBox(width: 8),
                              _buildStickerItem('assets/home/images/plus_one.png', '+1'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
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
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(
                            color: const Color(0xFFEFEFEF),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.only(left: 16, right: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: const Color(0xFF1F1F1F),
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Send Message",
                                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF737373),
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
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 58,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C57FC),
                                  borderRadius: BorderRadius.circular(19),
                                ),
                                child: storyState.isSending
                                    ? const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: SvgPicture.asset(
                                          'assets/home/icons/sent.svg',
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildOwnerBottomBar(
                context,
                currentGroup.storyIds[storyState.currentStoryIndex],
                currentMediaUrl,
                storyState,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  bool _isTouchInReactionArea(Offset localPosition, double cardHeight, bool isReactionTrayOpen) {
    final double areaLeft = 16;
    final double areaWidth = isReactionTrayOpen ? 352 : 50;
    final double areaHeight = 50;
    
    final double areaBottom = cardHeight - 16;
    final double areaTop = areaBottom - areaHeight;
    final double areaRight = areaLeft + areaWidth;

    final double x = localPosition.dx;
    final double y = localPosition.dy;

    return x >= areaLeft && x <= areaRight && y >= areaTop && y <= areaBottom;
  }

  Widget _buildStickerItem(String assetPath, String emoji) {
    final bool isSvg = assetPath.endsWith('.svg');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _sendEmojiReaction(emoji);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: isSvg
              ? SvgPicture.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                )
              : Image.asset(
                  assetPath,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}


class _StorySendSheetContent extends StatefulWidget {
  final VoidCallback onDismissed;
  const _StorySendSheetContent({required this.onDismissed});

  @override
  State<_StorySendSheetContent> createState() => _StorySendSheetContentState();
}

class _StorySendSheetContentState extends State<_StorySendSheetContent> {
  List<Map<String, String>> _allFriends = [];
  List<Map<String, String>> _filteredFriends = [];
  final Set<String> _selectedUsernames = {};
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadRealUsers();
  }

  Future<void> _loadRealUsers() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final followingResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followersResponse = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUserId);

      final List<String> userIds = [];
      for (var row in followingResponse) {
        final id = row['following_id'] as String?;
        if (id != null) userIds.add(id);
      }
      for (var row in followersResponse) {
        final id = row['follower_id'] as String?;
        if (id != null) userIds.add(id);
      }

      final Map<String, Map<String, String>> usersMap = {};

      void addProfile(dynamic row) {
        if (row == null) return;
        final id = row['id'] as String?;
        if (id == null || id == currentUserId) return;
        final username = row['username'] as String? ?? '';
        final firstName = row['first_name'] as String? ?? '';
        final lastName = row['last_name'] as String? ?? '';
        final avatarUrl = row['avatar_url'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        usersMap[id] = {
          'id': id,
          'name': name.isNotEmpty ? name : username,
          'username': username,
          'avatar': avatarUrl,
        };
      }

      if (userIds.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', userIds);

        for (var row in profilesResponse) {
          addProfile(row);
        }
      }

      if (usersMap.length < 5) {
        final fallbackResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .neq('id', currentUserId)
            .limit(20);

        for (var row in fallbackResponse) {
          addProfile(row);
        }
      }

      setState(() {
        _allFriends = usersMap.values.toList();
        _filteredFriends = _allFriends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading real users for story send sheet: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {

      if (query.trim().isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend['name']!.toLowerCase().contains(query.toLowerCase()) ||
                friend['username']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        return AssetImage(avatarUrl);
      }
    }
    return const AssetImage('assets/home/images/avatar_female.png');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + keyboardPadding + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Send",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF82858C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: const Color(0xFF1F242E),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C57FC),
                ),
              ),
            )
          else if (_filteredFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "No friends found",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final f = _filteredFriends[index];
                    final username = f['username']!;
                    final name = f['name']!;
                    final avatar = f['avatar'];
                    final isSelected = _selectedUsernames.contains(username);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarProvider(avatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF1F1F1F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "@$username",
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF7C57FC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUsernames.add(username);
                                } else {
                                  _selectedUsernames.remove(username);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedUsernames.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Story sent successfully to ${_selectedUsernames.length} friend(s)!",
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                          ),
                          backgroundColor: const Color(0xFF7C57FC),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Send",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: _selectedUsernames.isEmpty ? const Color(0xFF8E8E93) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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

class _StoryMentionSheetContent extends StatefulWidget {
  final VoidCallback onDismissed;
  const _StoryMentionSheetContent({required this.onDismissed});

  @override
  State<_StoryMentionSheetContent> createState() => _StoryMentionSheetContentState();
}

class _StoryMentionSheetContentState extends State<_StoryMentionSheetContent> {
  List<Map<String, String>> _allFriends = [];
  List<Map<String, String>> _filteredFriends = [];
  final Set<String> _selectedUsernames = {};
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadRealUsers();
  }

  Future<void> _loadRealUsers() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final followingResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followersResponse = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUserId);

      final List<String> userIds = [];
      for (var row in followingResponse) {
        final id = row['following_id'] as String?;
        if (id != null) userIds.add(id);
      }
      for (var row in followersResponse) {
        final id = row['follower_id'] as String?;
        if (id != null) userIds.add(id);
      }

      final Map<String, Map<String, String>> usersMap = {};

      void addProfile(dynamic row) {
        if (row == null) return;
        final id = row['id'] as String?;
        if (id == null || id == currentUserId) return;
        final username = row['username'] as String? ?? '';
        final firstName = row['first_name'] as String? ?? '';
        final lastName = row['last_name'] as String? ?? '';
        final avatarUrl = row['avatar_url'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        usersMap[id] = {
          'id': id,
          'name': name.isNotEmpty ? name : username,
          'username': username,
          'avatar': avatarUrl,
        };
      }

      if (userIds.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', userIds);

        for (var row in profilesResponse) {
          addProfile(row);
        }
      }

      if (usersMap.length < 5) {
        final fallbackResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .neq('id', currentUserId)
            .limit(20);

        for (var row in fallbackResponse) {
          addProfile(row);
        }
      }

      setState(() {
        _allFriends = usersMap.values.toList();
        _filteredFriends = _allFriends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading real users for story mention sheet: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {

      if (query.trim().isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend['name']!.toLowerCase().contains(query.toLowerCase()) ||
                friend['username']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  ImageProvider _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        return NetworkImage(avatarUrl);
      } else {
        return AssetImage(avatarUrl);
      }
    }
    return const AssetImage('assets/home/images/avatar_female.png');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + keyboardPadding + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Mentions",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF82858C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        color: const Color(0xFF1F242E),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C57FC),
                ),
              ),
            )
          else if (_filteredFriends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                "No friends found",
                style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final f = _filteredFriends[index];
                    final username = f['username']!;
                    final name = f['name']!;
                    final avatar = f['avatar'];
                    final isSelected = _selectedUsernames.contains(username);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatarProvider(avatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF1F1F1F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "@$username",
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: const Color(0xFF7C57FC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUsernames.add(username);
                                } else {
                                  _selectedUsernames.remove(username);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedUsernames.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      final listStr = _selectedUsernames.map((u) => "@$u").join(", ");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Mentioned $listStr in this story!",
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                          ),
                          backgroundColor: const Color(0xFF7C57FC),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C57FC),
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Add",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: _selectedUsernames.isEmpty ? const Color(0xFF8E8E93) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
