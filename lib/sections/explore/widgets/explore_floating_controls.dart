import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'search/explore_map_tabs.dart';

class ExploreFloatingControls extends StatelessWidget {
  final double bottom;
  final int selectedMapTab;
  final VoidCallback onLocationTap;
  final ValueChanged<int> onTabChanged;

  const ExploreFloatingControls({
    super.key,
    required this.bottom,
    required this.selectedMapTab,
    required this.onLocationTap,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current location locator button
          GestureDetector(
            onTap: onLocationTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/explore/sent.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF7C57FC),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // Core explore tabs (Discover, Plans, Live Now, My Places)
          ExploreMapTabs(
            selectedMapTab: selectedMapTab,
            onTabChanged: onTabChanged,
          ),

          // Right spacing placeholder to keep ExploreMapTabs centered
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}
