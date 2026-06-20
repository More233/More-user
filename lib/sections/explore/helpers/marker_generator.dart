import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MarkerGenerator {
  final Map<String, BitmapDescriptor> normalMarkerIcons = {};
  final Map<String, BitmapDescriptor> selectedMarkerIcons = {};
  final Map<String, BitmapDescriptor> heatmapMarkerIcons = {};
  final Map<String, BitmapDescriptor> networkIconsNormalCache = {};
  final Map<String, BitmapDescriptor> networkIconsSelectedCache = {};
  final Map<String, BitmapDescriptor> avatarMarkerCache = {};
  final Map<String, Uint8List> iconBytesCache = {};
  final Map<String, BitmapDescriptor> customPlaceMarkersNormal = {};
  final Map<String, BitmapDescriptor> customPlaceMarkersSelected = {};
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
    if (type == 'Restaurant') return Icons.restaurant;
    if (type == 'Coffee') return Icons.local_cafe;
    if (type == 'Park') return Icons.park;
    if (type == 'Ticket') return Icons.local_activity;
    if (type == 'Airport') return Icons.local_airport;
    if (type == 'Bars') return Icons.local_bar;
    if (type == 'Pharmacy') return Icons.local_pharmacy;
    if (type == 'Hotel') return Icons.king_bed;
    if (type == 'Supermarket') return Icons.storefront;
    if (type == 'Bakery') return Icons.bakery_dining;
    return Icons.location_on;
  }

  Color getMarkerColor(String type) {
    if (type == 'Restaurant') return const Color(0xFF7C57FC); // Purple
    if (type == 'Coffee') return const Color(0xFFE96D2B); // Orange/Brown
    if (type == 'Park') return const Color(0xFF017346); // Green
    if (type == 'Ticket') return const Color(0xFF7C57FC); // Purple
    if (type == 'Airport') return const Color(0xFF3649E1); // Blue
    if (type == 'Bars') return const Color(0xFF7C57FC); // Purple
    if (type == 'Pharmacy') return const Color(0xFF5A5D67); // Grey
    if (type == 'Hotel') return const Color(0xFF3649E1); // Blue
    if (type == 'Supermarket') return const Color(0xFF3649E1); // Blue
    if (type == 'Bakery') return const Color(0xFFCB3D8D); // Pink
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
  }

  Future<void> preloadPlaceMarkers(
    List<Map<String, dynamic>> places,
    VoidCallback onUpdate,
  ) async {
    bool needsUpdate = false;
    for (final place in places) {
      final String id = place['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      
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
    }
    if (needsUpdate) {
      onUpdate();
    }
  }

  Future<BitmapDescriptor> createMarkerWithLabel({
    required Map<String, dynamic> place,
    required bool isSelected,
  }) async {
    final String name = place['name']?.toString() ?? '';
    final type = place['type']?.toString() ?? 'Other';
    final double rating = (place['rating'] as num?)?.toDouble() ?? 4.0;
    final int peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
    final String price = place['price']?.toString() ?? r'$$';

    final IconData iconData = getIconDataForType(type);
    final Color color = getMarkerColor(type);

    final ui.PlatformDispatcher dispatcher = ui.PlatformDispatcher.instance;
    final double dpr = dispatcher.views.isNotEmpty ? dispatcher.views.first.devicePixelRatio : 3.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

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

    // 2. Draw Text Details on the Left
    // Line 1: Name
    final TextPainter namePainter = TextPainter(
      textDirection: TextDirection.rtl, // Since name can be Arabic
      textAlign: TextAlign.right,
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

    // Line 2: Check-ins count
    final TextPainter visitorsPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    visitorsPainter.text = TextSpan(
      text: "$peopleCount people here",
      style: TextStyle(
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
    visitorsPainter.layout(maxWidth: textWidth);

    // Line 3: Price & Rating
    final TextPainter ratingPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    ratingPainter.text = TextSpan(
      text: "$price. ★(${rating.toStringAsFixed(1)})",
      style: TextStyle(
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
    ratingPainter.layout(maxWidth: textWidth);

    // Paint the texts aligned vertically and next to the pin
    double currentY = pinDy;
    namePainter.paint(canvas, Offset(textWidth - namePainter.width, currentY));
    currentY += namePainter.height + 1.0;
    
    visitorsPainter.paint(canvas, Offset(textWidth - visitorsPainter.width, currentY));
    currentY += visitorsPainter.height + 1.0;

    ratingPainter.paint(canvas, Offset(textWidth - ratingPainter.width, currentY));

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
