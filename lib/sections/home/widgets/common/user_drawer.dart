import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/messages_view_model.dart';
import '../../view_models/social_feed_view_model.dart';
import '../../../explore/view_models/explore_view_model.dart';
import '../../profile_screen.dart';
import '../../followers_following_screen.dart';
import '../../home_screen.dart';
import '../../../auth/account_manager.dart';
import '../../../auth/auth_flow_page.dart';
import '../saved/saved_screen.dart';
import '../../notifications_screen.dart';
import '../../../settings/widgets/language_sheet.dart';
import '../../../settings/screens/location_settings_screen.dart';
import '../../../settings/screens/suggestions_settings_screen.dart';
import '../../../settings/screens/blocked_users_screen.dart';
import '../../../settings/screens/settings_screen.dart';
import '../../../settings/screens/appearance_screen.dart';
import '../../../settings/screens/help_support_screen.dart';


class UserDrawer extends ConsumerStatefulWidget {
  final VoidCallback? onProfileUpdated;
  final VoidCallback? onCloseMenu;

  const UserDrawer({
    super.key,
    this.onProfileUpdated,
    this.onCloseMenu,
  });

  @override
  ConsumerState<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends ConsumerState<UserDrawer> {
  bool _loading = true;
  String _fullName = '';
  String _username = '';
  String? _avatarUrl;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isEditingAccounts = false;

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

      // Save current session to SharedPreferences
      await AccountManager.saveCurrentAccount();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131722) : const Color(0xFFF7F9FA),
      ),
      child: _loading
          ? const Center(
              child: CupertinoActivityIndicator(
                color: Color(0xFF7C57FC),
                radius: 12,
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
                                        ? CachedNetworkImageProvider(_avatarUrl!)
                                        : AssetImage(_avatarUrl!)) as ImageProvider
                                    : const AssetImage('assets/home/images/avatar_placeholder.png'),
                              ),
                            ),
                             IconButton(
                               icon: Icon(
                                 CupertinoIcons.person_crop_circle_badge_plus,
                                 color: isDark ? Colors.white : Colors.black87,
                                 size: 24,
                               ),
                               padding: EdgeInsets.zero,
                               constraints: const BoxConstraints(),
                               onPressed: () {
                                 debugPrint("==== Switcher Button Tapped ====");
                                 HapticFeedback.lightImpact();
                                 _showAccountsBottomSheet();
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
                          color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _username.isNotEmpty ? '@$_username' : '',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : const Color(0xFF687684),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onCloseMenu?.call();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersFollowingScreen(
                                      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                                      username: _username,
                                      initialTabIndex: 1, // Following tab
                                    ),
                                  ),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Text(
                                    '$_followingCount',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                    Text(
                                      'Following',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : const Color(0xFF687684),
                                      ),
                                    ),
                                  ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onCloseMenu?.call();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersFollowingScreen(
                                      userId: Supabase.instance.client.auth.currentUser?.id ?? '',
                                      username: _username,
                                      initialTabIndex: 0, // Followers tab
                                    ),
                                  ),
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Text(
                                    '$_followersCount',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                    Text(
                                      'Followers',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : const Color(0xFF687684),
                                      ),
                                    ),
                                ],
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
                          context: context,
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
                          context: context,
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
                          context: context,
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
                          context: context,
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
                          context: context,
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
                          context: context,
                          icon: CupertinoIcons.moon,
                          title: 'Appearance',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppearanceScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          context: context,
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
                          context: context,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1, color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF0F0F0), thickness: 1),
                        ),
                        _buildDrawerItem(
                          context: context,
                          icon: CupertinoIcons.settings,
                          title: 'Settings and privacy',
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            widget.onCloseMenu?.call();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                            _fetchDrawerData();
                            widget.onProfileUpdated?.call();
                          },
                        ),
                        _buildDrawerItem(
                          context: context,
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
                          context: context,
                          icon: CupertinoIcons.square_arrow_left,
                          title: 'Logout',
                          color: const Color(0xFFFF453A),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showLogoutConfirmationDialog(context);
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

  void _showLogoutConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log out of More?',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to log out?',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          widget.onCloseMenu?.call();
                          ref.invalidate(messagesViewModelProvider);
                          ref.invalidate(exploreViewModelProvider);
                          ref.invalidate(socialFeedViewModelProvider);
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const AuthFlowPage()),
                              (route) => false,
                            );
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444), // Red action button
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Log Out',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountsBottomSheet() async {
    debugPrint("==== _showAccountsBottomSheet() Called ====");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Save current session first to ensure it's in SharedPreferences
    await AccountManager.saveCurrentAccount();
    final initialAccounts = await AccountManager.getSavedAccounts();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        debugPrint("==== showModalBottomSheet Builder Called ====");
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: FutureBuilder<List<SavedAccount>>(
                  future: AccountManager.getSavedAccounts(),
                  initialData: initialAccounts,
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? initialAccounts;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _isEditingAccounts = !_isEditingAccounts;
                                  });
                                },
                                child: Text(
                                  _isEditingAccounts ? "Done" : "Edit",
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    color: const Color(0xFF7C57FC),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "Accounts",
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 60),
                            ],
                          ),
                        ),
                        Divider(color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F1F1), height: 1),
                        Flexible(
                          child: accounts.isEmpty
                              ? const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CupertinoActivityIndicator(
                                      color: Color(0xFF7C57FC),
                                      radius: 10,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: accounts.length,
                                  itemBuilder: (context, index) {
                                    final acc = accounts[index];
                                    final isActive = acc.userId == currentUserId;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: acc.avatarUrl != null && acc.avatarUrl!.isNotEmpty
                                            ? CachedNetworkImageProvider(acc.avatarUrl!)
                                            : const AssetImage('assets/home/images/avatar_placeholder.png') as ImageProvider,
                                      ),
                                      title: Text(
                                        acc.fullName,
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "@${acc.username}",
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          color: isDark ? Colors.white54 : const Color(0xFF687684),
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: isActive
                                          ? const Icon(
                                              CupertinoIcons.checkmark_circle_fill,
                                              color: Color(0xFF7C57FC),
                                              size: 24,
                                            )
                                          : (_isEditingAccounts
                                              ? IconButton(
                                                  icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                                                  onPressed: () async {
                                                    await AccountManager.removeAccount(acc.userId);
                                                    setModalState(() {});
                                                  },
                                                )
                                              : null),
                                      onTap: () async {
                                        if (isActive) return;
                                        if (_isEditingAccounts) return;

                                        Navigator.pop(context);
                                        widget.onCloseMenu?.call();
                                        
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CupertinoActivityIndicator(
                                              color: Color(0xFF7C57FC),
                                              radius: 12,
                                            ),
                                          ),
                                        );

                                        final success = await AccountManager.switchToAccount(acc.userId);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          if (success) {
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(builder: (context) => HomeScreen()),
                                              (route) => false,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Failed to switch account")),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                        Divider(color: isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F1F1), height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFFF7F9FA),
                            child: Icon(
                              CupertinoIcons.plus,
                              color: Color(0xFF7C57FC),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            "Add an account",
                            style: GoogleFonts.ibmPlexSansArabic(
                              color: const Color(0xFF7C57FC),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            await AccountManager.saveCurrentAccount();
                            ref.invalidate(messagesViewModelProvider);
                            ref.invalidate(exploreViewModelProvider);
                            ref.invalidate(socialFeedViewModelProvider);
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
                              Navigator.pop(context);
                              widget.onCloseMenu?.call();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const AuthFlowPage()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isEditingAccounts = false;
      });
    });
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = color ?? (isDark ? Colors.white : Colors.black87);
    final textDisplayColor = color ?? (isDark ? Colors.white : Colors.black);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: displayColor,
              size: 24,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: textDisplayColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
