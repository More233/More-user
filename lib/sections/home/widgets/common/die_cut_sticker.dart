import 'package:flutter/material.dart';

class DieCutSticker extends StatelessWidget {
  final String emoji;
  final double size;
  final Color borderColor;
  final double strokeWidth;

  const DieCutSticker({
    super.key,
    required this.emoji,
    this.size = 32.0,
    this.borderColor = Colors.white,
    this.strokeWidth = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer border stroke with drop shadow
        Text(
          emoji,
          style: TextStyle(
            fontSize: size,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2.5),
              ),
            ],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = borderColor,
          ),
        ),
        // Foreground solid emoji
        Text(
          emoji,
          style: TextStyle(
            fontSize: size,
          ),
        ),
      ],
    );
  }
}
