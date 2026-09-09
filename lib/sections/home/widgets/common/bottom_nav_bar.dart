import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBarItem {
  final String label;
  final IconData icon;

  const BottomNavBarItem({
    required this.label,
    required this.icon,
  });
}

/// Authentic Apple Liquid Glass Floating Navigation Dock
/// Features real frosted backdrop blur, specular highlight border,
/// dual ambient glow shadows, and a smooth spring-physics sliding indicator.
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

  static const List<BottomNavBarItem> _items = [
    BottomNavBarItem(
      label: 'الرئيسية',
      icon: CupertinoIcons.house_fill,
    ),
    BottomNavBarItem(
      label: 'استكشف',
      icon: CupertinoIcons.compass_fill,
    ),
    BottomNavBarItem(
      label: 'الحجوزات',
      icon: CupertinoIcons.calendar,
    ),
    BottomNavBarItem(
      label: 'الطلبات',
      icon: CupertinoIcons.bag_fill,
    ),
    BottomNavBarItem(
      label: 'الرسائل',
      icon: CupertinoIcons.chat_bubble_2_fill,
    ),
  ];

  static const Color primaryColor = Color(0xFF7C57FC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(33),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(33),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF1E1E24).withValues(alpha: 0.88),
                            const Color(0xFF141418).withValues(alpha: 0.76),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.90),
                            Colors.white.withValues(alpha: 0.78),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.92),
                    width: 1.0,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalItems = _items.length;
                    final itemWidth = constraints.maxWidth / totalItems;
                    final safeIndex = selectedIndex.clamp(0, totalItems - 1);

                    return Stack(
                      children: [
                        // Smooth Sliding Apple Liquid Indicator Pill (Supports RTL & LTR)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          right: isRtl ? safeIndex * itemWidth + 5 : null,
                          left: !isRtl ? safeIndex * itemWidth + 5 : null,
                          top: 7,
                          width: itemWidth - 10,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? primaryColor.withValues(alpha: 0.22)
                                  : primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: isDark
                                    ? primaryColor.withValues(alpha: 0.40)
                                    : primaryColor.withValues(alpha: 0.22),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),

                        // Navigation Items Row
                        Row(
                          children: List.generate(totalItems, (index) {
                            final item = _items[index];
                            final isSelected = index == safeIndex;

                            int badge = 0;
                            if (index == 4) {
                              badge = unreadMessagesCount;
                            }

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onItemTapped(index);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 21,
                                          color: isSelected
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.45)
                                                  : const Color(0xFF8E8E93)),
                                        ),
                                        if (badge > 0)
                                          Positioned(
                                            top: -3,
                                            right: -7,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF3B30),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                                                  width: 1.2,
                                                ),
                                              ),
                                              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                              child: Text(
                                                badge > 99 ? '99+' : '$badge',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.0,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? primaryColor
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.45)
                                                : const Color(0xFF8E8E93)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

