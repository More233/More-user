import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFriendsBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> previouslySelected;

  const AddFriendsBottomSheet({super.key, this.previouslySelected = const []});

  @override
  State<AddFriendsBottomSheet> createState() => _AddFriendsBottomSheetState();
}

class _AddFriendsBottomSheetState extends State<AddFriendsBottomSheet> {
  List<Map<String, dynamic>> _deviceProfiles = [];
  bool _isLoading = true;
  final List<Map<String, dynamic>> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    _selectedFriends.addAll(widget.previouslySelected);
    _fetchFriendsFromDatabase();
  }

  Future<void> _fetchFriendsFromDatabase() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      final List<dynamic> response = await client
          .from('profiles')
          .select('id, first_name, last_name, username, avatar_url');
      
      final List<Map<String, dynamic>> fetched = [];
      for (final p in response) {
        final id = p['id'] as String;
        if (id == currentUserId) continue;

        final firstName = p['first_name'] as String? ?? '';
        final lastName = p['last_name'] as String? ?? '';
        final username = p['username'] as String? ?? '';
        final avatarUrl = p['avatar_url'] as String?;
        final fullName = '$firstName $lastName'.trim();
        final displayName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? '@$username' : 'User');

        fetched.add({
          'name': displayName,
          'avatar_url': avatarUrl,
        });
      }

      if (mounted) {
        setState(() {
          _deviceProfiles = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching friends: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
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
            'Check-in with Friends',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Scrollable List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C57FC)))
                : _deviceProfiles.isEmpty
                    ? Center(
                        child: Text(
                          'No friends found',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _deviceProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = _deviceProfiles[index];
                          final name = profile['name'] as String;
                          final avatarUrl = profile['avatar_url'] as String?;
                          final isSelected = _selectedFriends.any((f) => f['name'] == name);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl) as ImageProvider
                                  : const AssetImage(
                                      'assets/home/images/element.png',
                                    ),
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
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
                                    _selectedFriends.add({
                                      'name': name,
                                      'avatar_url': avatarUrl,
                                    });
                                  } else {
                                    _selectedFriends.removeWhere((f) => f['name'] == name);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
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
                  onPressed: () {
                    Navigator.pop(context, _selectedFriends);
                  },
                  child: Text(
                    'Add Friends (${_selectedFriends.length})',
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
    );
  }
}
