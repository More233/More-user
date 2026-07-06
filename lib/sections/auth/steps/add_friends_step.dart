import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../models/user_card_info.dart';

class AddFriendsStep extends StatefulWidget {
  final VoidCallback onDone;

  const AddFriendsStep({
    super.key,
    required this.onDone,
  });

  @override
  State<AddFriendsStep> createState() => _AddFriendsStepState();
}

class _AddFriendsStepState extends State<AddFriendsStep> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<UserCardInfo> _suggestions = [];
  List<UserCardInfo> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Set<String> _followedUsernames = {};
  final Set<String> _invitedUsernames = {};

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  String _getAvatarPath(String username) {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    final lower = clean.toLowerCase();
    if (lower == 'mayat') {
      return 'assets/Auth Section/images/element.png';
    } else if (lower == 'jordanmarco') {
      return 'assets/Auth Section/images/element_1.png';
    } else if (lower == 'avaj') {
      return 'assets/Auth Section/images/element_2.png';
    } else {
      final hash = clean.codeUnits.fold(0, (prev, element) => prev + element);
      final index = hash % 3;
      if (index == 0) {
        return 'assets/Auth Section/images/element.png';
      } else if (index == 1) {
        return 'assets/Auth Section/images/element_1.png';
      } else {
        return 'assets/Auth Section/images/element_2.png';
      }
    }
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 1. Suggestions: Query other profiles selecting only public fields and limiting to 30
      final List<dynamic> suggestionsData = await client
          .from('profiles')
          .select('id, first_name, last_name, username, city, avatar_url')
          .neq('id', currentUserId)
          .limit(30);

      final List<UserCardInfo> suggestions = [];
      final List<UserCardInfo> contacts = [];

      for (final p in suggestionsData) {
        final firstName = p['first_name'] as String? ?? '';
        final lastName = p['last_name'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        final username = p['username'] as String? ?? '';
        final city = p['city'] as String? ?? '';

        String detailText = 'On More';
        Widget? detailIcon = const Icon(Icons.sentiment_satisfied, size: 14, color: Color(0xFF9CA3AF));

        if (username.toLowerCase() == 'jordanmarco') {
          detailText = '5 Mutual Friends';
          detailIcon = const Icon(Icons.people, size: 14, color: Color(0xFF9CA3AF));
        } else if (city.isNotEmpty) {
          detailText = 'Recently at $city';
          detailIcon = SvgPicture.asset(
            'assets/Auth Section/icons/location.svg',
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
          );
        }

        final isFollowing = _followedUsernames.contains(username.toLowerCase());

        suggestions.add(
          UserCardInfo(
            name: name.isEmpty ? username : name,
            username: '@$username',
            avatarPath: _getAvatarPath(username),
            detailText: detailText,
            detailIcon: detailIcon,
            isRegistered: true,
            isFollowing: isFollowing,
          ),
        );
      }

      // Request and fetch device contacts
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
        // Fallback silently if contacts API fails
      }

      // 2. Contacts: check if registered by querying ONLY matched numbers/emails from DB (Secure)
      List<dynamic> matchedProfilesData = [];
      if (deviceContacts.isNotEmpty) {
        final List<String> contactPhones = [];
        final List<String> contactEmails = [];
        for (final dc in deviceContacts) {
          final String dcPhone = dc.phones.isNotEmpty ? dc.phones.first.number : '';
          final String dcEmail = dc.emails.isNotEmpty ? dc.emails.first.address : '';
          if (dcPhone.isNotEmpty) {
            contactPhones.add(_normalizePhone(dcPhone));
          }
          if (dcEmail.isNotEmpty) {
            contactEmails.add(dcEmail.toLowerCase());
          }
        }

        final List<String> orClauses = [];
        if (contactPhones.isNotEmpty) {
          final phonesList = contactPhones.map((p) => '"$p"').join(',');
          orClauses.add('phone.in.($phonesList)');
        }
        if (contactEmails.isNotEmpty) {
          final emailsList = contactEmails.map((e) => '"$e"').join(',');
          orClauses.add('email.in.($emailsList)');
        }

        if (orClauses.isNotEmpty) {
          try {
            matchedProfilesData = await client
                .from('profiles')
                .select('id, first_name, last_name, username, city, avatar_url, phone, email')
                .neq('id', currentUserId)
                .or(orClauses.join(','));
          } catch (e) {
            debugPrint("Error querying matched profiles: $e");
          }
        }
      }

      if (deviceContacts.isNotEmpty) {
        for (final dc in deviceContacts) {
          final String dcName = dc.displayName ?? '';
          final String dcPhone = dc.phones.isNotEmpty ? dc.phones.first.number : '';
          final String dcEmail = dc.emails.isNotEmpty ? dc.emails.first.address : '';

          if (dcPhone.isEmpty && dcEmail.isEmpty) continue; // Skip empty contact entries

          final normalizedPhone = _normalizePhone(dcPhone);

          // Check registration
          final match = matchedProfilesData.firstWhere(
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
            orElse: () => null,
          );

          final isRegistered = match != null;
          final String username = isRegistered ? (match['username'] as String) : (dcPhone.isNotEmpty ? dcPhone : dcEmail);
          final String name = dcName.isNotEmpty ? dcName : username;

          final isFollowing = isRegistered && _followedUsernames.contains(username.toLowerCase());
          final isInvited = !isRegistered && _invitedUsernames.contains(username.toLowerCase());

          contacts.add(
            UserCardInfo(
              name: name,
              username: isRegistered ? '@$username' : username,
              avatarPath: _getAvatarPath(username),
              detailText: 'In your contacts',
              isRegistered: isRegistered,
              isFollowing: isFollowing,
              isInvited: isInvited,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(String username) async {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    final cleanLower = clean.toLowerCase();
    final isFollowing = !_followedUsernames.contains(cleanLower);

    setState(() {
      if (isFollowing) {
        _followedUsernames.add(cleanLower);
      } else {
        _followedUsernames.remove(cleanLower);
      }

      // Sync suggestions list
      for (final u in _suggestions) {
        final uClean = u.username.startsWith('@') ? u.username.substring(1) : u.username;
        if (uClean.toLowerCase() == cleanLower) {
          u.isFollowing = isFollowing;
        }
      }

      // Sync contacts list
      for (final u in _contacts) {
        final uClean = u.username.startsWith('@') ? u.username.substring(1) : u.username;
        if (uClean.toLowerCase() == cleanLower) {
          u.isFollowing = isFollowing;
        }
      }
    });

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final targetProfile = await client
          .from('profiles')
          .select('id')
          .eq('username', clean)
          .maybeSingle();

      if (targetProfile != null) {
        final targetId = targetProfile['id'] as String;
        if (isFollowing) {
          await client.from('follows').upsert({
            'follower_id': currentUser.id,
            'following_id': targetId,
          });
        } else {
          await client
              .from('follows')
              .delete()
              .eq('follower_id', currentUser.id)
              .eq('following_id', targetId);
        }
      }
    } catch (e) {
      debugPrint("Error toggling follow in onboarding: $e");
    }
  }

  void _toggleInvite(String username, String name) {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    final cleanLower = clean.toLowerCase();
    final isInvited = !_invitedUsernames.contains(cleanLower);

    setState(() {
      if (isInvited) {
        _invitedUsernames.add(cleanLower);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invitation sent to $name!',
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            ),
            backgroundColor: const Color(0xFF7C57FC),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _invitedUsernames.remove(cleanLower);
      }

      // Sync contacts list
      for (final u in _contacts) {
        final uClean = u.username.startsWith('@') ? u.username.substring(1) : u.username;
        if (uClean.toLowerCase() == cleanLower) {
          u.isInvited = isInvited;
        }
      }
    });
  }

  List<UserCardInfo> _filterList(List<UserCardInfo> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuggestions = _filterList(_suggestions);
    final filteredContacts = _filterList(_contacts);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Add 5+ friends',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.onDone,
            child: Text(
              'Done',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C57FC),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/Auth Section/icons/search_01.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF9CA3AF),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          color: const Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or username',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(Icons.clear, color: Color(0xFF9CA3AF), size: 20),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                        strokeWidth: 3,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Something went wrong:\n$_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 14,
                                    color: const Color(0xFFE15252),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchProfiles,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C57FC),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Try Again',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchProfiles,
                          color: const Color(0xFF7C57FC),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      Text(
                                        'See all',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF7C57FC),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredSuggestions.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return _buildUserCard(filteredSuggestions[index]);
                                    },
                                  ),
                                  const SizedBox(height: 24),
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
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      Text(
                                        'See all',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF7C57FC),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredContacts.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return _buildUserCard(filteredContacts[index]);
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (filteredSuggestions.isEmpty && filteredContacts.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text(
                                        'No users found matching "$_searchQuery"',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 16,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserCardInfo user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(user.avatarPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.username,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (user.detailIcon != null) ...[
                      user.detailIcon!,
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        user.detailText,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Follow/Invite Button
          SizedBox(
            width: 90,
            height: 33,
            child: ElevatedButton(
              onPressed: () {
                if (user.isRegistered) {
                  _toggleFollow(user.username);
                } else {
                  _toggleInvite(user.username, user.name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: (user.isRegistered ? user.isFollowing : user.isInvited)
                    ? const Color(0xFFEDE6FC)
                    : const Color(0xFF7C57FC),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                user.isRegistered
                    ? (user.isFollowing ? 'Following' : 'Follow')
                    : (user.isInvited ? 'Invited' : 'Invite'),
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (user.isRegistered ? user.isFollowing : user.isInvited)
                      ? const Color(0xFF7C57FC)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
