import 'package:flutter/material.dart';

class CropGridPainter extends CustomPainter {
  const CropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    final firstThirdWidth = size.width / 3.0;
    canvas.drawLine(Offset(firstThirdWidth, 0), Offset(firstThirdWidth, size.height), paint);
    canvas.drawLine(Offset(firstThirdWidth * 2, 0), Offset(firstThirdWidth * 2, size.height), paint);

    // Draw horizontal lines
    final firstThirdHeight = size.height / 3.0;
    canvas.drawLine(Offset(0, firstThirdHeight), Offset(size.width, firstThirdHeight), paint);
    canvas.drawLine(Offset(0, firstThirdHeight * 2), Offset(size.width, firstThirdHeight * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CropGridPainter oldDelegate) => false;
}
