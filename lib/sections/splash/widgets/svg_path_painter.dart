import 'package:flutter/material.dart';

class SvgPathPainter extends CustomPainter {
  final List<Path> paths;
  final double progress;
  final Color color;

  const SvgPathPainter({
    required this.paths,
    required this.progress,
    required this.color,
  });

  // Exact centerline points that follow the cursive handwriting path of "More"
  // scaled to the SVG viewBox 299x71
  static const List<Offset> _centerlinePoints = [
    // M
    Offset(12, 35), Offset(3, 33), Offset(16, 15), Offset(22.6, 62),
    Offset(48, 30), Offset(65.7, 14.9), Offset(35.7, 63.9),
    Offset(71.6, 61.7), Offset(103, 16.6), Offset(107, 56), Offset(123, 31.8),
    
    // o (circle loops counter-clockwise)
    Offset(140, 20), Offset(136, 30), Offset(145, 54), Offset(165, 54), Offset(170, 30), Offset(160, 16),
    Offset(140, 20), // close circle
    Offset(165, 12), Offset(185, 29), Offset(189, 15), // transition to r (with bottom loop)
    
    // r
    Offset(191.5, 2), Offset(200, 5), Offset(209, 7), Offset(217, 53), Offset(223, 35), Offset(236, 49),
    
    // e (loop counter-clockwise, through top-right first)
    Offset(283, 7.5), Offset(273, 1), Offset(251, 5), Offset(245, 30), Offset(254, 53), Offset(272, 60), Offset(281, 52), Offset(298, 50)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty) return;

    // Exact viewBox in SVG is 299x71
    final double scaleX = size.width / 299.0;
    final double scaleY = size.height / 71.0;
    final Matrix4 scaleMatrix = Matrix4.diagonal3Values(scaleX, scaleY, 1.0);

    // Save a layer to isolate blending
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Draw the actual filled logo paths first (destination)
    final combinedLogoPath = Path()..fillType = PathFillType.evenOdd;
    for (var originalPath in paths) {
      combinedLogoPath.addPath(originalPath.transform(scaleMatrix.storage), Offset.zero);
    }

    final logoPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(combinedLogoPath, logoPaint);

    // 2. Draw the animated centerline path as a thick mask stroke on top using BlendMode.dstIn (source)
    final centerlinePath = Path();
    if (_centerlinePoints.isNotEmpty) {
      centerlinePath.moveTo(_centerlinePoints[0].dx, _centerlinePoints[0].dy);
      for (int i = 1; i < _centerlinePoints.length; i++) {
        centerlinePath.lineTo(_centerlinePoints[i].dx, _centerlinePoints[i].dy);
      }
    }

    // Scale the centerline path
    final scaledCenterline = centerlinePath.transform(scaleMatrix.storage);

    // Calculate subpath based on progress
    final animatedPath = Path();
    final pathMetrics = scaledCenterline.computeMetrics().toList();
    double totalLength = 0.0;
    for (final metric in pathMetrics) {
      totalLength += metric.length;
    }

    final targetLength = totalLength * progress;
    double currentLength = 0.0;
    for (final metric in pathMetrics) {
      if (currentLength + metric.length <= targetLength) {
        animatedPath.addPath(metric.extractPath(0, metric.length), Offset.zero);
        currentLength += metric.length;
      } else {
        final remainingLength = targetLength - currentLength;
        animatedPath.addPath(metric.extractPath(0, remainingLength), Offset.zero);
        break;
      }
    }

    // Draw the mask stroke using BlendMode.dstIn
    final maskPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38.0 * scaleX
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.dstIn; // Keep what was already drawn (the logo) where the stroke overlaps

    canvas.drawPath(animatedPath, maskPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SvgPathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
