import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile_screen.dart';
import '../saved/saved_screen.dart';
import '../../notifications_screen.dart';
import '../../../settings/widgets/language_sheet.dart';
import '../../../settings/screens/location_settings_screen.dart';
import '../../../settings/screens/suggestions_settings_screen.dart';
import '../../../settings/screens/blocked_users_screen.dart';
import '../../../settings/screens/settings_screen.dart';
import '../../../settings/screens/help_support_screen.dart';


class UserDrawer extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  final VoidCallback? onCloseMenu;

  const UserDrawer({
    super.key,
    this.onProfileUpdated,
    this.onCloseMenu,
  });

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  bool _loading = true;
  String _fullName = '';
  String _username = '';
  String? _avatarUrl;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDrawerData();
  }

  Future<void> _fetchDrawerData() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final results = await Future.wait<dynamic>([
        client.from('profiles').select().eq('id', user.id).maybeSingle(),
        client.from('follows').select('follower_id').eq('following_id', user.id),
        client.from('follows').select('following_id').eq('follower_id', user.id),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final followersData = results[1] as List<dynamic>;
      final followingData = results[2] as List<dynamic>;

      if (mounted) {
        setState(() {
          if (profile != null) {
            _fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
            _username = profile['username'] ?? '';
            _avatarUrl = profile['avatar_url'] as String?;
          }
          _followersCount = followersData.length;
          _followingCount = followingData.length;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching drawer profile data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FA),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C57FC),
              ),
            )
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Spacing
                  const SizedBox(height: 12),
                  // Header section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onCloseMenu?.call(); // Close sliding drawer
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      userPosts: const [],
                                      onPostUpdated: () {
                                        _fetchDrawerData();
                                        widget.onProfileUpdated?.call();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? (_avatarUrl!.startsWith('http')
                                        ? NetworkImage(_avatarUrl!)
                                        : AssetImage(_avatarUrl!)) as ImageProvider
                                    : const AssetImage('assets/home/images/avatar_placeholder.png'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                CupertinoIcons.person_crop_circle_badge_plus,
                                color: Colors.black87,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName.isNotEmpty ? _fullName : 'No Name',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _username.isNotEmpty ? '@$_username' : '',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF687684),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '$_followingCount',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Following',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF687684),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '$_followersCount',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Followers',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF687684),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Spacing before list (no divider here per Twitter layout)
                  const SizedBox(height: 20),
                  // Menu List
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildDrawerItem(
                          icon: CupertinoIcons.person,
                          title: 'Profile',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userPosts: const [],
                                  onPostUpdated: () {
                                    _fetchDrawerData();
                                    widget.onProfileUpdated?.call();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.bookmark,
                          title: 'Bookmarks',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.globe,
                          title: 'Language',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const LanguageSheet(),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.bell,
                          title: 'Notifications',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(showBackButton: true),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.location,
                          title: 'Location',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.sparkles,
                          title: 'Check-in Suggestions',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SuggestionsSettingsScreen(),
                              ),
                            );
                          },
                        ),

                        _buildDrawerItem(
                          icon: CupertinoIcons.person_crop_circle_badge_xmark,
                          title: 'Blocked people',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BlockedUsersScreen(),
                              ),
                            );
                          },
                        ),
                        // The single line/divider separating footer settings per Twitter layout
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1, color: Color(0xFFF0F0F0), thickness: 1),
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.settings,
                          title: 'Settings and privacy',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.question_circle,
                          title: 'Help Center',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: CupertinoIcons.square_arrow_left,
                          title: 'Logout',
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            await Supabase.instance.client.auth.signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
