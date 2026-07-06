import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileActionButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onTap;

  const ProfileActionButton({
    super.key,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFF141B34),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
