import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  Widget build(BuildContext context) {
    final tabItems = <CNTabBarItem>[
      const CNTabBarItem(
        label: 'الرئيسية',
        icon: CNSymbol('house.fill', size: 17.0),
      ),
      const CNTabBarItem(
        label: 'استكشف',
        icon: CNSymbol('safari.fill', size: 17.0),
      ),
      const CNTabBarItem(
        label: 'الحجوزات',
        icon: CNSymbol('calendar', size: 17.0),
      ),
      const CNTabBarItem(
        label: 'الطلبات',
        icon: CNSymbol('bag.fill', size: 17.0),
      ),
      const CNTabBarItem(
        label: 'الرسائل',
        icon: CNSymbol('bubble.left.and.bubble.right.fill', size: 17.0),
      ),
    ];

    final safeIndex = selectedIndex.clamp(0, tabItems.length - 1);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
        child: CNTabBar(
          currentIndex: safeIndex,
          iconSize: 17.0,
          onTap: (idx) {
            HapticFeedback.selectionClick();
            onItemTapped(idx);
          },
          tint: const Color(0xFF7C57FC),
          items: tabItems,
        ),
      ),
    );
  }
}


