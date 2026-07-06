import 'package:flutter/material.dart';

class DotSeparator extends StatelessWidget {
  const DotSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF3B3C4F).withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
