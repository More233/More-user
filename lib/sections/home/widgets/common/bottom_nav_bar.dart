import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF161822).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: Row(
              children: List.generate(_items.length, (index) {
                final label = _items[index];
                final isActive = index == selectedIndex;

                int badgeCount = 0;
                if (label == 'Messages') {
                  badgeCount = unreadMessagesCount;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onItemTapped(index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          _buildNavIcon(label, isActive, isDark),
                          if (badgeCount > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF161822) : Colors.white,
                                    width: 1.5,
                                  ),
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
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(String label, bool isActive, bool isDark) {
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

    final inactiveColor = isDark ? const Color(0xFFA0A3AB) : const Color(0xFF8E8E93);

    return AnimatedScale(
      scale: isActive ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: SvgPicture.asset(
        assetPath,
        width: 23,
        height: 23,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : inactiveColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
