import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'explore_screen_helpers.dart';
import 'marker_generator.dart';
import '../models/explore_state.dart';

class ExploreMarkerBuilder {
  static Set<Marker> buildMarkers({
    required ExploreState state,
    required List<Map<String, dynamic>> filtered,
    required double currentZoom,
    required MarkerGenerator markerGenerator,
    required void Function(Map<String, dynamic> place, LatLng position) onMarkerTap,
  }) {
    final Set<Marker> markers = {};
    final List<Map<String, dynamic>> placesToDraw = List.from(filtered);

    if (state.selectedPlace != null) {
      final selectedId = state.selectedPlace!['id'];
      if (!placesToDraw.any((p) => p['id'] == selectedId)) {
        placesToDraw.add(state.selectedPlace!);
      }
    }

    final normalCustomCache = state.selectedMapTab == 2
        ? markerGenerator.customPlaceMarkersNormalHeatmap
        : markerGenerator.customPlaceMarkersNormal;
    final selectedCustomCache = state.selectedMapTab == 2
        ? markerGenerator.customPlaceMarkersSelectedHeatmap
        : markerGenerator.customPlaceMarkersSelected;

    for (final place in placesToDraw) {
      final isSelected = state.selectedPlace != null && state.selectedPlace!['id'] == place['id'];

      final type = place['type'] as String? ?? 'Other';
      final iconUrl = place['iconUrl'] as String?;
      final isCheckIn = place['isCheckIn'] as bool? ?? false;
      final authorAvatar = place['authorAvatar'] as String?;
      
      BitmapDescriptor icon;
      final bool isManualTapped = place['id'].toString().startsWith('tapped_');
      double anchorX = 0.5;
      double anchorY = 1.0;

      final bool isProminent = ExploreScreenHelpers.isProminentPlace(place);
      final bool showAsPin = isSelected || isProminent || currentZoom >= 15.0 || state.selectedMapTab == 2;

      if (isManualTapped) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      } else if (isCheckIn && authorAvatar != null && markerGenerator.avatarMarkerCache.containsKey(authorAvatar)) {
        icon = markerGenerator.avatarMarkerCache[authorAvatar]!;
      } else if (showAsPin) {
        final bool showCustomLabel = (isSelected || currentZoom >= 15.0 || state.selectedMapTab == 2) && normalCustomCache.containsKey(place['id'].toString());
        
        if (showCustomLabel) {
          if (isSelected && selectedCustomCache.containsKey(place['id'].toString())) {
            icon = selectedCustomCache[place['id'].toString()]!;
          } else {
            icon = normalCustomCache[place['id'].toString()]!;
          }
          
          final double finalScale = isSelected ? 1.1 : 0.9;
          
          if (state.selectedMapTab == 2) {
            // Heatmap custom label marker: circle icon at top center, text below it
            final double radius = 16.0 * finalScale;
            final double glowRadius = radius + 4.0;
            final double canvasWidth = 150.0;
            final double cy = glowRadius + 4.0;
            
            final name = place['name']?.toString() ?? '';
            final TextPainter namePainter = TextPainter(
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 1,
              ellipsis: '...',
            )..text = TextSpan(
              text: name,
              style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
            )..layout(maxWidth: canvasWidth - 16.0);
            
            final int peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
            final String visitorsText = peopleCount == 1 ? "1 person here" : "$peopleCount people here";
            final TextPainter visitorsPainter = TextPainter(
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 1,
            )..text = TextSpan(
              text: visitorsText,
              style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.w600),
            )..layout(maxWidth: canvasWidth - 16.0);
            
            final double textSpacing = 4.0;
            final double textTop = cy + glowRadius + 6.0;
            final double canvasHeight = textTop + namePainter.height + textSpacing + visitorsPainter.height + 8.0;
            
            anchorX = 0.5;
            anchorY = cy / canvasHeight;
          } else {
            final double rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
            if (!isCheckIn && rating > 0.0) {
              anchorX = 0.5;
              anchorY = isSelected ? 0.5 : 0.9;
            } else {
              // Standard teardrop custom label marker
              final double pinWidth = 27.75 * finalScale;
              final double textWidth = 120.0;
              final double spacing = 8.0;
              final double canvasWidth = textWidth + spacing + pinWidth + 8.0;
              
              final double pinDx = textWidth + spacing + 4.0;
              final double pinDy = 4.0;
              final double pinHeight = 30.833 * finalScale;
              final double canvasHeight = pinHeight + 16.0;

              anchorX = (pinDx + 13.875 * finalScale) / canvasWidth;
              anchorY = (pinDy + 30.833 * finalScale) / canvasHeight;
            }
          }
        } else {
          if (state.selectedMapTab == 2) {
            icon = markerGenerator.heatmapCircleIcons[type] ?? markerGenerator.heatmapCircleIcons['default'] ?? BitmapDescriptor.defaultMarker;
            anchorX = 0.5;
            anchorY = 0.5;
          } else if (isSelected) {
            icon = markerGenerator.selectedMarkerIcons[type] ?? markerGenerator.selectedMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
          } else {
            icon = markerGenerator.normalMarkerIcons[type] ?? markerGenerator.normalMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
          }
        }
      } else if (iconUrl != null &&
          (isSelected ? markerGenerator.networkIconsSelectedCache : markerGenerator.networkIconsNormalCache).containsKey(iconUrl)) {
        icon = (isSelected ? markerGenerator.networkIconsSelectedCache : markerGenerator.networkIconsNormalCache)[iconUrl]!;
      } else if (markerGenerator.iconsLoaded) {
        icon = markerGenerator.dotMarkerIcons[type] ?? markerGenerator.dotMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
        anchorX = 0.5;
        anchorY = 0.5;
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      }

      final LatLng position = LatLng(
        (place['latitude'] as num? ?? 0.0).toDouble(),
        (place['longitude'] as num? ?? 0.0).toDouble(),
      );

      markers.add(
        Marker(
          markerId: MarkerId(place['id']?.toString() ?? UniqueKey().toString()),
          position: position,
          icon: icon,
          anchor: Offset(anchorX, anchorY),
          onTap: () => onMarkerTap(place, position),
        ),
      );
    }
    return markers;
  }

  static Set<Heatmap> buildHeatmaps({
    required ExploreState state,
    required List<Map<String, dynamic>> filtered,
    required double currentZoom,
  }) {
    // Show heatmap only on Swarming (2) tab
    if (state.selectedMapTab != 2) return {};

    // Hide heatmap completely at street level zoom
    if (currentZoom >= 16.5) {
      debugPrint("buildHeatmaps: hidden due to close zoom = $currentZoom");
      return {};
    }

    // Determine weight boost factor based on zoom level to increase color intensity when zoomed out
    double weightBoost = 1.0;
    if (currentZoom < 4.0) {
      weightBoost = 2.8;
    } else if (currentZoom >= 4.0 && currentZoom < 6.0) {
      weightBoost = 2.2;
    } else if (currentZoom >= 6.0 && currentZoom < 9.0) {
      weightBoost = 1.6;
    } else if (currentZoom >= 9.0 && currentZoom < 12.0) {
      weightBoost = 1.2;
    }

    final List<WeightedLatLng> points = [];

    for (final place in filtered) {
      final double lat = (place['latitude'] as num? ?? 0.0).toDouble();
      final double lng = (place['longitude'] as num? ?? 0.0).toDouble();

      final double heatWeight = ExploreScreenHelpers.calculateHybridWeight(
        place: place,
        isSaved: place['isSaved'] as bool? ?? false,
      );

      final int peopleCount = (place['peopleCount'] as num?)?.toInt() ?? 0;
      if (peopleCount > 0) {
        debugPrint("buildHeatmaps LOOP: name=${place['name']}, peopleCount=$peopleCount, weight=$heatWeight, lat=$lat, lng=$lng");
      }

      // Only add to heatmap if the weight is above a threshold to avoid noise
      if (heatWeight > 0.5) {
        final double finalWeight = (heatWeight * weightBoost * 2.0).clamp(0.5, 200.0);
        points.add(WeightedLatLng(LatLng(lat, lng), weight: finalWeight));
      }
    }

    debugPrint("buildHeatmaps: points count = ${points.length}, zoom = $currentZoom, weightBoost = $weightBoost");
    if (points.isEmpty) return {};

    // Calculate dynamic opacity: fades out between 14.0 and 16.5
    double opacity = 0.85;
    if (currentZoom >= 14.0) {
      opacity = (0.80 * (1.0 - (currentZoom - 14.0) / 2.5)).clamp(0.0, 0.80);
    } else if (currentZoom >= 10.0) {
      opacity = (0.85 - (currentZoom - 10.0) * 0.05).clamp(0.65, 0.85);
    }

    // Calculate dynamic radius: wider on zoom-out, tighter on zoom-in
    int radius = 45;
    if (currentZoom < 4.0) {
      radius = 120; // Massive global coverage!
    } else if (currentZoom >= 4.0 && currentZoom < 6.0) {
      radius = 95;  // Large country-level blobs
    } else if (currentZoom >= 6.0 && currentZoom < 9.0) {
      radius = 75;  // Regional/city-level clusters
    } else if (currentZoom >= 9.0 && currentZoom < 12.0) {
      radius = 55;  // Local district clusters
    } else if (currentZoom >= 12.0 && currentZoom < 14.0) {
      radius = 40;  // Street-level glow
    } else {
      radius = 25;  // Very tight pinpoint glow before vanishing
    }

    return {
      Heatmap(
        heatmapId: const HeatmapId('explore_heatmap'),
        data: points,
        radius: HeatmapRadius.fromPixels(radius),
        dissipating: true,
        opacity: opacity,
        gradient: const HeatmapGradient(
          [
            HeatmapGradientColor(Color(0xFF3F51B5), 0.15),  // Blue/Indigo for very low density
            HeatmapGradientColor(Color(0xFF00BCD4), 0.4),   // Cyan/Teal for low-medium density
            HeatmapGradientColor(Color(0xFF4CAF50), 0.65),  // Green for medium density
            HeatmapGradientColor(Color(0xFFFFEB3B), 0.85),  // Yellow for high density
            HeatmapGradientColor(Color(0xFFFF5722), 1.0),   // Deep Orange/Red for maximum density
          ],
        ),
      ),
    };
  }
}
