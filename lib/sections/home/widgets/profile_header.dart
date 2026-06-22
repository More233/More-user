import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const ProfileHeader({
    super.key,
    this.onSearchTap,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(
                'assets/home/images/element.png',
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Coin badge
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE9E9E9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/home/images/coin.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 5),
                Text(
                  '200',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF464646),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Search button
          _ActionButton(
            iconPath:
                'assets/home/icons/search_01.svg',
            onTap: onSearchTap,
          ),
          const SizedBox(width: 16),
          // Notification button
          _ActionButton(
            iconPath:
                'assets/home/icons/notification_02.svg',
            onTap: onNotificationTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onTap;

  const _ActionButton({required this.iconPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFF141B34),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
