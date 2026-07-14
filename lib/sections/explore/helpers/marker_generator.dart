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
    const double dx = 10.0;
    const double dy = 8.0;

    final double gap = 4.0 * finalScale;
    final double dotRadius = 3.8 * finalScale;

    final double width = (30.0 * finalScale) + 20.0;
    final double height = isSelected
        ? (34.0 * finalScale) + gap + (dotRadius * 2) + 20.0
        : (34.0 * finalScale) + 20.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(dpr);

    final Path path = Path();
    path.moveTo(dx + 15.0 * finalScale, dy + 34.0 * finalScale); // Start at bottom tip (shortened to 34)
    path.lineTo(dx + 5.8 * finalScale, dy + 26.8 * finalScale); // Line to left tangent point
    path.arcTo(
      Rect.fromCircle(
        center: Offset(dx + 15.0 * finalScale, dy + 15.0 * finalScale),
        radius: 15.0 * finalScale,
      ),
      3.14159265 - 0.9099,
      3.14159265 + 2 * 0.9099,
      false,
    ); // Arc clockwise over the top to right tangent point
    path.close(); // Line back to bottom tip automatically

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
      ..strokeWidth = 3.0 * finalScale;
    canvas.drawPath(path, borderPaint);

    // 4. Draw White Icon inside teardrop pin circular head
    final double iconCx = dx + 15.0 * finalScale;
    final double iconCy = dy + 15.0 * finalScale;

    final iconData = getIconDataForType(type);
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: (isSelected ? 16.0 : 13.0) * finalScale,
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
      final double tipY = dy + 34.0 * finalScale;
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
    
    const double size = 18.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    canvas.scale(dpr);
    
    final color = getMarkerColor(type);
    
    final bgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(9.0, 9.0), 6.5, bgPaint);
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(const Offset(9.0, 9.0), 6.5, borderPaint);
    
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
    if (t.contains('library') || t.contains('book')) return Icons.local_library;
    if (t.contains('exhibition') || t.contains('exhibit') || t.contains('business')) return Icons.business;
    if (t.contains('parking')) return Icons.local_parking;
    return Icons.square;
  }

  static Color getMarkerColor(String type) {
    final String t = type.toLowerCase().trim();
    if (t.contains('movie') || t.contains('cinema')) {
      return const Color(0xFFCB3D8D); // Pink
    }
    if (t.contains('park') || t.contains('garden') || t.contains('playground') ||
        t.contains('sports') || t.contains('stadium') || t.contains('arena') || t.contains('soccer') || t.contains('gym')) {
      return const Color(0xFF1B8A5A); // Swarm Green
    }
    if (t.contains('concert') || t.contains('music') || t.contains('gig')) {
      return const Color(0xFF00B0FF); // Concerts Sky Blue
    }
    if (t.contains('coffee') || t.contains('cafe') || t.contains('café') || t.contains('local_cafe')) {
      return const Color(0xFFFF5A19); // Swarm Food Orange-Red (Same as restaurant)
    }
    if (t.contains('restaurant') || t.contains('food') || t.contains('dining') ||
        t.contains('bakery') || t.contains('bread') || t.contains('mkhbazat') ||
        t.contains('dessert') || t.contains('sweets') || t.contains('chocolate') || t.contains('pastry') || t.contains('cake') ||
        t.contains('pizza') || t.contains('pizzeria') || t.contains('bar') || t.contains('pub') || t.contains('club') || t.contains('nightlife')) {
      return const Color(0xFFFF5A19); // Swarm Food Orange-Red
    }
    if (t.contains('hotel') || t.contains('motel') || t.contains('resort') || t.contains('bed') || t.contains('stay') || t.contains('room') ||
        t.contains('airport') || t.contains('flight') || t.contains('plane')) {
      return const Color(0xFF0066FF); // Swarm Blue
    }
    return const Color(0xFF5A5D67); // Swarm Charcoal/Grey default
  }

  static String resolveType(String rawType, String name, [String arabicName = '']) {
    final String r = rawType.toLowerCase().trim();
    final String n = name.toLowerCase();
    final String ar = arabicName.toLowerCase();
    
    // First, if the type contains any of the known categories directly:
    if (r.contains('restaurant') || r.contains('food') || r.contains('dining') || r.contains('pizza') || r.contains('burger') || r.contains('sushi')) return 'restaurant';
    if (r.contains('coffee') || r.contains('cafe') || r.contains('café')) return 'coffee';
    if (r.contains('hotel') || r.contains('motel') || r.contains('resort') || r.contains('stay') || r.contains('suites')) return 'hotel';
    if (r.contains('park') || r.contains('garden')) return 'park';
    if (r.contains('movie') || r.contains('cinema')) return 'movies';
    if (r.contains('concert') || r.contains('music') || r.contains('gig')) return 'concerts';
    if (r.contains('bar') || r.contains('pub') || r.contains('club')) return 'bars';
    if (r.contains('airport') || r.contains('flight') || r.contains('plane')) return 'airport';
    if (r.contains('bakery') || r.contains('bread')) return 'bakery';
    if (r.contains('supermarket') || r.contains('grocery') || r.contains('mall')) return 'supermarket';
    if (r.contains('pharmacy') || r.contains('drugstore')) return 'pharmacy';
    if (r.contains('school') || r.contains('university') || r.contains('college')) return 'school';
    if (r.contains('mosque') || r.contains('masjid')) return 'mosque';
    if (r.contains('library')) return 'library';
    if (r.contains('museum')) return 'museum';
    if (r.contains('exhibition') || r.contains('exhibit')) return 'exhibition';

    // Second, check the name of the place:
    if (n.contains('restaurant') || n.contains('dining') || n.contains('pizza') || n.contains('burger') || n.contains('sushi') || ar.contains('مطعم') || ar.contains('بيتزا') || ar.contains('برجر') || ar.contains('سوشي')) return 'restaurant';
    if (n.contains('coffee') || n.contains('cafe') || n.contains('café') || n.contains('espresso') || ar.contains('قهوة') || ar.contains('كافيه') || ar.contains('مقهى')) return 'coffee';
    if (n.contains('hotel') || n.contains('motel') || n.contains('resort') || n.contains('suites') || ar.contains('فندق') || ar.contains('أجنحة') || ar.contains('منتجع')) return 'hotel';
    if (n.contains('park') || n.contains('garden') || ar.contains('حديقة') || ar.contains('منتزه')) return 'park';
    if (n.contains('cinema') || n.contains('movie') || ar.contains('سينما')) return 'movies';
    if (n.contains('concert') || n.contains('theatre') || n.contains('music') || ar.contains('مسرح') || ar.contains('حفلة')) return 'concerts';
    if (n.contains('bar') || n.contains('pub') || n.contains('club') || ar.contains('نادي') || ar.contains('بار')) return 'bars';
    if (n.contains('airport') || ar.contains('مطار')) return 'airport';
    if (n.contains('bakery') || n.contains('pastry') || ar.contains('مخبز') || ar.contains('مخابز') || ar.contains('حلويات')) return 'bakery';
    if (n.contains('supermarket') || n.contains('hypermarket') || n.contains('grocery') || n.contains('mall') || ar.contains('سوبرماركت') || ar.contains('هايبرماركت') || ar.contains('بقالة') || ar.contains('مول')) return 'supermarket';
    if (n.contains('pharmacy') || ar.contains('صيدلية')) return 'pharmacy';
    if (n.contains('school') || n.contains('university') || n.contains('college') || ar.contains('مدرسة') || ar.contains('جامعة')) return 'school';
    if (n.contains('mosque') || n.contains('masjid') || ar.contains('مسجد') || ar.contains('جامع')) return 'mosque';
    if (n.contains('library') || ar.contains('مكتبة')) return 'library';
    if (n.contains('museum') || ar.contains('متحف')) return 'museum';
    if (n.contains('exhibition') || n.contains('exhibit') || ar.contains('معرض') || ar.contains('معارض')) return 'exhibition';

    return 'other';
  }
}
