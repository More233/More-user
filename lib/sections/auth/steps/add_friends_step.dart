import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserCardInfo {
  final String name;
  final String username;
  final String avatarPath;
  final String detailText;
  final Widget? detailIcon;
  bool isFollowing;

  UserCardInfo({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.detailText,
    this.detailIcon,
    this.isFollowing = false,
  });
}

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

  late List<UserCardInfo> _suggestions;
  late List<UserCardInfo> _contacts;

  @override
  void initState() {
    super.initState();
    
    _suggestions = [
      UserCardInfo(
        name: 'Maya Thompson',
        username: '@mayat',
        avatarPath: 'assets/Auth Section/Basic information  Add Friend/image/Element.png',
        detailText: 'Recently at Blue Bottle Coffee',
        detailIcon: SvgPicture.asset(
          'assets/Auth Section/Discover more around you/icon/location-01.svg',
          width: 14,
          height: 14,
          colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
        ),
      ),
      UserCardInfo(
        name: 'Jordan Marco',
        username: '@jordanmarco',
        avatarPath: 'assets/Auth Section/Basic information  Add Friend/image/Element-1.png',
        detailText: '5 Mutual Friends',
        detailIcon: const Icon(Icons.people, size: 14, color: Color(0xFF9CA3AF)),
      ),
      UserCardInfo(
        name: 'Ava Johnson',
        username: '@avaj',
        avatarPath: 'assets/Auth Section/Basic information  Add Friend/image/Element-2.png',
        detailText: 'On More',
        detailIcon: const Icon(Icons.sentiment_satisfied, size: 14, color: Color(0xFF9CA3AF)),
      ),
    ];

    _contacts = [
      UserCardInfo(
        name: 'Maya Thompson',
        username: '@mayat',
        avatarPath: 'assets/Auth Section/Basic information  Add Friend/image/Element.png',
        detailText: 'In your contacts',
      ),
      UserCardInfo(
        name: 'Jordan Marco',
        username: '@jordanmarco',
        avatarPath: 'assets/Auth Section/Basic information  Add Friend/image/Element-1.png',
        detailText: 'In your contacts',
      ),
      UserCardInfo(
        name: 'Ava Johnson',
        username: '@avaj',
        avatarPath: 'assets/Auth Section/Basic information  Add Friend/image/Element-2.png',
        detailText: 'In your contacts',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      'assets/Auth Section/Basic information  Add Friend/icon/search-01.svg',
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
              child: SingleChildScrollView(
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
          // Follow Button
          SizedBox(
            width: 90,
            height: 33,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  user.isFollowing = !user.isFollowing;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: user.isFollowing ? const Color(0xFFEDE6FC) : const Color(0xFF7C57FC),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                user.isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: user.isFollowing ? const Color(0xFF7C57FC) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
