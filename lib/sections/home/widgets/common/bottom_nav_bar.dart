import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String? userAvatarUrl;
  final int unreadNotificationsCount;
  final int unreadMessagesCount;
  final BorderRadius borderRadius;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.userAvatarUrl,
    required this.unreadNotificationsCount,
    required this.unreadMessagesCount,
    this.borderRadius = BorderRadius.zero,
  });

  static const _items = [
    'Home',
    'Explore',
    'Bookings',
    'Orders',
    'Messages',
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F1219).withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  final label = _items[index];
                  final isActive = index == selectedIndex;
                  
                  int badgeCount = 0;
                  if (label == 'Messages') {
                    badgeCount = unreadMessagesCount;
                  }

                  return _NavItem(
                    label: label,
                    isActive: isActive,
                    onTap: () => onItemTapped(index),
                    userAvatarUrl: userAvatarUrl,
                    badgeCount: badgeCount,
                  );
                }),
              ),
            ),
          ),
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
  final int badgeCount;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.userAvatarUrl,
    this.badgeCount = 0,
  });

  Widget _buildIcon() {
    String assetPath;
    if (label == 'Home') {
      assetPath = 'assets/home/icons/home.svg';
    } else if (label == 'Explore') {
      assetPath = 'assets/home/icons/explore_nav_icon.svg';
    } else if (label == 'Bookings') {
      assetPath = 'assets/home/icons/booking_nav_icon.svg';
    } else if (label == 'Orders') {
      assetPath = 'assets/home/icons/order_nav_icon.svg';
    } else if (label == 'Messages') {
      assetPath = 'assets/home/icons/chat_bubble_icon.svg';
    } else {
      assetPath = 'assets/home/icons/home.svg';
    }

    return SvgPicture.asset(
      assetPath,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(
        isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
        BlendMode.srcIn,
      ),
    );
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
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
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
