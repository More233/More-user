import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String? userAvatarUrl;
  final bool hasUnreadNotifications;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.userAvatarUrl,
    this.hasUnreadNotifications = false,
  });

  static const _items = [
    'Home',
    'Search',
    'Notifications',
    'Messages',
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
                showBadge: label == 'Notifications' && hasUnreadNotifications,
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
  final bool showBadge;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.userAvatarUrl,
    this.showBadge = false,
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
    if (label == 'Search') {
      return SvgPicture.asset(
        'assets/home/icons/search_01.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Notifications') {
      return Icon(
        CupertinoIcons.bell,
        size: 24,
        color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
      );
    }
    if (label == 'Messages') {
      return Icon(
        CupertinoIcons.chat_bubble,
        size: 24,
        color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildIcon(),
              if (showBadge)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
