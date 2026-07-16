import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/chat/conversation_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialTabIndex;

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.initialTabIndex,
  });

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final client = Supabase.instance.client;
  String get _currentUserId => client.auth.currentUser?.id ?? '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  
  // Local copies for filtering
  List<Map<String, dynamic>> _filteredFollowers = [];
  List<Map<String, dynamic>> _filteredFollowing = [];

  // Sets to track current user's follow status
  final Set<String> _currentUserFollowingIds = {};
  final Set<String> _currentUserFollowerIds = {}; // Who follows the current user

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(_handleTabSelection);
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _onSearchChanged();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFollowers = List.from(_followers);
        _filteredFollowing = List.from(_following);
      } else {
        _filteredFollowers = _followers.where((u) {
          final uname = (u['username'] as String? ?? '').toLowerCase();
          final fname = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.toLowerCase();
          return uname.contains(query) || fname.contains(query);
        }).toList();

        _filteredFollowing = _following.where((u) {
          final uname = (u['username'] as String? ?? '').toLowerCase();
          final fname = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.toLowerCase();
          return uname.contains(query) || fname.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch Follows rows where target user is being followed (to get followers)
      final followersRows = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', widget.userId);

      final List<String> followerIds = List<Map<String, dynamic>>.from(followersRows)
          .map((r) => r['follower_id'] as String)
          .toList();

      // 2. Fetch Follows rows where target user is follower (to get following)
      final followingRows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', widget.userId);

      final List<String> followingIds = List<Map<String, dynamic>>.from(followingRows)
          .map((r) => r['following_id'] as String)
          .toList();

      // 3. Fetch Follows rows where current user is follower (to check follow status)
      final currentUserFollowingRows = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', _currentUserId);

      _currentUserFollowingIds.clear();
      for (var r in currentUserFollowingRows) {
        final id = r['following_id'] as String?;
        if (id != null) _currentUserFollowingIds.add(id);
      }

      // 4. Fetch Follows rows where current user is following_id (to check if they follow current user)
      final currentUserFollowersRows = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', _currentUserId);

      _currentUserFollowerIds.clear();
      for (var r in currentUserFollowersRows) {
        final id = r['follower_id'] as String?;
        if (id != null) _currentUserFollowerIds.add(id);
      }

      // 5. Query profiles for followers
      List<Map<String, dynamic>> followersList = [];
      if (followerIds.isNotEmpty) {
        final res = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', followerIds);
        followersList = List<Map<String, dynamic>>.from(res);
      }

      // 6. Query profiles for following
      List<Map<String, dynamic>> followingList = [];
      if (followingIds.isNotEmpty) {
        final res = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', followingIds);
        followingList = List<Map<String, dynamic>>.from(res);
      }

      if (mounted) {
        setState(() {
          _followers = followersList;
          _following = followingList;
          _filteredFollowers = List.from(_followers);
          _filteredFollowing = List.from(_following);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading followers/following data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> userProfile) async {
    final targetId = userProfile['id'] as String;
    final isFollowing = _currentUserFollowingIds.contains(targetId);

    try {
      if (isFollowing) {
        // Confirm unfollow
        final confirm = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildUnfollowConfirmationSheet(userProfile),
        );

        if (confirm != true) return;

        setState(() {
          _currentUserFollowingIds.remove(targetId);
        });

        await client
            .from('follows')
            .delete()
            .eq('follower_id', _currentUserId)
            .eq('following_id', targetId);
      } else {
        setState(() {
          _currentUserFollowingIds.add(targetId);
        });

        await client.from('follows').insert({
          'follower_id': _currentUserId,
          'following_id': targetId,
        });
      }
      _loadData();
    } catch (e) {
      debugPrint("Error toggling follow: $e");
      _loadData();
    }
  }

  Future<void> _openConversation(Map<String, dynamic> otherProfile) async {
    final otherUserId = otherProfile['id'] as String;
    
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C57FC)),
      ),
    );

    try {
      final response = await client
          .from('chat_threads')
          .select('id, user1_id, user2_id')
          .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId');
          
      final list = List<Map<String, dynamic>>.from(response as List);
      final existing = list.firstWhere(
        (t) => (t['user1_id'] == _currentUserId && t['user2_id'] == otherUserId) ||
               (t['user1_id'] == otherUserId && t['user2_id'] == _currentUserId),
        orElse: () => {},
      );

      String? threadId;
      if (existing.isNotEmpty) {
        threadId = existing['id'] as String;
      } else {
        final insertResponse = await client.from('chat_threads').insert({
          'user1_id': _currentUserId,
          'user2_id': otherUserId,
        }).select().single();
        threadId = insertResponse['id'] as String;
      }

      if (!mounted) return;
      // Pop the loading dialog
      Navigator.pop(context);

      // Navigate to ConversationScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            threadId: threadId!,
            otherProfile: otherProfile,
            currentUserId: _currentUserId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading
      debugPrint("Error opening conversation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening chat: $e")),
      );
    }
  }

  Widget _buildUnfollowConfirmationSheet(Map<String, dynamic> profile) {
    final avatarUrl = profile['avatar_url'] as String?;
    final username = profile['username'] ?? '';
    
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
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFFF5F5F5),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? (avatarUrl.startsWith('http')
                      ? NetworkImage(avatarUrl) as ImageProvider
                      : AssetImage(avatarUrl))
                  : const AssetImage('assets/home/images/avatar_placeholder.png'),
            ),
            const SizedBox(height: 16),
            Text(
              "Unfollow @$username?",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE5E5EA), height: 1),
            ListTile(
              onTap: () => Navigator.pop(context, true),
              title: Center(
                child: Text(
                  "Unfollow",
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFFFF3B30),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(color: Color(0xFFE5E5EA), height: 1),
            ListTile(
              onTap: () => Navigator.pop(context, false),
              title: Center(
                child: Text(
                  "Cancel",
                  style: GoogleFonts.ibmPlexSansArabic(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(Map<String, dynamic> user, int index) {
    final avatarUrl = user['avatar_url'] as String?;
    final hasActiveStory = index % 2 == 0; 

    final avatarImage = avatarUrl != null && avatarUrl.isNotEmpty
        ? (avatarUrl.startsWith('http')
            ? NetworkImage(avatarUrl) as ImageProvider
            : AssetImage(avatarUrl))
        : const AssetImage('assets/home/images/avatar_placeholder.png');

    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasActiveStory)
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7C57FC),
              ),
            ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: hasActiveStory ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: ClipOval(
              child: Image(
                image: avatarImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> user) {
    final targetId = user['id'] as String;
    if (targetId == _currentUserId) return const SizedBox.shrink();

    final isFollowing = _currentUserFollowingIds.contains(targetId);
    final followsUs = _currentUserFollowerIds.contains(targetId);

    if (isFollowing) {
      return GestureDetector(
        onTap: () => _openConversation(user),
        child: Container(
          width: 100,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            "Message",
            style: GoogleFonts.ibmPlexSansArabic(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      final btnText = followsUs ? "Follow back" : "Follow";
      return GestureDetector(
        onTap: () => _toggleFollow(user),
        child: Container(
          width: 100,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF7C57FC), // App Brand Purple
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            btnText,
            style: GoogleFonts.ibmPlexSansArabic(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildListUserItem(Map<String, dynamic> user, int index, bool isFollowersTab) {
    final username = user['username'] ?? 'unknown';
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final isOwnProfile = widget.userId == _currentUserId;
    final targetId = user['id'] as String;
    final isFollowing = _currentUserFollowingIds.contains(targetId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _buildAvatarWidget(user, index),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fullName.isNotEmpty ? fullName : username,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF687684),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(user),
          if (isOwnProfile && isFollowing && targetId != _currentUserId) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _toggleFollow(user),
              child: const Icon(
                Icons.close,
                color: Color(0xFF8E8E93),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: GoogleFonts.ibmPlexSansArabic(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C57FC),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: const Color(0xFF687684),
          isScrollable: false,
          tabs: [
            Tab(text: "${_followers.length} followers"),
            Tab(text: "${_following.length} following"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C57FC)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Followers Tab
                _buildTabContent(true),
                // 2. Following Tab
                _buildTabContent(false),
              ],
            ),
    );
  }

  Widget _buildTabContent(bool isFollowersTab) {
    final list = isFollowersTab ? _filteredFollowers : _filteredFollowing;

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF687684), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.ibmPlexSansArabic(color: Colors.black, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF687684)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // User list
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    isFollowersTab ? "No followers found" : "No following found",
                    style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF687684)),
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return _buildListUserItem(list[index], index, isFollowersTab);
                  },
                ),
        ),
      ],
    );
  }
}
