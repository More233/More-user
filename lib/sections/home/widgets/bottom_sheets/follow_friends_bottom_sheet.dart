import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../models/suggested_user.dart';

class FollowFriendsBottomSheet extends StatefulWidget {
  final Set<String> followedUsernames;
  final Function(String, bool) onFollowChanged;

  const FollowFriendsBottomSheet({
    super.key,
    required this.followedUsernames,
    required this.onFollowChanged,
  });

  @override
  State<FollowFriendsBottomSheet> createState() => _FollowFriendsBottomSheetState();
}

class _FollowFriendsBottomSheetState extends State<FollowFriendsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Set<String> _localFollowed;

  List<SuggestedUser> _allSuggestions = [];
  List<SuggestedUser> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localFollowed = Set.from(widget.followedUsernames);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  String _getAvatarAsset(String username) {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    final lower = clean.toLowerCase();
    if (lower == 'mayat') {
      return 'assets/home/images/profile_image_1.png';
    } else if (lower == 'jordanmarco') {
      return 'assets/home/images/profile_image2.png';
    } else if (lower == 'avaj') {
      return 'assets/home/images/avatar.png';
    } else {
      return 'assets/home/images/element.png';
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
    return AssetImage(_getAvatarAsset(username));
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;

      // 1. Fetch registered profiles from Supabase database
      final List<dynamic> profilesData = await client.from('profiles').select();

      final List<Map<String, dynamic>> otherProfiles = [];
      for (final p in profilesData) {
        final id = p['id'] as String;
        if (id == currentUserId) continue;

        final firstName = p['first_name'] as String? ?? '';
        final lastName = p['last_name'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        final username = p['username'] as String? ?? '';
        final phone = p['phone'] as String? ?? '';
        final email = p['email'] as String? ?? '';
        final avatarUrl = p['avatar_url'] as String?;

        otherProfiles.add({
          'id': id,
          'name': name.isEmpty ? username : name,
          'username': username,
          'phone': phone,
          'email': email,
          'avatar_url': avatarUrl,
        });
      }

      // 2. Suggestions list populated from Supabase database profiles (actual users)
      final List<SuggestedUser> suggestions = [];
      for (final p in otherProfiles) {
        final username = p['username'] as String;
        final name = p['name'] as String;
        final avatarUrl = p['avatar_url'] as String?;

        suggestions.add(SuggestedUser(
          name: name,
          username: username,
          subtitle: 'On More',
          avatarUrl: avatarUrl,
          isOnMore: true,
        ));
      }

      // 3. Fetch device contacts
      List<Contact> deviceContacts = [];
      try {
        final status = await ph.Permission.contacts.status;
        if (status.isGranted) {
          deviceContacts = await FlutterContacts.getAll(
            properties: {ContactProperty.phone, ContactProperty.email},
          );
        } else {
          final requestStatus = await ph.Permission.contacts.request();
          if (requestStatus.isGranted) {
            deviceContacts = await FlutterContacts.getAll(
              properties: {ContactProperty.phone, ContactProperty.email},
            );
          }
        }
      } catch (e) {
        debugPrint("Error fetching contacts: $e");
      }

      // 4. Match device contacts against database profiles to only display registered users
      final List<SuggestedUser> matchedContacts = [];
      if (deviceContacts.isNotEmpty) {
        for (final dc in deviceContacts) {
          final String dcName = dc.displayName ?? '';
          final String dcPhone = dc.phones.isNotEmpty ? dc.phones.first.number : '';
          final String dcEmail = dc.emails.isNotEmpty ? dc.emails.first.address : '';

          if (dcPhone.isEmpty && dcEmail.isEmpty) continue;

          final normalizedPhone = _normalizePhone(dcPhone);

          final match = otherProfiles.firstWhere(
            (p) {
              final pPhone = p['phone'] as String? ?? '';
              final pEmail = p['email'] as String? ?? '';
              if (normalizedPhone.isNotEmpty && pPhone.isNotEmpty) {
                if (_normalizePhone(pPhone) == normalizedPhone) return true;
              }
              if (dcEmail.isNotEmpty && pEmail.isNotEmpty) {
                if (dcEmail.toLowerCase() == pEmail.toLowerCase()) return true;
              }
              return false;
            },
            orElse: () => {},
          );

          if (match.isNotEmpty) {
            final String username = match['username'] as String;
            final String name = dcName.isNotEmpty ? dcName : username;
            final String? avatarUrl = match['avatar_url'] as String?;

            matchedContacts.add(SuggestedUser(
              name: name,
              username: username,
              subtitle: 'In your contacts',
              avatarUrl: avatarUrl,
              isOnMore: true,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _allSuggestions = suggestions;
          _contacts = matchedContacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in _fetchData: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SuggestedUser> _filterList(List<SuggestedUser> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((u) =>
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.username.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildMutualAvatars() {
    return SizedBox(
      width: 44,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: 9,
              backgroundImage: AssetImage('assets/home/images/profile_image_1.png'),
            ),
          ),
          Positioned(
            left: 12,
            child: CircleAvatar(
              radius: 9,
              backgroundImage: AssetImage('assets/home/images/profile_image2.png'),
            ),
          ),
          Positioned(
            left: 24,
            child: CircleAvatar(
              radius: 9,
              backgroundImage: AssetImage('assets/home/images/avatar.png'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(SuggestedUser user) {
    final isFollowing = _localFollowed.contains(user.username);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: _getAvatarProvider(user.username, user.avatarUrl),
      ),
      title: Text(
        user.name,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Row(
        children: [
          if (user.isOnMore) ...[
            const Icon(Icons.sentiment_satisfied_alt, color: Color(0xFF7C57FC), size: 16),
            const SizedBox(width: 4),
          ],
          if (user.hasMutualFriends) ...[
            _buildMutualAvatars(),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              user.subtitle,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: const Color(0xFF82858C),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: SizedBox(
        height: 32,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isFollowing ? const Color(0xFFF2EEFC) : Colors.white,
            side: BorderSide(
              color: isFollowing ? Colors.transparent : const Color(0xFF7C57FC),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: () {
            setState(() {
              if (isFollowing) {
                _localFollowed.remove(user.username);
                widget.onFollowChanged(user.username, false);
              } else {
                _localFollowed.add(user.username);
                widget.onFollowChanged(user.username, true);
              }
            });
          },
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7C57FC),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = _filterList(_allSuggestions);
    final filteredContacts = _filterList(_contacts);
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),

            // Header title
            Center(
              child: Text(
                'Add friends',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Container(
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
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Scrollable Body
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CupertinoActivityIndicator(color: Color(0xFF7C57FC)),
                      ),
                    )
                  : (filteredSuggestions.isEmpty && filteredContacts.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No suggestions found',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                color: const Color(0xFF82858C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Suggestions section
                              if (filteredSuggestions.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Suggestions',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'See all',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C57FC),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredSuggestions.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserTile(filteredSuggestions[index]);
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Contacts section
                              if (filteredContacts.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'From your contacts',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'See all',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7C57FC),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredContacts.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserTile(filteredContacts[index]);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
