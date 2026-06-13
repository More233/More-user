import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestedUser {
  final String name;
  final String username;
  final String subtitle;
  final String avatarAsset;
  final bool isOnMore;
  final bool hasMutualFriends;

  SuggestedUser({
    required this.name,
    required this.username,
    required this.subtitle,
    required this.avatarAsset,
    this.isOnMore = false,
    this.hasMutualFriends = false,
  });
}

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

  final List<SuggestedUser> _allSuggestions = [
    SuggestedUser(
      name: 'Maya Thompson',
      username: 'mayat',
      subtitle: 'Recently at Bice Bottle Coffee',
      avatarAsset: 'assets/Timeline/images/profile_image_1.png',
      isOnMore: false,
    ),
    SuggestedUser(
      name: 'Jordan Marco',
      username: 'jordanmarco',
      subtitle: '5 Mutual Friends',
      avatarAsset: 'assets/Timeline/images/profile_image2.png',
      hasMutualFriends: true,
    ),
    SuggestedUser(
      name: 'Ava Johnson',
      username: 'avaj',
      subtitle: 'On More',
      avatarAsset: 'assets/Timeline/images/avatar.png',
      isOnMore: true,
    ),
    SuggestedUser(
      name: 'karennne',
      username: 'karennne',
      subtitle: 'On More',
      avatarAsset: 'assets/Timeline/images/element.png',
      isOnMore: true,
    ),
  ];

  final List<SuggestedUser> _contacts = [
    SuggestedUser(
      name: 'Maya Thompson',
      username: 'mayat',
      subtitle: 'In your contacts',
      avatarAsset: 'assets/Timeline/images/profile_image_1.png',
    ),
    SuggestedUser(
      name: 'Jordan Marco',
      username: 'jordanmarco',
      subtitle: 'In your contacts',
      avatarAsset: 'assets/Timeline/images/profile_image2.png',
    ),
    SuggestedUser(
      name: 'Ava Johnson',
      username: 'avaj',
      subtitle: 'In your contacts',
      avatarAsset: 'assets/Timeline/images/avatar.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _localFollowed = Set.from(widget.followedUsernames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              backgroundImage: AssetImage('assets/Timeline/images/profile_image_1.png'),
            ),
          ),
          Positioned(
            left: 12,
            child: CircleAvatar(
              radius: 9,
              backgroundImage: AssetImage('assets/Timeline/images/profile_image2.png'),
            ),
          ),
          Positioned(
            left: 24,
            child: CircleAvatar(
              radius: 9,
              backgroundImage: AssetImage('assets/Timeline/images/avatar.png'),
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
        backgroundImage: AssetImage(user.avatarAsset),
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

    return Container(
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
              child: SingleChildScrollView(
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
