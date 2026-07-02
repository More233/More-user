import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String? userAvatarUrl;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.userAvatarUrl,
  });

  static const _items = [
    'Home',
    'Explore',
    'Reels',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8E8E8),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final label = _items[index];
              final isActive = index == selectedIndex;
              return _NavItem(
                label: label,
                isActive: isActive,
                onTap: () => onItemTapped(index),
                userAvatarUrl: userAvatarUrl,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? userAvatarUrl;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.userAvatarUrl,
  });

  Widget _buildIcon() {
    if (label == 'Home') {
      return SvgPicture.asset(
        'assets/home/icons/home.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Explore') {
      return SvgPicture.asset(
        'assets/home/icons/explore_nav_icon.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Reels') {
      return SvgPicture.asset(
        'assets/home/icons/reels_nav_icon.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Profile') {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFF7C57FC) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: userAvatarUrl != null && userAvatarUrl!.isNotEmpty
              ? (userAvatarUrl!.startsWith('http')
                  ? Image.network(userAvatarUrl!, fit: BoxFit.cover)
                  : Image.asset(userAvatarUrl!, fit: BoxFit.cover))
              : Image.asset(
                  'assets/home/images/avatar_placeholder.png',
                  fit: BoxFit.cover,
                ),
        ),
      );
    }
    return const Icon(Icons.help_outline);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: _buildIcon(),
        ),
      ),
    );
  }
}
