import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/screens/help_support_screen.dart';
import '../../auth/account_manager.dart';
import '../../auth/auth_flow_page.dart';
import 'rewards_screen.dart';
import 'more_pro_screen.dart';
import 'vouchers_screen.dart';
import 'about_app_screen.dart';
import 'partner_register_screen.dart';
import 'my_orders_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  String _displayName = 'Abdullah ELAWADY';
  String? _avatarUrl;
  final String _country = 'مصر';
  final String _flag = '🇪🇬';
  bool _isPro = false;
  final int _userPoints = 350;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('display_name, username, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _displayName = data['display_name'] ?? data['username'] ?? 'Abdullah ELAWADY';
          _avatarUrl = data['avatar_url'];
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد بالتأكيد تسجيل الخروج من حسابك؟',
          textAlign: TextAlign.right,
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.ibmPlexSansArabic()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('خروج', style: GoogleFonts.ibmPlexSansArabic(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await AccountManager.removeAccount(user.id);
      }
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthFlowPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2022);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Top Header (Screenshot 5)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings Gear icon on left
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 24),
                    color: textColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  // User Info on right (Avatar + Name + Country)
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _displayName,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _country,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(_flag, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Circular Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEDD5), // Soft peach bg
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    _avatarUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'A',
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF9A3412),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Promo Banner Card (Screenshot 5)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF), // Light purple background
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'شهر من More Pro علينا',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2022),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مع خصم 20% على اشتراكك الشهري',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12.5,
                              color: const Color(0xFF4B5563),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MoreProScreen(
                                    initialIsPro: _isPro,
                                    onProStatusChanged: (val) => setState(() => _isPro = val),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              _isPro ? 'عرض اشتراكك' : 'جرب مجاناً',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF7C57FC),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Pro Badge Circle (matching Screenshot 5)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'MORE pro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('✕', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            const Text(
                              'OSN+',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                color: Color(0xFF1E2022),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Menu Items List
              _buildMenuTile(
                icon: Icons.card_giftcard_rounded,
                title: 'مكافآت',
                trailingText: '$_userPoints نقطة',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.receipt_long_rounded,
                title: 'طلباتي السابقة',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.confirmation_number_outlined,
                title: 'القسائم',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VouchersScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.workspace_premium_rounded,
                title: 'More pro',
                trailingBadge: 'pro',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MoreProScreen(
                        initialIsPro: _isPro,
                        onProStatusChanged: (val) => setState(() => _isPro = val),
                      ),
                    ),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.help_outline_rounded,
                title: 'احصل على المساعدة',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.info_outline_rounded,
                title: 'حول التطبيق',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.handshake_outlined,
                title: 'انضم كشريك',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PartnerRegisterScreen()),
                  );
                },
                textColor: textColor,
              ),
              _buildMenuTile(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                onTap: _handleLogout,
                textColor: Colors.red,
                iconColor: Colors.red,
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color textColor,
    Color? iconColor,
    String? trailingText,
    String? trailingBadge,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: trailingText != null
          ? Text(
              trailingText,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: Colors.grey),
            )
          : (trailingBadge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trailingBadge,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              : null),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 14),
          Icon(icon, color: iconColor ?? textColor, size: 22),
        ],
      ),
    );
  }
}
