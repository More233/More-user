import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MarkerGenerator {
  final Map<String, BitmapDescriptor> normalMarkerIcons = {};
  final Map<String, BitmapDescriptor> selectedMarkerIcons = {};
  /// Large colored circle icons with white icon inside (Live Now / heatmap mode, zoom >= 15)
  final Map<String, BitmapDescriptor> heatmapCircleIcons = {};
  /// Compact teardrop icons for heatmap fallback
  final Map<String, BitmapDescriptor> heatmapMarkerIcons = {};
  /// Small colored dot markers for far zoom (< 15)
  final Map<String, BitmapDescriptor> dotMarkerIcons = {};
  /// Small dots in each type's color for heatmap far zoom
  final Map<String, BitmapDescriptor> heatmapDotIcons = {};
  final Map<String, BitmapDescriptor> networkIconsNormalCache = {};
  final Map<String, BitmapDescriptor> networkIconsSelectedCache = {};
  final Map<String, BitmapDescriptor> avatarMarkerCache = {};
  final Map<String, Uint8List> iconBytesCache = {};
  final Map<String, BitmapDescriptor> customPlaceMarkersNormal = {};
  final Map<String, BitmapDescriptor> customPlaceMarkersSelected = {};
  final Map<String, BitmapDescriptor> customPlaceMarkersNormalHeatmap = {};
  final Map<String, BitmapDescriptor> customPlaceMarkersSelectedHeatmap = {};
  bool iconsLoaded = false;

  Future<BitmapDescriptor> createTeardropIcon(
    IconData iconData,
    Color color, {
    required bool isSelected,
    double scale = 1.0,
  }) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final double finalScale = 0.85 * scale;
    final double width = 27.75 * finalScale + 4.0;
    final double height = 30.833 * finalScale + 4.0;

    // Scale canvas by device pixel ratio to draw in high DPI
    canvas.scale(dpr);

    final double dx = 2.0;
    final double dy = 2.0;

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

    final Paint paint = Paint()..color = color;
    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * finalScale;
    canvas.drawPath(path, borderPaint);

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 12.0 * finalScale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        dx + 13.875 * finalScale - textPainter.width / 2,
        dy + 13.7041 * finalScale - textPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      (width * dpr).toInt(),
      (height * dpr).toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    final Uint8List uint8list = byteData.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
  }

  /// Small dot for far-zoom view
  Future<BitmapDescriptor> createCircularDotIcon(
    Color color, {
    double scale = 1.0,
  }) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final double radius = 7.0 * scale;
    final double width = (radius * 2) + 4.0;
    final double height = (radius * 2) + 4.0;

    canvas.scale(dpr);

    final double cx = radius + 2.0;
    final double cy = radius + 2.0;

    // Subtle shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset(cx, cy + 1.0), radius, shadowPaint);

    // Fill
    final Paint fillPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // White border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      (width * dpr).toInt(),
      (height * dpr).toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    final Uint8List uint8list = byteData.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
  }

  /// Large circle icon with white icon inside — used for Live Now / heatmap close zoom (Figma 32px style)
  Future<BitmapDescriptor> createLiveNowCircleIcon(
    IconData iconData,
    Color color, {
    double scale = 1.0,
  }) async {
    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Figma size: 32px circle. We scale it.
    final double radius = 16.0 * scale;
    final double size = (radius * 2) + 6.0;

    canvas.scale(dpr);

    final double cx = radius + 3.0;
    final double cy = radius + 3.0;

    // Outer glow ring (semi-transparent)
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius + 4.0, glowPaint);

    // Fill circle
    final Paint fillPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // White border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // White icon inside
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 14.0 * scale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      (size * dpr).toInt(),
      (size * dpr).toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    final Uint8List uint8list = byteData.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
  }

  Future<BitmapDescriptor?> downloadAndProcessNetworkIcon(
    String url,
    String? bgColorStr, {
    required bool isSelected,
  }) async {
    try {
      Uint8List bytes;
      if (iconBytesCache.containsKey(url)) {
        bytes = iconBytesCache[url]!;
      } else {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          debugPrint("Failed to download network icon from $url: ${response.statusCode}");
          return null;
        }
        bytes = response.bodyBytes;
        iconBytesCache[url] = bytes;
      }

      final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
      final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

      final int iconSize = 14;
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: (iconSize * dpr).toInt(),
        targetHeight: (iconSize * dpr).toInt(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image iconImage = fi.image;

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      final double finalScale = 0.85;
      final double width = 27.75 * finalScale + 4.0;
      final double height = 30.833 * finalScale + 4.0;

      canvas.scale(dpr);

      final double dx = 2.0;
      final double dy = 2.0;

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

      Color color = const Color(0xFF7C57FC); // Default Purple
      if (bgColorStr != null && bgColorStr.startsWith('#')) {
        final hex = bgColorStr.substring(1);
        final intVal = int.tryParse(hex, radix: 16);
        if (intVal != null) {
          color = Color(0xFF000000 | intVal);
        }
      }

      final Paint paint = Paint()..color = color;
      canvas.drawPath(path, paint);

      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * finalScale;
      canvas.drawPath(path, borderPaint);

      final Paint iconPaint = Paint()
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcIn);

      canvas.drawImageRect(
        iconImage,
        Rect.fromLTWH(0, 0, iconImage.width.toDouble(), iconImage.height.toDouble()),
        Rect.fromLTWH(
          dx + 13.875 * finalScale - iconSize / 2,
          dy + 13.7041 * finalScale - iconSize / 2,
          iconSize.toDouble(),
          iconSize.toDouble(),
        ),
        iconPaint,
      );

      final ui.Image markerImage = await pictureRecorder.endRecording().toImage(
        (width * dpr).toInt(),
        (height * dpr).toInt(),
      );
      final ByteData? markerByteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      if (markerByteData == null) return null;
      return BitmapDescriptor.bytes(markerByteData.buffer.asUint8List(), imagePixelRatio: dpr);
    } catch (e) {
      debugPrint("Error creating network marker for $url: $e");
      return null;
    }
  }

  Future<void> preloadNetworkIconsForPlaces(
    List<Map<String, dynamic>> places,
    VoidCallback onUpdate,
  ) async {
    bool needsUpdate = false;
    for (final place in places) {
      final iconUrl = place['iconUrl'] as String?;
      if (iconUrl == null || iconUrl.isEmpty) continue;
      if (networkIconsNormalCache.containsKey(iconUrl)) continue;

      final type = place['type'] as String? ?? 'Other';
      final markerColor = getMarkerColor(type);
      final bgColorHex = '#${markerColor.toARGB32().toRadixString(16).substring(2)}';

      final normalMarker = await downloadAndProcessNetworkIcon(
        iconUrl,
        bgColorHex,
        isSelected: false,
      );
      final selectedMarker = await downloadAndProcessNetworkIcon(
        iconUrl,
        bgColorHex,
        isSelected: true,
      );
      if (normalMarker != null && selectedMarker != null) {
        networkIconsNormalCache[iconUrl] = normalMarker;
        networkIconsSelectedCache[iconUrl] = selectedMarker;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      onUpdate();
    }
  }

  IconData getIconDataForType(String type) {
    final String t = type.toLowerCase().trim();
    if (t.contains('restaurant') || t.contains('food') || t.contains('dining')) return Icons.restaurant;
    if (t.contains('coffee') || t.contains('cafe') || t.contains('café')) return Icons.local_cafe;
    if (t.contains('dessert') || t.contains('sweets') || t.contains('chocolate') || t.contains('pastry')) return Icons.cake;
    if (t.contains('bar') || t.contains('pub') || t.contains('club')) return Icons.local_bar;
    if (t.contains('airport') || t.contains('flight') || t.contains('plane')) return Icons.local_airport;
    if (t.contains('hotel') || t.contains('motel') || t.contains('resort') || t.contains('bed')) return Icons.king_bed;
    if (t.contains('supermarket') || t.contains('shopping') || t.contains('mall') || t.contains('store') || t.contains('shop')) return Icons.storefront;
    if (t.contains('bakery') || t.contains('bread') || t.contains('mkhbazat')) return Icons.bakery_dining;
    if (t.contains('ticket') || t.contains('event') || t.contains('activity') || t.contains('show')) return Icons.local_activity;
    if (t.contains('park') || t.contains('garden') || t.contains('playground')) return Icons.park;
    if (t.contains('pharmacy') || t.contains('hospital') || t.contains('clinic')) return Icons.local_pharmacy;
    return Icons.location_on;
  }

  Color getMarkerColor(String type) {
    final String t = type.toLowerCase().trim();
    if (t.contains('restaurant') || t.contains('food') || t.contains('dining')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('coffee') || t.contains('cafe') || t.contains('café') || t.contains('local_cafe')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('dessert') || t.contains('sweets') || t.contains('chocolate') || t.contains('pastry')) {
      return const Color(0xFFE96D2B); // Orange
    }
    if (t.contains('bar') || t.contains('pub') || t.contains('club') || t.contains('nightlife')) {
      return const Color(0xFFE96D2B); // Orange
    }
    
    if (t.contains('airport') || t.contains('flight') || t.contains('plane')) {
      return const Color(0xFF3649E1); // Blue
    }
    if (t.contains('hotel') || t.contains('booking') || t.contains('motel') || t.contains('resort') || t.contains('stay') || t.contains('bed')) {
      return const Color(0xFF3649E1); // Blue
    }
    if (t.contains('supermarket') || t.contains('shopping') || t.contains('mall') || t.contains('store') || t.contains('shop')) {
      return const Color(0xFF3649E1); // Blue
    }
    
    if (t.contains('bakery') || t.contains('mkhbazat') || t.contains('bread')) {
      return const Color(0xFF7C57FC); // Purple/Violet
    }
    
    if (t.contains('ticket') ||
        t.contains('event') ||
        t.contains('activity') ||
        t.contains('show') ||
        t.contains('cinema') ||
        t.contains('theater') ||
        t.contains('movie') ||
        t.contains('museum') ||
        t.contains('entertainment')) {
      return const Color(0xFFCB3D8D); // Pink
    }
    
    if (t.contains('park') || t.contains('garden') || t.contains('playground')) {
      return const Color(0xFF017346); // Green
    }
    
    if (t.contains('pharmacy') || t.contains('hospital') || t.contains('clinic')) {
      return const Color(0xFF5A5D67); // Grey
    }
    
    return const Color(0xFF5A5D67); // Grey default
  }

  Future<void> initMarkerIcons({double zoom = 13.0, required VoidCallback onUpdate}) async {
    try {
      final types = [
        'Coffee',
        'Restaurant',
        'Park',
        'Ticket',
        'Airport',
        'Bars',
        'Pharmacy',
        'Hotel',
        'Supermarket',
        'Bakery',
        'default',
      ];
      final double scale = (zoom / 13.0).clamp(0.6, 1.8);

      for (final type in types) {
        final IconData iconData = getIconDataForType(type);
        final Color color = getMarkerColor(type);

        normalMarkerIcons[type] = await createTeardropIcon(
          iconData,
          color,
          isSelected: false,
          scale: scale,
        );
        selectedMarkerIcons[type] = await createTeardropIcon(
          iconData,
          color,
          isSelected: true,
          scale: scale,
        );
        heatmapMarkerIcons[type] = await createTeardropIcon(
          iconData,
          const Color(0xFF7C57FC),
          isSelected: false,
          scale: scale,
        );
        dotMarkerIcons[type] = await createCircularDotIcon(
          color,
          scale: scale * 0.9,
        );
        // Live Now close-zoom: large circle icon in each type's own color (not all purple)
        heatmapCircleIcons[type] = await createLiveNowCircleIcon(
          iconData,
          const Color(0xFF7C57FC),
          scale: scale,
        );
        // Live Now far-zoom: small dot in each type's own color
        heatmapDotIcons[type] = await createCircularDotIcon(
          const Color(0xFF7C57FC),
          scale: scale * 0.9,
        );
      }

      iconsLoaded = true;
      onUpdate();
    } catch (e) {
      debugPrint("Error creating custom marker icons: $e");
    }
  }

  Future<BitmapDescriptor> createUserAvatarMarker(String url) async {
    if (avatarMarkerCache.containsKey(url)) {
      return avatarMarkerCache[url]!;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Failed to fetch");
      final Uint8List bytes = response.bodyBytes;

      final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
      final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

      final double finalScale = 0.85;
      final double width = 27.75 * finalScale + 4.0;
      final double height = 30.833 * finalScale + 4.0;
      final double dx = 2.0;
      final double dy = 2.0;

      final int avatarSize = (22.0 * finalScale * dpr).toInt();
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: avatarSize,
        targetHeight: avatarSize,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image avatarImage = fi.image;

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

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

      final Paint paint = Paint()..color = const Color(0xFF7C57FC);
      canvas.drawPath(path, paint);

      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * finalScale;
      canvas.drawPath(path, borderPaint);

      canvas.save();
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(dx + 13.875 * finalScale, dy + 13.7041 * finalScale),
          radius: 11.0 * finalScale,
        ));
      canvas.clipPath(clipPath);

      canvas.drawImageRect(
        avatarImage,
        Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble()),
        Rect.fromCircle(
          center: Offset(dx + 13.875 * finalScale, dy + 13.7041 * finalScale),
          radius: 11.0 * finalScale,
        ),
        Paint(),
      );
      canvas.restore();

      final ui.Image markerImage = await pictureRecorder.endRecording().toImage(
        (width * dpr).toInt(),
        (height * dpr).toInt(),
      );
      final ByteData? markerByteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      if (markerByteData == null) return BitmapDescriptor.defaultMarker;
      final descriptor = BitmapDescriptor.bytes(markerByteData.buffer.asUint8List(), imagePixelRatio: dpr);
      avatarMarkerCache[url] = descriptor;
      return descriptor;
    } catch (e) {
      debugPrint("Error creating avatar marker for $url: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> preloadCheckInAvatars(
    List<Map<String, dynamic>> checkins,
    VoidCallback onUpdate,
  ) async {
    for (final c in checkins) {
      final avatarUrl = c['authorAvatar'] as String?;
      if (avatarUrl == null || avatarUrl.isEmpty) continue;
      if (avatarMarkerCache.containsKey(avatarUrl)) continue;
      await createUserAvatarMarker(avatarUrl);
    }
    onUpdate();
  }

  void clearPlaceMarkersCache() {
    customPlaceMarkersNormal.clear();
    customPlaceMarkersSelected.clear();
    customPlaceMarkersNormalHeatmap.clear();
    customPlaceMarkersSelectedHeatmap.clear();
  }

  Future<void> preloadPlaceMarkers(
    List<Map<String, dynamic>> places,
    VoidCallback onUpdate,
  ) async {
    bool needsUpdate = false;
    for (final place in places) {
      final String id = place['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      
      // Standard custom markers
      if (!customPlaceMarkersNormal.containsKey(id)) {
        final normalMarker = await createMarkerWithLabel(place: place, isSelected: false);
        customPlaceMarkersNormal[id] = normalMarker;
        needsUpdate = true;
      }
      if (!customPlaceMarkersSelected.containsKey(id)) {
        final selectedMarker = await createMarkerWithLabel(place: place, isSelected: true);
        customPlaceMarkersSelected[id] = selectedMarker;
        needsUpdate = true;
      }

      // Heatmap custom markers (All purple)
      if (!customPlaceMarkersNormalHeatmap.containsKey(id)) {
        final normalMarker = await createMarkerWithLabel(place: place, isSelected: false, isHeatmap: true);
        customPlaceMarkersNormalHeatmap[id] = normalMarker;
        needsUpdate = true;
      }
      if (!customPlaceMarkersSelectedHeatmap.containsKey(id)) {
        final selectedMarker = await createMarkerWithLabel(place: place, isSelected: true, isHeatmap: true);
        customPlaceMarkersSelectedHeatmap[id] = selectedMarker;
        needsUpdate = true;
      }
    }
    if (needsUpdate) {
      onUpdate();
    }
  }

  Future<BitmapDescriptor> createMarkerWithLabel({
    required Map<String, dynamic> place,
    required bool isSelected,
    bool isHeatmap = false,
  }) async {
    final String name = place['name']?.toString() ?? '';
    final type = place['type']?.toString() ?? 'Other';
    final double rating = (place['rating'] as num?)?.toDouble() ?? 4.0;
    final int peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
    final String price = place['price']?.toString() ?? r'$$';

    final IconData iconData = getIconDataForType(type);
    final Color color = isHeatmap ? const Color(0xFF7C57FC) : getMarkerColor(type);

    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    if (isHeatmap) {
      // Swarm design: Circle icon at top (purple fill, white icon, glow ring),
      // and text (place name + visitors count) centered directly below it.
      final double finalScale = isSelected ? 1.1 : 0.9;
      final double radius = 16.0 * finalScale;
      final double glowRadius = radius + 4.0;
      
      final double canvasWidth = 150.0;
      final double cx = canvasWidth / 2;
      final double cy = glowRadius + 4.0; // Top circle center

      // Prepare texts
      final TextPainter namePainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
        ellipsis: '...',
      );
      namePainter.text = TextSpan(
        text: name,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF7C57FC),
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(1.0, 1.0),
            ),
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(-1.0, -1.0),
            ),
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(1.0, -1.0),
            ),
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(-1.0, 1.0),
            ),
          ],
        ),
      );
      namePainter.layout(maxWidth: canvasWidth - 16.0);

      final String visitorsText = peopleCount == 1 ? "1 person here" : "$peopleCount people here";
      final TextPainter visitorsPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      );
      visitorsPainter.text = TextSpan(
        text: visitorsText,
        style: TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCB3D8D),
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(1.0, 1.0),
            ),
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(-1.0, -1.0),
            ),
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(1.0, -1.0),
            ),
            Shadow(
              blurRadius: 4.0,
              color: Colors.white,
              offset: const Offset(-1.0, 1.0),
            ),
          ],
        ),
      );
      visitorsPainter.layout(maxWidth: canvasWidth - 16.0);

      final double textSpacing = 4.0;
      final double textTop = cy + glowRadius + 6.0;
      final double canvasHeight = textTop + namePainter.height + textSpacing + visitorsPainter.height + 8.0;

      canvas.scale(dpr);

      // 1. Draw Glow Ring
      final Paint glowPaint = Paint()
        ..color = const Color(0xFF7C57FC).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), glowRadius, glowPaint);

      // 2. Draw Fill Circle
      final Paint fillPaint = Paint()..color = const Color(0xFF7C57FC);
      canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

      // 3. Draw White Border
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * finalScale;
      canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

      // 4. Draw White Icon inside
      final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
      iconPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 14.0 * finalScale,
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

      // 5. Paint texts centered below the circle icon
      namePainter.paint(canvas, Offset(cx - namePainter.width / 2, textTop));
      visitorsPainter.paint(
        canvas,
        Offset(cx - visitorsPainter.width / 2, textTop + namePainter.height + textSpacing),
      );

      final ui.Image image = await pictureRecorder.endRecording().toImage(
        (canvasWidth * dpr).toInt(),
        (canvasHeight * dpr).toInt(),
      );
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return BitmapDescriptor.defaultMarker;
      final Uint8List uint8list = byteData.buffer.asUint8List();
      return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
    }

    final bool isCheckIn = place['isCheckIn'] as bool? ?? false;


    // If it's a standard venue (not a checkin post) and has a rating, draw speech bubble / circular pin
    if (!isCheckIn && rating > 0.0) {
      if (isSelected) {
        // Draw the large Circular icon pin (e.g. for selected venue)
        final double canvasWidth = 56.0;
        final double canvasHeight = 56.0;
        final double cx = 28.0;
        final double cy = 28.0;

        canvas.scale(dpr);

        // 1. Draw outer shadow/glow
        final Paint glowPaint = Paint()
          ..color = const Color(0xFFE05638).withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), 26.0, glowPaint);

        // 2. Draw outer white circle
        final Paint outerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), 22.0, outerPaint);

        // 3. Draw inner orange/red circle
        final Paint innerPaint = Paint()
          ..color = const Color(0xFFE05638)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), 18.0, innerPaint);

        // 4. Draw white icon in center
        final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
        iconPainter.text = TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: 16.0,
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

        final ui.Image image = await pictureRecorder.endRecording().toImage(
          (canvasWidth * dpr).toInt(),
          (canvasHeight * dpr).toInt(),
        );
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return BitmapDescriptor.defaultMarker;
        final Uint8List uint8list = byteData.buffer.asUint8List();
        return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
      } else {
        // Draw the Rating Speech Bubble (e.g. 🍴 8.9)
        final double canvasWidth = 64.0;
        final double canvasHeight = 42.0;

        canvas.scale(dpr);

        final paint = Paint()
          ..color = const Color(0xFFE05638)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        // Draw speech bubble rounded rect
        final RRect rrect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 2, 60, 28),
          const Radius.circular(14),
        );
        canvas.drawRRect(rrect, paint);
        canvas.drawRRect(rrect, borderPaint);

        // Draw pointer triangle at bottom center (x=32)
        final path = Path()
          ..moveTo(27, 30)
          ..lineTo(37, 30)
          ..lineTo(32, 36)
          ..close();
        canvas.drawPath(path, paint);
        
        // Stroke only bottom parts of the pointer to blend nicely
        final pointerStroke = Path()
          ..moveTo(27, 30)
          ..lineTo(32, 36)
          ..lineTo(37, 30);
        canvas.drawPath(pointerStroke, borderPaint);

        // Draw White Icon on the left
        final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
        iconPainter.text = TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: 12.0,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.white,
          ),
        );
        iconPainter.layout();
        iconPainter.paint(canvas, Offset(8, 16 - iconPainter.height / 2));

        // Draw Rating Text on the right
        final String ratingStr = rating.toStringAsFixed(1);
        final TextPainter ratingPainter = TextPainter(textDirection: TextDirection.ltr);
        ratingPainter.text = TextSpan(
          text: ratingStr,
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
        ratingPainter.layout();
        ratingPainter.paint(canvas, Offset(28, 16 - ratingPainter.height / 2));

        final ui.Image image = await pictureRecorder.endRecording().toImage(
          (canvasWidth * dpr).toInt(),
          (canvasHeight * dpr).toInt(),
        );
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return BitmapDescriptor.defaultMarker;
        final Uint8List uint8list = byteData.buffer.asUint8List();
        return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
      }
    }

    final double finalScale = isSelected ? 1.1 : 0.9;
    final double pinWidth = 27.75 * finalScale;
    final double pinHeight = 30.833 * finalScale;
    
    // Text block dimensions
    final double textWidth = 120.0;
    final double spacing = 8.0;
    final double canvasWidth = textWidth + spacing + pinWidth + 8.0;
    final double canvasHeight = pinHeight + 16.0;

    canvas.scale(dpr);

    // Pin is on the right
    final double pinDx = textWidth + spacing + 4.0;
    final double pinDy = 4.0;

    // 1. Draw Teardrop Pin
    final Path path = Path();
    path.moveTo(pinDx + 13.875 * finalScale, pinDy);
    path.cubicTo(
      pinDx + 21.538 * finalScale,
      pinDy,
      pinDx + 27.75 * finalScale,
      pinDy + 6.13575 * finalScale,
      pinDx + 27.75 * finalScale,
      pinDy + 13.7041 * finalScale,
    );
    path.cubicTo(
      pinDx + 27.7497 * finalScale,
      pinDy + 21.2724 * finalScale,
      pinDx + 19.078 * finalScale,
      pinDy + 30.833 * finalScale,
      pinDx + 13.875 * finalScale,
      pinDy + 30.833 * finalScale,
    );
    path.cubicTo(
      pinDx + 8.67197 * finalScale,
      pinDy + 30.833 * finalScale,
      pinDx + 0.000303757 * finalScale,
      pinDy + 21.2724 * finalScale,
      pinDx,
      pinDy + 13.7041 * finalScale,
    );
    path.cubicTo(
      pinDx,
      pinDy + 6.13575 * finalScale,
      pinDx + 6.21205 * finalScale,
      pinDy,
      pinDx + 13.875 * finalScale,
      pinDy,
    );
    path.close();

    final Paint paint = Paint()..color = color;
    canvas.drawPath(path, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * finalScale;
    canvas.drawPath(path, borderPaint);

    // Draw Icon inside Teardrop
    final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 12.0 * finalScale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        pinDx + 13.875 * finalScale - iconPainter.width / 2,
        pinDy + 13.7041 * finalScale - iconPainter.height / 2,
      ),
    );

    // 2. Draw Text Details on the Left — directly (no white pill background)
    // Prepare texts
    final TextPainter namePainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '...',
    );
    namePainter.text = TextSpan(
      text: name,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    namePainter.layout(maxWidth: textWidth);

    // Line 2: People count  (e.g. "29 people here")
    final TextPainter visitorsPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    visitorsPainter.text = TextSpan(
      text: peopleCount > 0 ? "$peopleCount people here" : "",
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
    visitorsPainter.layout(maxWidth: textWidth);

    // Line 3: Price & Rating
    final TextPainter ratingPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    ratingPainter.text = TextSpan(
      children: [
        TextSpan(
          text: price,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (price.isNotEmpty)
          TextSpan(
            text: ' . ',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        const TextSpan(
          text: '★',
          style: TextStyle(
            fontSize: 9.5,
            color: Color(0xFFFFC107),
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: '(${rating.toStringAsFixed(1)})',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
    ratingPainter.layout(maxWidth: textWidth);

    // Position text area vertically centered relative to pin
    final double textHeight = namePainter.height +
        (peopleCount > 0 ? visitorsPainter.height + 2.0 : 0.0) +
        ratingPainter.height +
        2.0;
    final double textTop = pinDy + (pinHeight / 2) - (textHeight / 2);
    final double textLeft = 4.0;

    // Paint the texts directly onto the canvas
    double currentY = textTop;

    namePainter.paint(canvas, Offset(textLeft, currentY));
    currentY += namePainter.height + 2.0;

    if (peopleCount > 0) {
      visitorsPainter.paint(canvas, Offset(textLeft, currentY));
      currentY += visitorsPainter.height + 2.0;
    }

    ratingPainter.paint(canvas, Offset(textLeft, currentY));

    // Convert Canvas to Image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      (canvasWidth * dpr).toInt(),
      (canvasHeight * dpr).toInt(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    final Uint8List uint8list = byteData.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8list, imagePixelRatio: dpr);
  }
}
