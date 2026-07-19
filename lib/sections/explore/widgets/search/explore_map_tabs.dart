import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExploreMapTabs extends StatefulWidget {
  final int selectedMapTab;
  final Function(int) onTabChanged;

  const ExploreMapTabs({
    super.key,
    required this.selectedMapTab,
    required this.onTabChanged,
  });

  @override
  State<ExploreMapTabs> createState() => _ExploreMapTabsState();
}

class _ExploreMapTabsState extends State<ExploreMapTabs> {
  double _previousTab = 0;

  @override
  void initState() {
    super.initState();
    _previousTab = widget.selectedMapTab.toDouble();
  }

  @override
  void didUpdateWidget(ExploreMapTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMapTab != widget.selectedMapTab) {
      _previousTab = oldWidget.selectedMapTab.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF181C26).withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.3),
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
          child: Stack(
            children: [
              // Liquid Sliding Pill Background
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: _previousTab,
                  end: widget.selectedMapTab.toDouble(),
                ),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  final double target = widget.selectedMapTab.toDouble();
                  final double distance = (target - _previousTab).abs();
                  final double currentDist = (animValue - target).abs();
                  final double progress = distance > 0 
                      ? (1.0 - (currentDist / distance)).clamp(0.0, 1.0) 
                      : 1.0;
                  
                  // Water droplet stretch calculation
                  final double stretch = distance > 0
                      ? (38.0 * distance * 0.45 * (progress * (1.0 - progress) * 4.0))
                      : 0.0;
                  final double width = 38.0 + stretch;
                  
                  // Center and offset bias based on slide direction
                  final double center = 10.0 + (animValue * 44.0) + 19.0;
                  final double bias = distance > 0
                      ? (stretch * 0.5 * ((target - _previousTab) > 0 ? 1.0 : -1.0))
                      : 0.0;
                  final double left = (center + bias) - (width / 2.0);

                  return Positioned(
                    left: left,
                    top: 5,
                    width: width,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C253B) : const Color(0xFFEDE6FC),
                        borderRadius: BorderRadius.circular(19),
                      ),
                    ),
                  );
                },
              ),
              // Front layer of text/icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PillTabItem(
                      index: 0,
                      selectedMapTab: widget.selectedMapTab,
                      iconPath: 'assets/explore/earth.svg',
                      onTap: widget.onTabChanged,
                    ),
                    const SizedBox(width: 6),
                    _PillTabItem(
                      index: 1,
                      selectedMapTab: widget.selectedMapTab,
                      iconPath: '',
                      iconData: Icons.local_activity_outlined,
                      onTap: widget.onTabChanged,
                    ),
                    const SizedBox(width: 6),
                    _PillTabItem(
                      index: 2,
                      selectedMapTab: widget.selectedMapTab,
                      iconPath: '',
                      iconData: Icons.sensors,
                      onTap: widget.onTabChanged,
                    ),
                    const SizedBox(width: 6),
                    _PillTabItem(
                      index: 3,
                      selectedMapTab: widget.selectedMapTab,
                      iconPath: '',
                      iconData: Icons.person_outline,
                      onTap: widget.onTabChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTabItem extends StatelessWidget {
  final int index;
  final int selectedMapTab;
  final String iconPath;
  final IconData? iconData;
  final Function(int) onTap;

  const _PillTabItem({
    required this.index,
    required this.selectedMapTab,
    required this.iconPath,
    this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = selectedMapTab == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: iconData != null
            ? Icon(
                iconData,
                size: 18,
                color: isActive ? const Color(0xFF7C57FC) : (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF82858C)),
              )
            : SvgPicture.asset(
                iconPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isActive ? const Color(0xFF7C57FC) : (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF82858C)),
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }
}

