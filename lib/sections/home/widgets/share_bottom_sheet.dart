import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShareBottomSheet extends StatefulWidget {
  const ShareBottomSheet({super.key});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
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
    setState(() {
      _isLoading = true;
    });
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Fetch user IDs I follow
      final followingResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      // 2. Fetch user IDs who follow me
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

      // Query profiles for followed / following IDs
      if (userIds.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', userIds);

        for (var row in profilesResponse) {
          addProfile(row);
        }
      }

      // Fallback: If we don't have enough users (less than 5), fetch other active profiles
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
      debugPrint("Error loading real users for share sheet: $e");
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
    return const AssetImage('assets/home/images/element.png');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC8C8C8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Share with friends',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          color: const Color(0xFF1F242E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or username',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 15,
                            color: const Color(0xFF9CA3AF),
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Friends List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C57FC),
                    ),
                  )
                : (_filteredFriends.isEmpty
                    ? Center(
                        child: Text(
                          'No friends found',
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _filteredFriends[index];
                          final isSelected = _selectedUsernames.contains(friend['username']);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _getAvatarProvider(friend['avatar']),
                            ),
                            title: Text(
                              friend['name']!,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '@${friend['username']!}',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF7C57FC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedUsernames.add(friend['username']!);
                                  } else {
                                    _selectedUsernames.remove(friend['username']!);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      )),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _selectedUsernames.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Shared successfully with ${_selectedUsernames.length} friend(s)!',
                                style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                              ),
                              backgroundColor: const Color(0xFF7C57FC),
                            ),
                          );
                        },
                  child: Text(
                    'Share (${_selectedUsernames.length})',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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
