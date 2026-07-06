import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExploreMapTabs extends StatelessWidget {
  final int selectedMapTab;
  final Function(int) onTabChanged;

  const ExploreMapTabs({
    super.key,
    required this.selectedMapTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillTabItem(
            index: 0,
            iconPath: 'assets/explore/earth.svg',
          ),
          const SizedBox(width: 8),
          _buildPillTabItem(
            index: 1,
            iconPath: '',
            iconData: Icons.explore_outlined,
          ),
          const SizedBox(width: 8),
          _buildPillTabItem(
            index: 2,
            iconPath: '',
            iconData: Icons.sensors,
          ),
          const SizedBox(width: 8),
          _buildPillTabItem(
            index: 3,
            iconPath: 'assets/explore/favourite.svg',
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabItem({
    required int index,
    required String iconPath,
    IconData? iconData,
  }) {
    final bool isActive = selectedMapTab == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE6FC) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: iconData != null
            ? Icon(
                iconData,
                size: 22,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
              )
            : SvgPicture.asset(
                iconPath,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }
}

