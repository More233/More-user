import 'dart:ui';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Current location locator button
        GestureDetector(
          onTap: onLocationTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/explore/sent.svg',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7C57FC),
                    BlendMode.srcIn,
                  ),
                ),
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
        const SizedBox(width: 44),
      ],
    );
  }
}
