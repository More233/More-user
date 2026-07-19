import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MarkerGenerator {
  static final Map<String, Uint8List> _normalPinCache = {};
  static final Map<String, Uint8List> _selectedPinCache = {};
  static final Map<String, Uint8List> _dotCache = {};

  static Future<Uint8List> getNormalPin(String type, {bool isDark = false}) async {
    final t = type.toLowerCase().trim();
    final key = "${t}_$isDark";
    if (_normalPinCache.containsKey(key)) {
      return _normalPinCache[key]!;
    }
    final bytes = await _generateTeardropPin(type, isSelected: false, isDark: isDark);
    _normalPinCache[key] = bytes;
    return bytes;
  }

  static Future<Uint8List> getSelectedPin(String type, {bool isDark = false}) async {
    final t = type.toLowerCase().trim();
    final key = "${t}_$isDark";
    if (_selectedPinCache.containsKey(key)) {
      return _selectedPinCache[key]!;
    }
    final bytes = await _generateTeardropPin(type, isSelected: true, isDark: isDark);
    _selectedPinCache[key] = bytes;
    return bytes;
  }

  static Future<Uint8List> getDotPin(String type, {bool isDark = false}) async {
    final t = type.toLowerCase().trim();
    final key = "${t}_$isDark";
    if (_dotCache.containsKey(key)) {
      return _dotCache[key]!;
    }
    final bytes = await _generateDotPin(type, isDark: isDark);
    _dotCache[key] = bytes;
    return bytes;
  }

  static final Map<String, Uint8List> _liveCache = {};

  static Future<Uint8List> getLivePin(String type, {required bool isSelected, bool isDark = false}) async {
    final key = "${type.toLowerCase().trim()}_${isSelected}_$isDark";
    if (_liveCache.containsKey(key)) {
      return _liveCache[key]!;
    }
    final bytes = await _generateLivePin(type, isSelected: isSelected, isDark: isDark);
    _liveCache[key] = bytes;
    return bytes;
  }

  static final Map<String, Uint8List> _capsuleCache = {};

  static Future<Uint8List> getCapsulePin(String type, String rating, {required bool isSelected, bool isDark = false}) async {
    final key = "${type.toLowerCase().trim()}_${rating.trim()}_${isSelected}_$isDark";
    if (_capsuleCache.containsKey(key)) {
      return _capsuleCache[key]!;
    }
    final bytes = await _generateCapsulePin(type, rating, isSelected: isSelected, isDark: isDark);
    _capsuleCache[key] = bytes;
    return bytes;
  }

  static Future<Uint8List> _generateCapsulePin(
    String type,
    String rating, {
    required bool isSelected,
    bool isDark = false,
  }) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final double scale = isSelected ? 1.15 : 0.92;
    final color = getMarkerColor(type);

    final double rectWidth = 66.0 * scale;
    final double rectHeight = 26.0 * scale;
    final double triangleHeight = 6.0 * scale;
    final double triangleWidth = 8.0 * scale;

    const double dx = 12.0;
    final double dy = triangleHeight + 10.0;

    final double width = rectWidth + 2 * dx;
    final double height = rectHeight + 2 * dy;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    final double cx = dx + rectWidth / 2;
    final double cy = dy + rectHeight / 2;

    // 1. Draw Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final Path capsulePath = Path();
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, rectWidth, rectHeight),
      Radius.circular(100.0 * scale),
    );
    capsulePath.addRRect(rrect);

    final Path trianglePath = Path()
      ..moveTo(cx - triangleWidth / 2, dy + rectHeight)
      ..lineTo(cx, dy + rectHeight + triangleHeight)
      ..lineTo(cx + triangleWidth / 2, dy + rectHeight)
      ..close();
    capsulePath.addPath(trianglePath, Offset.zero);

    canvas.drawPath(capsulePath, shadowPaint);

    // 2. Draw Fill
    final Paint fillPaint = Paint()..color = color;
    canvas.drawPath(capsulePath, fillPaint);

    // 3. Draw Border
    final Paint borderPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawPath(capsulePath, borderPaint);

    // 4. Draw White Icon (perfectly centered in the left section)
    final iconData = getIconDataForType(type);
    final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 12.5 * scale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    
    final double leftCenter = 12.0 * scale;
    iconPainter.paint(
      canvas,
      Offset(dx + leftCenter - iconPainter.width / 2, cy - iconPainter.height / 2),
    );

    // 5. Draw Divider
    final Paint dividerPaint = Paint()
      ..color = (isDark ? const Color(0xFF1E1E1E) : Colors.white).withValues(alpha: 0.5)
      ..strokeWidth = 1.0 * scale;
    canvas.drawLine(
      Offset(dx + 24.0 * scale, dy + 5.0 * scale),
      Offset(dx + 24.0 * scale, dy + rectHeight - 5.0 * scale),
      dividerPaint,
    );

    // 6. Draw Rating text (perfectly centered vertically with typographical compensation)
    final TextPainter ratingPainter = TextPainter(textDirection: TextDirection.ltr);
    ratingPainter.text = TextSpan(
      text: rating.isNotEmpty ? rating : "4.0",
      style: TextStyle(
        fontSize: 10.5 * scale,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    ratingPainter.layout();

    final double rightCenter = 45.0 * scale;
    ratingPainter.paint(
      canvas,
      Offset(dx + rightCenter - ratingPainter.width / 2, cy - ratingPainter.height / 2 - 1.0 * scale),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage((width * dpr).toInt(), (height * dpr).toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  static Future<Uint8List> _generateTeardropPin(String type, {required bool isSelected, bool isDark = false}) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;
    
    final double finalScale = isSelected ? 1.05 : 0.85;
    const double dx = 10.0;
    const double dy = 8.0;

    final color = getMarkerColor(type);



    // If selected, keep the teardrop pin shape to point exactly at the location
    final double gap = isSelected ? (4.0 * finalScale) : 0.0;
    final double dotRadius = isSelected ? (3.8 * finalScale) : 0.0;

    final double width = (30.0 * finalScale) + 20.0;
    final double height = isSelected
        ? ((34.0 * finalScale) + gap + (dotRadius * 2) + 20.0)
        : ((34.0 * finalScale) + 20.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(dpr);

    final Path path = Path();
    path.moveTo(dx + 15.0 * finalScale, dy + 34.0 * finalScale); // Start at bottom tip
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

    // 2. Draw Teardrop pin (Fill)
    final Paint fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);

    // 3. Draw Border around teardrop pin
    final Paint borderPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
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
        fontSize: 16.0 * finalScale,
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
        ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * finalScale;
      canvas.drawCircle(Offset(dotCx, dotCy), dotRadius, dotBorderPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage((width * dpr).toInt(), (height * dpr).toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  static Future<Uint8List> _generateDotPin(String type, {bool isDark = false}) async {
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
      ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
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
    if (t.contains('bar') || t.contains('pub') || t.contains('club') || t.contains('juice') || t.contains('smoothie') || t.contains('drink') || t.contains('lounge') || t.contains('juices')) return Icons.local_drink;
    if (t.contains('airport') || t.contains('flight') || t.contains('plane')) return Icons.local_airport;
    if (t.contains('hotel') || t.contains('motel') || t.contains('resort') || t.contains('bed') || t.contains('room') || t.contains('stay') || t.contains('hotels')) return Icons.king_bed;
    if (t.contains('supermarket') || t.contains('shopping') || t.contains('mall') || t.contains('store') || t.contains('shop')) return Icons.storefront;
    if (t.contains('bakery') || t.contains('bread') || t.contains('mkhbazat')) return Icons.bakery_dining;
    if (t.contains('ticket') || t.contains('event') || t.contains('activity') || t.contains('show')) return Icons.local_activity;
    if (t.contains('park') || t.contains('garden') || t.contains('playground') || t.contains('parks')) return Icons.park;
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
    
    // 1. Movies / Cinema / Tickets / Events -> Purple
    if (t.contains('movie') || t.contains('cinema') || t.contains('ticket') || t.contains('show') || t.contains('exhibition')) {
      return const Color(0xFF9C27B0); // Purple/Violet
    }

    // 2. Concerts / Music -> Fuchsia/Pink
    if (t.contains('concert') || t.contains('music') || t.contains('gig')) {
      return const Color(0xFFE91E63); // Fuchsia/Pink
    }

    // 3. Food and Coffee (restaurants, cafes, bakeries, bars, etc.) -> Orange
    if (t.contains('restaurant') || t.contains('food') || t.contains('dining') ||
        t.contains('coffee') || t.contains('cafe') || t.contains('café') ||
        t.contains('bakery') || t.contains('bread') || t.contains('mkhbazat') ||
        t.contains('dessert') || t.contains('sweets') || t.contains('chocolate') ||
        t.contains('pastry') || t.contains('cake') || t.contains('pizza') ||
        t.contains('pizzeria') || t.contains('bar') || t.contains('pub') ||
        t.contains('club') || t.contains('nightlife') || t.contains('local_cafe') ||
        t.contains('juice') || t.contains('smoothie') || t.contains('drink') ||
        t.contains('juices') || t.contains('desserts')) {
      return const Color(0xFFFF5A19); // Food & Coffee Orange
    }
    
    // 4. Parks and Sports (parks, gardens, stadium, gym, soccer) -> Green
    if (t.contains('park') || t.contains('garden') || t.contains('playground') ||
        t.contains('sports') || t.contains('stadium') || t.contains('arena') ||
        t.contains('soccer') || t.contains('gym')) {
      return const Color(0xFF1B8A5A); // Parks & Sports Green
    }
    
    // 5. Hotels and Airports (hotels, motels, resorts, airports, planes) -> Blue
    if (t.contains('hotel') || t.contains('motel') || t.contains('resort') ||
        t.contains('bed') || t.contains('stay') || t.contains('room') ||
        t.contains('airport') || t.contains('flight') || t.contains('plane')) {
      return const Color(0xFF0066FF); // Hotels & Airports Blue
    }
    
    // 6. Other/Rest -> Grey
    return const Color(0xFF9E9E9E); // Rest Grey
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
    if (r.contains('sports') || r.contains('stadium') || r.contains('gym') || r.contains('soccer') || r.contains('arena')) return 'sports';

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
    if (n.contains('stadium') || n.contains('arena') || n.contains('gym') || n.contains('sports') || n.contains('soccer') || ar.contains('ملعب') || ar.contains('صالة') || ar.contains('رياضة') || ar.contains('نادي رياض')) return 'sports';

    return 'other';
  }

  static Future<Uint8List> _generateLivePin(String type, {required bool isSelected, bool isDark = false}) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final double scale = isSelected ? 1.25 : 1.0;
    // Signature Swarm Purple Color
    const color = Color(0xFF7C57FC);

    final double radius = 12.0 * scale;
    const double dx = 10.0;
    const double dy = 10.0;

    final double width = radius * 2 + 20.0;
    final double height = radius * 2 + 20.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    final double cx = dx + radius;
    final double cy = dy + radius;

    // 1. Draw Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset(cx, cy), radius, shadowPaint);

    // 2. Draw Circle Fill
    final Paint fillPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // 3. Draw Border
    final Paint borderPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // 4. Draw White Icon (perfectly centered)
    final iconData = getIconDataForType(type);
    final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 12.0 * scale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    
    iconPainter.paint(
      canvas,
      Offset(cx - iconPainter.width / 2, cy - iconPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage((width * dpr).toInt(), (height * dpr).toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  static final Map<String, Uint8List> _calloutPinCache = {};

  static Future<Uint8List> getCheckInCalloutPin({
    required String type,
    required String? avatarUrl,
    required String authorName,
    required bool isSelected,
    bool isDark = false,
  }) async {
    final String key = "${type.toLowerCase().trim()}_${avatarUrl ?? 'placeholder'}_${authorName}_${isSelected}_$isDark";
    if (_calloutPinCache.containsKey(key)) {
      return _calloutPinCache[key]!;
    }

    try {
      final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
      final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

      final double scale = isSelected ? 1.15 : 0.95;

      final double pinScale = scale * 0.85;
      final double R = 15.0 * pinScale;
      final double gap = 4.0 * scale;
      final double boxWidth = 110.0 * scale;
      final double boxHeight = 24.0 * scale;

      // Symmetrical horizontal dimensions
      final double halfWidth = R + gap + boxWidth + 4.0;
      final double width = 2 * halfWidth;
      
      // Symmetrical vertical dimensions to align bottom tip of pin exactly at the center (cy)
      final double height = 60.0 * scale;

      final double cx = halfWidth;
      final double cy = height / 2; // Bottom tip of teardrop is anchored exactly at the center (cy)

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(dpr);

      final Color pinColor = getMarkerColor(type);

      // Position callout box to the LEFT of the pin
      final double boxRight = cx - R - gap;
      final double boxLeft = boxRight - boxWidth;
      final double boxCy = cy - 19.0 * pinScale; // Center box vertically with pin's head
      final double boxTop = boxCy - boxHeight / 2;

      final Path bubblePath = Path();
      final RRect boxRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        Radius.circular(6.0 * scale),
      );
      bubblePath.addRRect(boxRRect);

      final Path pointerPath = Path();
      // Draw a triangle pointing right towards the pin head
      pointerPath.moveTo(boxRight, boxCy - 3.5 * scale);
      pointerPath.lineTo(boxRight + gap + 0.5, boxCy); // Tip of pointer touching the pin
      pointerPath.lineTo(boxRight, boxCy + 3.5 * scale);
      pointerPath.close();

      // Merge both paths into a single unified speech bubble path
      final Path combinedPath = Path.combine(PathOperation.union, bubblePath, pointerPath);

      // 1. Draw Shadow
      canvas.drawPath(
        combinedPath.shift(const Offset(0.0, 1.0)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );

      // 2. Draw Fill
      canvas.drawPath(combinedPath, Paint()..color = isDark ? const Color(0xFF21242E) : Colors.white);

      // 3. Draw Border Stroke matching the pin's color
      canvas.drawPath(
        combinedPath,
        Paint()
          ..color = pinColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1 * scale,
      );

      final double avatarRadius = 8.0 * scale;
      final double avatarCx = boxLeft + 4.0 * scale + avatarRadius;
      final double avatarCy = boxCy;

      ui.Image? avatarImage;
      try {
        final pathOrUrl = avatarUrl != null && avatarUrl.isNotEmpty
            ? avatarUrl
            : 'assets/home/images/avatar_placeholder.png';

        Uint8List bytes;
        if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
          final file = await DefaultCacheManager().getSingleFile(pathOrUrl).timeout(const Duration(seconds: 5));
          bytes = await file.readAsBytes();
        } else {
          final data = await rootBundle.load(pathOrUrl);
          bytes = data.buffer.asUint8List();
        }

        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: (avatarRadius * 2 * dpr).toInt(),
          targetHeight: (avatarRadius * 2 * dpr).toInt(),
        );
        final frameInfo = await codec.getNextFrame();
        avatarImage = frameInfo.image;
      } catch (e) {
        debugPrint("Error loading avatar for callout: $e");
      }

      if (avatarImage != null) {
        canvas.save();
        final Path clipPath = Path()..addOval(Rect.fromCircle(center: Offset(avatarCx, avatarCy), radius: avatarRadius));
        canvas.clipPath(clipPath);

        final src = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
        final dest = Rect.fromCircle(center: Offset(avatarCx, avatarCy), radius: avatarRadius);

        canvas.drawImageRect(avatarImage, src, dest, Paint()..isAntiAlias = true);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(avatarCx, avatarCy), avatarRadius, Paint()..color = const Color(0xFFE8E8E8));
      }

      final double textLeft = avatarCx + avatarRadius + 4.0 * scale;
      final bool containsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(authorName);
      final String displayName = authorName.length > 10 ? '${authorName.substring(0, 8)}...' : authorName;
      final String textStr = containsArabic ? 'زار $displayName' : 'Visited by $displayName';

      final TextPainter textPainter = TextPainter(
        textDirection: containsArabic ? TextDirection.rtl : TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      textPainter.text = TextSpan(
        text: textStr,
        style: TextStyle(
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1F242E),
        ),
      );
      textPainter.layout(maxWidth: boxWidth - (textLeft - boxLeft) - 2.0);
      textPainter.paint(
        canvas,
        Offset(textLeft, boxCy - textPainter.height / 2),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage((width * dpr).toInt(), (height * dpr).toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      final resultBytes = pngBytes!.buffer.asUint8List();
      _calloutPinCache[key] = resultBytes;
      return resultBytes;
    } catch (e) {
      debugPrint("Error generating checkin callout pin: $e");
      return getNormalPin(type);
    }
  }

  static final Map<String, Uint8List> _checkInAvatarCache = {};

  static Future<Uint8List> getCheckInAvatarPin(String? avatarUrl, {required bool isSelected, bool isDark = false}) async {
    final String key = "${avatarUrl ?? 'placeholder'}_${isSelected}_$isDark";
    if (_checkInAvatarCache.containsKey(key)) {
      return _checkInAvatarCache[key]!;
    }

    try {
      final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
      final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

      final double scale = isSelected ? 1.25 : 1.0;
      final double radius = 18.0 * scale; // 36px diameter
      const double dx = 10.0;
      const double dy = 10.0;
      final double width = radius * 2 + 20.0;
      final double height = radius * 2 + 20.0;

      final double cx = dx + radius;
      final double cy = dy + radius;

      // Try to load avatar image
      ui.Image? avatarImage;
      try {
        final pathOrUrl = avatarUrl != null && avatarUrl.isNotEmpty
            ? avatarUrl
            : 'assets/home/images/avatar_placeholder.png';
        
        Uint8List bytes;
        if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
          final response = await http.get(Uri.parse(pathOrUrl)).timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            bytes = response.bodyBytes;
          } else {
            throw Exception("Failed to load network image");
          }
        } else {
          final data = await rootBundle.load(pathOrUrl);
          bytes = data.buffer.asUint8List();
        }
        
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: (radius * 2 * dpr).toInt(),
          targetHeight: (radius * 2 * dpr).toInt(),
        );
        final frameInfo = await codec.getNextFrame();
        avatarImage = frameInfo.image;
      } catch (e) {
        debugPrint("Error loading avatar image for pin, using fallback: $e");
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(dpr);

      // 1. Draw Shadow
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(Offset(cx, cy), radius, shadowPaint);

      // 2. Draw Black/Dark Fill
      final Paint bgPaint = Paint()..color = const Color(0xFF1E1E1E);
      canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

      // 3. Draw Avatar (clipped)
      if (avatarImage != null) {
        canvas.save();
        final Path clipPath = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius - 1.5));
        canvas.clipPath(clipPath);
        
        final src = Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble());
        final dest = Rect.fromCircle(center: Offset(cx, cy), radius: radius - 1.5);
        
        canvas.drawImageRect(avatarImage, src, dest, Paint()..isAntiAlias = true);
        canvas.restore();
      }

      // 4. Draw Border
      final Paint borderPaint = Paint()
        ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale;
      canvas.drawCircle(Offset(cx, cy), radius - 0.5, borderPaint);

      // 5. Draw Purple Checkmark Circle Overlay at bottom right
      final double offset = radius * 0.707; // cos(45) and sin(45)
      final double checkCx = cx + offset;
      final double checkCy = cy + offset;
      final double checkRadius = 6.5 * scale;

      // Draw Checkmark Circle shadow
      canvas.drawCircle(Offset(checkCx, checkCy + 0.5), checkRadius, shadowPaint);

      // Draw Checkmark Circle fill (Purple: Color(0xFF7C57FC))
      final Paint checkBgPaint = Paint()..color = const Color(0xFF7C57FC);
      canvas.drawCircle(Offset(checkCx, checkCy), checkRadius, checkBgPaint);

      // Draw Checkmark Circle border
      final Paint checkBorderPaint = Paint()
        ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale;
      canvas.drawCircle(Offset(checkCx, checkCy), checkRadius, checkBorderPaint);

      // Draw White Checkmark icon
      final TextPainter checkPainter = TextPainter(textDirection: TextDirection.ltr);
      checkPainter.text = TextSpan(
        text: '✓',
        style: TextStyle(
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      );
      checkPainter.layout();
      checkPainter.paint(
        canvas,
        Offset(checkCx - checkPainter.width / 2, checkCy - checkPainter.height / 2 - 0.5 * scale),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage((width * dpr).toInt(), (height * dpr).toInt());
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      final resultBytes = pngBytes!.buffer.asUint8List();
      _checkInAvatarCache[key] = resultBytes;
      return resultBytes;
    } catch (e) {
      debugPrint("Outer error in getCheckInAvatarPin: $e");
      // Fallback: return standard live pin
      return getLivePin("other", isSelected: isSelected, isDark: isDark);
    }
  }
}
