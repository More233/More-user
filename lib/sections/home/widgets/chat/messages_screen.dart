import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'conversation_screen.dart';
import '../../helpers/story_tracker.dart';
import '../../models/user_story_group.dart';
import '../../view_models/messages_view_model.dart';
import '../common/custom_loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final Set<String> followedUsernames;
  final Function(String, bool) onFollowChanged;
  final bool showBackButton;
  final VoidCallback? onAvatarTapped;

  const MessagesScreen({
    super.key,
    required this.followedUsernames,
    required this.onFollowChanged,
    this.showBackButton = true,
    this.onAvatarTapped,
  });

  @override
  ConsumerState<MessagesScreen> createState() => MessagesScreenState();
}

class MessagesScreenState extends ConsumerState<MessagesScreen> {
  void enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
  }

  void showNewChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NewChatBottomSheet(
          profilesList: _profilesList,
          currentUserId: _currentUserId,
          getAvatarProvider: _getAvatarProvider,
          onUserSelected: (profile) {
            Navigator.pop(context);
            _openConversation(profile);
          },
        );
      },
    );
  }
  bool _isLoadingStories = true;
  List<Map<String, dynamic>> _profilesList = [];
  List<Map<String, dynamic>> _searchThreadsResult = [];
  bool _isSearching = false;
  final List<UserStoryGroup> _storyGroups = [];
  bool _isSearchMode = false;
  String _currentUserId = '';
  final TextEditingController _searchController = TextEditingController();

  String? get _currentUserAvatarUrl {
    final curProfile = _profilesList.firstWhere(
      (p) => p['id'] == _currentUserId,
      orElse: () => {},
    );
    return curProfile['avatar_url'] as String?;
  }

  @override
  void initState() {
    super.initState();
    StoryTracker().init().then((_) {
      if (mounted) {
        setState(() {});
      }
    });

    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.id;
      // Load profiles locally for search
      client.from('profiles').select().then((res) {
        if (mounted) {
          setState(() {
            _profilesList = List<Map<String, dynamic>>.from(res);
          });
        }
      });
      // Initialize Riverpod ViewModel
      Future.microtask(() {
        ref.read(messagesViewModelProvider.notifier).init(_currentUserId);
      });
      _fetchStories();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStories() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      // 1. Fetch followed user IDs
      final followsResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final userIds = List<Map<String, dynamic>>.from(followsResponse)
          .map((f) => f['following_id'] as String)
          .toList();

      // Include current user's ID
      userIds.add(currentUser.id);

      // 2. Fetch active stories from Supabase where expires_at > now()
      final storiesResponse = await client
          .from('stories')
          .select('*, user:profiles(id, username, first_name, last_name, avatar_url)')
          .inFilter('user_id', userIds)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: true);

      // 3. Group by user
      final Map<String, UserStoryGroup> grouped = {};
      for (var row in storiesResponse) {
        final user = row['user'];
        if (user == null) continue;

        final uId = user['id'] as String;
        final username = user['username'] as String? ?? 'unknown';
        final avatarUrl = user['avatar_url'] as String?;
        final mediaUrl = row['media_url'] as String;
        final createdAtStr = row['created_at'] as String;
        final createdAt = DateTime.parse(createdAtStr);
        final storyId = row['id'] as String;
        final storyOverlays = row['overlays'] as List<dynamic>? ?? [];

        if (grouped.containsKey(uId)) {
          grouped[uId]!.mediaUrls.add(mediaUrl);
          grouped[uId]!.createdTimes.add(createdAt);
          grouped[uId]!.storyIds.add(storyId);
          grouped[uId]!.overlays.add(storyOverlays);
        } else {
          grouped[uId] = UserStoryGroup(
            userId: uId,
            username: username,
            avatarUrl: avatarUrl,
            mediaUrls: [mediaUrl],
            createdTimes: [createdAt],
            storyIds: [storyId],
            overlays: [storyOverlays],
          );
        }
      }

      if (mounted) {
        setState(() {
          _storyGroups.clear();
          _storyGroups.addAll(grouped.values);
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stories: $e");
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
        });
      }
    }
  }

  Future<void> _onSearchChanged(String query) async {
    final queryTrimmed = query.trim();
    if (queryTrimmed.isEmpty) {
      setState(() {
        _searchThreadsResult = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final queryLower = queryTrimmed.toLowerCase();
    final messagesState = ref.read(messagesViewModelProvider);
    final threadsList = messagesState.threads;

    // 1. Filter local threads by other user's name/username
    final localMatches = threadsList.where((t) {
      final otherProfile = t['otherProfile'] as Map<String, dynamic>;
      final firstName = (otherProfile['first_name'] ?? '').toString().toLowerCase();
      final lastName = (otherProfile['last_name'] ?? '').toString().toLowerCase();
      final username = (otherProfile['username'] ?? '').toString().toLowerCase();
      
      return firstName.contains(queryLower) ||
          lastName.contains(queryLower) ||
          username.contains(queryLower);
    }).toList();

    // 2. Query Supabase for messages containing the query in the user's threads
    final threadIds = threadsList.map((t) => t['thread']['id'] as String).toList();
    final Set<String> msgMatchingThreadIds = {};

    if (threadIds.isNotEmpty) {
      try {
        final client = Supabase.instance.client;
        final res = await client
            .from('chat_messages')
            .select('thread_id')
            .inFilter('thread_id', threadIds)
            .ilike('content', '%$queryTrimmed%');

        final data = List<Map<String, dynamic>>.from(res as List);
        for (var row in data) {
          final tId = row['thread_id'] as String?;
          if (tId != null) {
            msgMatchingThreadIds.add(tId);
          }
        }
      } catch (e) {
        debugPrint("Error searching chat messages: $e");
      }
    }

    // 3. Combine local matches (by name) and remote matches (by message content)
    final Set<String> addedThreadIds = {};
    final List<Map<String, dynamic>> combinedResults = [];

    for (var t in localMatches) {
      final tId = t['thread']['id'] as String;
      if (addedThreadIds.add(tId)) {
        combinedResults.add(t);
      }
    }

    for (var t in threadsList) {
      final tId = t['thread']['id'] as String;
      if (msgMatchingThreadIds.contains(tId)) {
        if (addedThreadIds.add(tId)) {
          combinedResults.add(t);
        }
      }
    }

    if (mounted) {
      setState(() {
        _searchThreadsResult = combinedResults;
        _isSearching = false;
      });
    }
  }

  Future<void> _openConversation(Map<String, dynamic> otherProfile) async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final otherUserId = otherProfile['id'];
      String? threadId;

      final threads = ref.read(messagesViewModelProvider).threads;
      final existingThreadIndex = threads.indexWhere(
        (t) {
          final thread = t['thread'] as Map<String, dynamic>;
          return (thread['user1_id'] == currentUserId && thread['user2_id'] == otherUserId) ||
                 (thread['user1_id'] == otherUserId && thread['user2_id'] == currentUserId);
        },
      );

      if (existingThreadIndex != -1) {
        threadId = threads[existingThreadIndex]['thread']['id'];
      } else {
        // Create a new thread
        final insertResponse = await client.from('chat_threads').insert({
          'user1_id': currentUserId,
          'user2_id': otherUserId,
        }).select().single();
        threadId = insertResponse['id'];
        await ref.read(messagesViewModelProvider.notifier).loadData(); // Reload threads list
      }

      if (!mounted) return;
      
      // Navigate to ConversationScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            threadId: threadId!,
            otherProfile: otherProfile,
            currentUserId: currentUserId,
          ),
        ),
      );
      
      // Reload on return
      ref.read(messagesViewModelProvider.notifier).loadData();
    } catch (e) {
      debugPrint("Error opening conversation: $e");
    }
  }

  ImageProvider _getAvatarProvider(String username, String? dbUrl) {
    if (dbUrl != null && dbUrl.isNotEmpty) {
      if (dbUrl.startsWith('http')) {
        return CachedNetworkImageProvider(dbUrl);
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

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) {
        return 'now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d';
      } else {
        final weeks = (diff.inDays / 7).floor();
        return '${weeks}w';
      }
    } catch (e) {
      return '';
    }
  }



  Widget _buildThreadTile(Map<String, dynamic> populatedThread) {
    final otherProfile = populatedThread['otherProfile'] as Map<String, dynamic>;
    final lastMsg = populatedThread['lastMessage'] as Map<String, dynamic>?;
    final otherUsername = otherProfile['username'] ?? '';
    final otherName = '${otherProfile['first_name'] ?? ''} ${otherProfile['last_name'] ?? ''}'.trim();
    final avatarUrl = otherProfile['avatar_url'] as String?;

    String lastMsgText = 'No messages yet';
    if (lastMsg != null) {
      if (lastMsg['message_type'] == 'text') {
        lastMsgText = lastMsg['content'] ?? '';
      } else if (lastMsg['message_type'] == 'image') {
        lastMsgText = '📷 Sent a photo';
      } else if (lastMsg['message_type'] == 'audio') {
        lastMsgText = '🎵 Sent a voice message';
      } else if (lastMsg['message_type'] == 'story_share') {
        final isSentByMe = lastMsg['sender_id'] == _currentUserId;
        lastMsgText = isSentByMe ? 'Mentioned them in your story' : 'Mentioned you in their story';
      }
    }

    final timeText = lastMsg != null ? _formatTime(lastMsg['created_at']) : '';

    final unreadCount = populatedThread['unreadCount'] as int? ?? 0;

    return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: _getAvatarProvider(otherUsername, avatarUrl),
        ),
        title: Text(
          otherName,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D111C),
          ),
        ),
        subtitle: Text(
          lastMsgText,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            color: const Color(0xFF545763),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeText,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: const Color(0xFF82858C),
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        onTap: () => _openConversation(otherProfile),
      );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5D5D5D).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2,
                size: 40,
                color: Color(0xFF7C57FC),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with one of your friends to see messages here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: const Color(0xFF545763),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesViewModelProvider);
    final threadsList = messagesState.threads;
    final isLoading = messagesState.isLoading || _isLoadingStories;

    if (_isSearchMode) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _isSearchMode = false;
                      _searchController.clear();
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEFF2),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.search, color: Color(0xFF82858C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF82858C),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C57FC),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
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
        ),
        body: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            Expanded(
              child: _isSearching
                  ? const CustomLoadingIndicator()
                  : (_searchController.text.trim().isEmpty
                      ? (threadsList.isEmpty
                          ? Center(
                              child: Text(
                                'No conversations yet',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: const Color(0xFF82858C),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: threadsList.length,
                              itemBuilder: (context, index) {
                                return _buildThreadTile(threadsList[index]);
                              },
                            ))
                      : (_searchThreadsResult.isEmpty
                          ? Center(
                              child: Text(
                                'No results found',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: const Color(0xFF82858C),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _searchThreadsResult.length,
                              itemBuilder: (context, index) {
                                return _buildThreadTile(_searchThreadsResult[index]);
                              },
                            ))),
            ),
          ],
        ),
      );
    }

    final avatarUrl = _currentUserAvatarUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : (widget.onAvatarTapped != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.onAvatarTapped,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? (avatarUrl.startsWith('http')
                                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                                    : Image.asset(avatarUrl, fit: BoxFit.cover))
                                : Image.asset(
                                    'assets/home/images/avatar_placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null),
        title: Text(
          'Chat',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E4E6)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 12,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const CustomLoadingIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar trigger
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchMode = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFF2),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.search, color: Color(0xFF82858C), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Search',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 15,
                              color: const Color(0xFF82858C),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE8E8E8)),

                // Messages thread list / empty state
                Expanded(
                  child: threadsList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: threadsList.length,
                          itemBuilder: (context, index) {
                            return _buildThreadTile(threadsList[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _NewChatBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> profilesList;
  final String currentUserId;
  final ImageProvider Function(String username, String? dbUrl) getAvatarProvider;
  final Function(Map<String, dynamic>) onUserSelected;

  const _NewChatBottomSheet({
    required this.profilesList,
    required this.currentUserId,
    required this.getAvatarProvider,
    required this.onUserSelected,
  });

  @override
  State<_NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<_NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProfiles = [];

  @override
  void initState() {
    super.initState();
    // Exclude current user from list
    _filteredProfiles = widget.profilesList
        .where((p) => p['id'] != widget.currentUserId)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final queryLower = query.trim().toLowerCase();
    if (queryLower.isEmpty) {
      setState(() {
        _filteredProfiles = widget.profilesList
            .where((p) => p['id'] != widget.currentUserId)
            .toList();
      });
      return;
    }

    final results = widget.profilesList.where((p) {
      if (p['id'] == widget.currentUserId) return false;

      final firstName = (p['first_name'] ?? '').toString().toLowerCase();
      final lastName = (p['last_name'] ?? '').toString().toLowerCase();
      final username = (p['username'] ?? '').toString().toLowerCase();

      return firstName.contains(queryLower) ||
          lastName.contains(queryLower) ||
          username.contains(queryLower);
    }).toList();

    setState(() {
      _filteredProfiles = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Text(
                  'New chat',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEFF2),
                borderRadius: BorderRadius.circular(21),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.search, color: Color(0xFF82858C), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C57FC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [

                // Users list
                ..._filteredProfiles.map((profile) {
                  final username = profile['username'] ?? '';
                  final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
                  final avatarUrl = profile['avatar_url'] as String?;
                  final isVerified = profile['is_verified'] as bool? ?? false;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: widget.getAvatarProvider(username, avatarUrl),
                    ),
                    title: Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF1D9BF0),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '@$username',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: const Color(0xFF536471),
                      ),
                    ),
                    onTap: () => widget.onUserSelected(profile),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
