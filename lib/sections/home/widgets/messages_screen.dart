import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'follow_friends_bottom_sheet.dart';
import 'conversation_screen.dart';
import 'story_viewer.dart';
import 'story_composer_screen.dart';
import '../helpers/story_tracker.dart';
import '../models/user_story_group.dart';
import '../view_models/messages_view_model.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final Set<String> followedUsernames;
  final Function(String, bool) onFollowChanged;

  const MessagesScreen({
    super.key,
    required this.followedUsernames,
    required this.onFollowChanged,
  });

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  late Set<String> _localFollowed;
  bool _isLoadingStories = true;
  List<Map<String, dynamic>> _profilesList = [];
  List<Map<String, dynamic>> _searchResults = [];
  final List<UserStoryGroup> _storyGroups = [];
  bool _isSearching = false;
  String _currentUserId = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localFollowed = Set.from(widget.followedUsernames);
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

        if (grouped.containsKey(uId)) {
          grouped[uId]!.mediaUrls.add(mediaUrl);
          grouped[uId]!.createdTimes.add(createdAt);
          grouped[uId]!.storyIds.add(storyId);
        } else {
          grouped[uId] = UserStoryGroup(
            userId: uId,
            username: username,
            avatarUrl: avatarUrl,
            mediaUrls: [mediaUrl],
            createdTimes: [createdAt],
            storyIds: [storyId],
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

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final results = _profilesList.where((p) {
      // Don't show current user in search results
      if (p['id'] == _currentUserId) return false;

      final firstName = (p['first_name'] ?? '').toString().toLowerCase();
      final lastName = (p['last_name'] ?? '').toString().toLowerCase();
      final username = (p['username'] ?? '').toString().toLowerCase();

      return firstName.contains(queryLower) ||
          lastName.contains(queryLower) ||
          username.contains(queryLower);
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
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
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }

  void _openAddFriends() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FollowFriendsBottomSheet(
          followedUsernames: _localFollowed,
          onFollowChanged: (username, isFollowed) {
            setState(() {
              if (isFollowed) {
                _localFollowed.add(username);
              } else {
                _localFollowed.remove(username);
              }
            });
            widget.onFollowChanged(username, isFollowed);
            ref.read(messagesViewModelProvider.notifier).loadData();
          },
        );
      },
    );
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
      }
    }

    final timeText = lastMsg != null ? _formatTime(lastMsg['created_at']) : '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEF0), width: 1),
        ),
      ),
      child: ListTile(
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
        trailing: Text(
          timeText,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12,
            color: const Color(0xFF82858C),
          ),
        ),
        onTap: () => _openConversation(otherProfile),
      ),
    );
  }

  Widget _buildSearchTile(Map<String, dynamic> profile) {
    final otherUsername = profile['username'] ?? '';
    final otherName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
    final avatarUrl = profile['avatar_url'] as String?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        radius: 20,
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
        '@$otherUsername',
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 14,
          color: const Color(0xFF82858C),
        ),
      ),
      onTap: () => _openConversation(profile),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SvgPicture.asset(
                'assets/home/icons/chat_bubble_icon.svg',
                width: 64,
                height: 64,
                colorFilter: const ColorFilter.mode(Color(0xFF82858C), BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No chats yet',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to start chatting.',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                color: const Color(0xFF545763),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesRow() {
    final currentUserGroup = _storyGroups.firstWhere(
      (g) => g.userId == _currentUserId,
      orElse: () => UserStoryGroup(userId: '', username: '', avatarUrl: '', mediaUrls: [], createdTimes: [], storyIds: []),
    );
    final hasOwnStory = currentUserGroup.userId.isNotEmpty;

    final currentUserProfile = _profilesList.firstWhere(
      (p) => p['id'] == _currentUserId,
      orElse: () => <String, dynamic>{},
    );
    final String? currentUserAvatarUrl = currentUserProfile['avatar_url'] as String?;
    final String currentUserUsername = currentUserProfile['username'] ?? '';

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Your Story Bubble
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (hasOwnStory) {
                          final index = _storyGroups.indexOf(currentUserGroup);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoryViewer(
                                storyGroups: _storyGroups,
                                initialGroupIndex: index,
                              ),
                            ),
                          ).then((_) => _fetchStories());
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoryComposerScreen(),
                            ),
                          ).then((_) => _fetchStories());
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasOwnStory
                                ? (StoryTracker().isGroupViewed(currentUserGroup.mediaUrls)
                                    ? const Color(0xFFE9E9E9)
                                    : const Color(0xFF7C57FC))
                                : const Color(0xFFE9E9E9),
                            width: hasOwnStory ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _getAvatarProvider(currentUserUsername, currentUserAvatarUrl),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoryComposerScreen(),
                            ),
                          ).then((_) => _fetchStories());
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Story',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF5A5D67),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Followed user stories
          ..._storyGroups.where((g) => g.userId != _currentUserId).map((group) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  final index = _storyGroups.indexOf(group);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryViewer(
                        storyGroups: _storyGroups,
                        initialGroupIndex: index,
                      ),
                    ),
                  ).then((_) => _fetchStories());
                },
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: StoryTracker().isGroupViewed(group.mediaUrls)
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF7C57FC), Color(0xFFFF57B9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        border: StoryTracker().isGroupViewed(group.mediaUrls)
                            ? Border.all(color: const Color(0xFFE9E9E9), width: 2)
                            : null,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _getAvatarProvider(group.username, group.avatarUrl),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.username,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: const Color(0xFF5A5D67),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesViewModelProvider);
    final threadsList = messagesState.threads;
    final isLoading = messagesState.isLoading || _isLoadingStories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _buildActionButtonChild(
                child: SvgPicture.asset(
                  'assets/home/icons/add_friend_icon.svg',
                  width: 24,
                  height: 24,
                ),
                onTap: _openAddFriends,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF82858C), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by name or username',
                              hintStyle: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF82858C),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isSearching) ...[
                  // Search results header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Search Results',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Search results list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildSearchTile(_searchResults[index]);
                      },
                    ),
                  ),
                ] else ...[
                  // Stories row
                  _buildStoriesRow(),
                  const SizedBox(height: 12),

                  // Messages list header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Messages',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

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
              ],
            ),
    );
  }

  Widget _buildActionButtonChild({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE9E9E9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
