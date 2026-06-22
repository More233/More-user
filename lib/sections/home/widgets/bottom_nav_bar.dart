import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  static const _items = [
    'Home',
    'Explore',
    'Booking',
    'Order',
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Nav bar container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFC).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFFE8E8E8),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (index) {
                    final label = _items[index];
                    final isActive = index == selectedIndex;
                    return _NavItem(
                      label: label,
                      isActive: isActive,
                      onTap: () => onItemTapped(index),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        // Spacer for iOS Home indicator safe area
        SizedBox(height: bottomPadding > 0 ? bottomPadding + 6 : 16),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  Widget _buildIcon() {
    if (label == 'Home') {
      return SvgPicture.asset(
        'assets/home/icons/home.svg',
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Explore') {
      return SvgPicture.asset(
        'assets/home/icons/explore_nav_icon.svg',
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Booking') {
      return SvgPicture.asset(
        'assets/home/icons/booking_nav_icon.svg',
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    if (label == 'Order') {
      return SvgPicture.asset(
        'assets/home/icons/order_nav_icon.svg',
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
          BlendMode.srcIn,
        ),
      );
    }
    return const Icon(Icons.help_outline);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
