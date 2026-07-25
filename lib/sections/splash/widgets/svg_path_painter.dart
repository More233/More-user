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

  // Exact centerline points that follow the new logo vector paths
  // scaled to the SVG viewBox 211x141
  static const List<Offset> _centerlinePoints = [
    Offset(105, 3), Offset(76, 31), Offset(133, 31),
    Offset(12, 140), Offset(12, 78), Offset(43, 34), Offset(86, 78), Offset(105, 141),
    Offset(148, 78), Offset(166, 34), Offset(210, 78), Offset(210, 140)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty) return;

    // Exact viewBox in SVG is 211x141
    final double scaleX = size.width / 211.0;
    final double scaleY = size.height / 141.0;
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
      ..strokeWidth = 60.0 * scaleX
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
