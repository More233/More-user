import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StoryIconButton extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onTap;
  const StoryIconButton({
    super.key,
    required this.svgAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(10),
        child: SvgPicture.asset(
          svgAsset,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
