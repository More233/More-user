import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class TimelineTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const TimelineTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate the width of each tab including the 8px spacing gap
          final double totalWidth = constraints.maxWidth;
          final double gap = 8.0;
          final double tabWidth = (totalWidth - gap) / 2;

          return Stack(
            children: [
              // Sliding Active Tab Indicator Background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                left: selectedIndex == 0 ? 0 : tabWidth + gap,
                width: tabWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE6FC),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),

              // Foreground Tab Buttons Row
              Row(
                children: [
                  Expanded(
                    child: _TabItem(
                      label: 'Timeline',
                      iconPath:
                          'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/icon/time-04.svg',
                      isActive: selectedIndex == 0,
                      onTap: () => onTabChanged(0),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _TabItem(
                      label: 'Social',
                      iconPath:
                          'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/icon/user-multiple.svg',
                      isActive: selectedIndex == 1,
                      onTap: () => onTabChanged(1),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.iconPath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isActive
                    ? const Color(0xFF7C57FC)
                    : const Color(0xFF3B3C4F).withValues(alpha: 0.75),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF7C57FC)
                    : const Color(0xFF3B3C4F).withValues(alpha: 0.75),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
