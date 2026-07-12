import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MarkerGenerator {
  static final Map<String, Uint8List> _normalPinCache = {};
  static final Map<String, Uint8List> _selectedPinCache = {};
  static final Map<String, Uint8List> _dotCache = {};

  static Future<Uint8List> getNormalPin(String type) async {
    final t = type.toLowerCase().trim();
    if (_normalPinCache.containsKey(t)) {
      return _normalPinCache[t]!;
    }
    final bytes = await _generateTeardropPin(type, isSelected: false);
    _normalPinCache[t] = bytes;
    return bytes;
  }

  static Future<Uint8List> getSelectedPin(String type) async {
    final t = type.toLowerCase().trim();
    if (_selectedPinCache.containsKey(t)) {
      return _selectedPinCache[t]!;
    }
    final bytes = await _generateTeardropPin(type, isSelected: true);
    _selectedPinCache[t] = bytes;
    return bytes;
  }

  static Future<Uint8List> getDotPin(String type) async {
    final t = type.toLowerCase().trim();
    if (_dotCache.containsKey(t)) {
      return _dotCache[t]!;
    }
    final bytes = await _generateDotPin(type);
    _dotCache[t] = bytes;
    return bytes;
  }

  static Future<Uint8List> _generateTeardropPin(String type, {required bool isSelected}) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;
    
    final double finalScale = isSelected ? 1.05 : 0.85;
    const double dx = 8.0;
    const double dy = 6.0;

    final double gap = 4.0 * finalScale;
    final double dotRadius = 3.8 * finalScale;

    final double width = (27.75 * finalScale) + 16.0;
    final double height = isSelected
        ? (30.833 * finalScale) + gap + (dotRadius * 2) + 16.0
        : (30.833 * finalScale) + 16.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(dpr);

    final Path path = Path();
    path.moveTo(dx + 13.875 * finalScale, dy);
    path.cubicTo(
      dx + 21.538 * finalScale,
      dy,
      dx + 27.75 * finalScale,
      dy + 6.13575 * finalScale,
      dx + 27.75 * finalScale,
      dy + 13.7041 * finalScale,
    );
    path.cubicTo(
      dx + 27.7497 * finalScale,
      dy + 21.2724 * finalScale,
      dx + 19.078 * finalScale,
      dy + 30.833 * finalScale,
      dx + 13.875 * finalScale,
      dy + 30.833 * finalScale,
    );
    path.cubicTo(
      dx + 8.67197 * finalScale,
      dy + 30.833 * finalScale,
      dx + 0.000303757 * finalScale,
      dy + 21.2724 * finalScale,
      dx,
      dy + 13.7041 * finalScale,
    );
    path.cubicTo(
      dx,
      dy + 6.13575 * finalScale,
      dx + 6.21205 * finalScale,
      dy,
      dx + 13.875 * finalScale,
      dy,
    );
    path.close();

    // 1. Draw Shadow for teardrop pin
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(path, shadowPaint);

    final color = getMarkerColor(type);

    // 2. Draw Teardrop pin (Fill)
    final Paint fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);

    // 3. Draw White Border around teardrop pin
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * finalScale;
    canvas.drawPath(path, borderPaint);

    // 4. Draw White Icon inside teardrop pin circular head
    final double iconCx = dx + 13.875 * finalScale;
    final double iconCy = dy + 13.7 * finalScale;

    final iconData = getIconDataForType(type);
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: (isSelected ? 14.5 : 12.0) * finalScale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(iconCx - textPainter.width / 2, iconCy - textPainter.height / 2),
    );

    if (isSelected) {
      // 5. Draw Bottom Dot Shadow
      final double dotCx = iconCx;
      final double tipY = dy + 30.833 * finalScale;
      final double dotCy = tipY + gap + dotRadius;

      final Paint dotShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(Offset(dotCx, dotCy + 1.0), dotRadius, dotShadowPaint);

      // 6. Draw Bottom Dot Fill
      final Paint dotFillPaint = Paint()..color = color;
      canvas.drawCircle(Offset(dotCx, dotCy), dotRadius, dotFillPaint);

      // 7. Draw Bottom Dot Border
      final Paint dotBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * finalScale;
      canvas.drawCircle(Offset(dotCx, dotCy), dotRadius, dotBorderPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage((width * dpr).toInt(), (height * dpr).toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  static Future<Uint8List> _generateDotPin(String type) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;
    
    const double size = 16.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    canvas.scale(dpr);
    
    final color = getMarkerColor(type);
    
    final bgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(8.0, 8.0), 5.0, bgPaint);
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(8.0, 8.0), 5.0, borderPaint);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage((size * dpr).toInt(), (size * dpr).toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  static IconData getIconDataForType(String type) {
    final String t = type.toLowerCase().trim();
    if (t.contains('movie') || t.contains('cinema')) return Icons.movie;
    if (t.contains('sports') || t.contains('stadium') || t.contains('arena') || t.contains('soccer') || t.contains('gym')) return Icons.sports_soccer;
    if (t.contains('concert') || t.contains('music') || t.contains('gig')) return Icons.music_note;
    if (t.contains('restaurant') || t.contains('food') || t.contains('dining')) return Icons.restaurant;
    if (t.contains('coffee') || t.contains('cafe') || t.contains('café')) return Icons.local_cafe;
    if (t.contains('dessert') || t.contains('sweets') || t.contains('chocolate') || t.contains('pastry') || t.contains('cake')) return Icons.cake;
    if (t.contains('bar') || t.contains('pub') || t.contains('club')) return Icons.local_bar;
    if (t.contains('airport') || t.contains('flight') || t.contains('plane')) return Icons.local_airport;
    if (t.contains('hotel') || t.contains('motel') || t.contains('resort') || t.contains('bed') || t.contains('room') || t.contains('stay')) return Icons.king_bed;
    if (t.contains('supermarket') || t.contains('shopping') || t.contains('mall') || t.contains('store') || t.contains('shop')) return Icons.storefront;
    if (t.contains('bakery') || t.contains('bread') || t.contains('mkhbazat')) return Icons.bakery_dining;
    if (t.contains('ticket') || t.contains('event') || t.contains('activity') || t.contains('show')) return Icons.local_activity;
    if (t.contains('park') || t.contains('garden') || t.contains('playground')) return Icons.park;
    if (t.contains('pharmacy') || t.contains('drugstore')) return Icons.local_pharmacy;
    if (t.contains('hospital') || t.contains('clinic') || t.contains('doctor') || t.contains('medical')) return Icons.local_hospital;
    if (t.contains('bank')) return Icons.account_balance;
    if (t.contains('atm')) return Icons.local_atm;
    if (t.contains('school') || t.contains('university') || t.contains('college') || t.contains('academy') || t.contains('education')) return Icons.school;
    if (t.contains('mosque') || t.contains('masjid')) return Icons.mosque;
    if (t.contains('church')) return Icons.church;
    if (t.contains('gas') || t.contains('petrol') || t.contains('fuel')) return Icons.local_gas_station;
    if (t.contains('museum') || t.contains('art') || t.contains('gallery')) return Icons.museum;
    if (t.contains('parking')) return Icons.local_parking;
    return Icons.square;
  }

  static Color getMarkerColor(String type) {
    final String t = type.toLowerCase().trim();
    if (t.contains('movie') || t.contains('cinema')) {
      return const Color(0xFFCB3D8D); // Pink
    }
    if (t.contains('sports') || t.contains('stadium') || t.contains('arena') || t.contains('soccer') || t.contains('gym')) {
      return const Color(0xFF388E3C); // Sports Green
    }
    if (t.contains('concert') || t.contains('music') || t.contains('gig')) {
      return const Color(0xFF00B0FF); // Concerts Sky Blue
    }
    if (t.contains('restaurant') || t.contains('food') || t.contains('dining')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('coffee') || t.contains('cafe') || t.contains('café') || t.contains('local_cafe')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('dessert') || t.contains('sweets') || t.contains('chocolate') || t.contains('pastry') || t.contains('cake')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('bar') || t.contains('pub') || t.contains('club') || t.contains('nightlife')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('hotel') || t.contains('motel') || t.contains('resort') || t.contains('bed') || t.contains('stay') || t.contains('room')) {
      return const Color(0xFF3498DB); // Blue for Hotels
    }
    if (t.contains('parking')) {
      return const Color(0xFF3649E1); // Blue for Parking
    }
    return const Color(0xFF5A5D67); // Grey default
  }
}
