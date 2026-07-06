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

    final normalCustomCache = markerGenerator.customPlaceMarkersNormal;
    final selectedCustomCache = markerGenerator.customPlaceMarkersSelected;

    for (final place in placesToDraw) {
      final isSelected = state.selectedPlace != null && state.selectedPlace!['id'] == place['id'];
      
      // In heatmap mode, hide markers entirely if zoomed out far (below zoom 14.0) unless selected
      if (state.selectedMapTab == 2 && currentZoom < 14.0 && !isSelected) {
        continue;
      }

      final type = place['type'] as String? ?? 'Other';
      final iconUrl = place['iconUrl'] as String?;
      final isCheckIn = place['isCheckIn'] as bool? ?? false;
      final authorAvatar = place['authorAvatar'] as String?;
      
      BitmapDescriptor icon;
      final bool isManualTapped = place['id'].toString().startsWith('tapped_');
      double anchorX = 0.5;
      double anchorY = 1.0;

      final bool isProminent = ExploreScreenHelpers.isProminentPlace(place);
      final bool showAsPin = isSelected || isProminent || currentZoom >= 15.0;

      if (isManualTapped) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      } else if (isCheckIn && authorAvatar != null && markerGenerator.avatarMarkerCache.containsKey(authorAvatar)) {
        icon = markerGenerator.avatarMarkerCache[authorAvatar]!;
      } else if (showAsPin) {
        final bool showCustomLabel = (isSelected || currentZoom >= 15.0) && normalCustomCache.containsKey(place['id'].toString());
        
        if (showCustomLabel) {
          if (isSelected && selectedCustomCache.containsKey(place['id'].toString())) {
            icon = selectedCustomCache[place['id'].toString()]!;
          } else {
            icon = normalCustomCache[place['id'].toString()]!;
          }
          
          final double finalScale = isSelected ? 1.1 : 0.9;
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
        } else {
          if (isSelected) {
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
    if (state.selectedMapTab != 2) return {};

    // Hide heatmap completely at very close zooms
    if (currentZoom >= 17.5) return {};

    final List<WeightedLatLng> points = [];

    for (final place in filtered) {
      final double lat = (place['latitude'] as num? ?? 0.0).toDouble();
      final double lng = (place['longitude'] as num? ?? 0.0).toDouble();
      final int reviews = (place['reviewsCount'] as num? ?? 0).toInt();
      final double rating = (place['rating'] as num? ?? 0.0).toDouble();
      final int checkIns = (place['peopleCount'] as num? ?? 0).toInt();

      // Calculate weight based on reviews, ratings, and app check-ins
      final double reviewScore = (reviews / 50.0).clamp(0.0, 0.5);
      final double ratingScore = rating > 4.0 ? ((rating - 4.0) * 0.2).clamp(0.0, 0.2) : 0.0;
      final double checkInScore = (checkIns * 0.3).clamp(0.0, 0.6);
      
      // Keep a higher baseline floor weight (0.4) to guarantee visibility on map
      final double heatWeight = (reviewScore + ratingScore + checkInScore).clamp(0.4, 1.0);

      points.add(WeightedLatLng(LatLng(lat, lng), weight: heatWeight));
    }

    if (points.isEmpty) return {};

    // Calculate dynamic opacity: fades out as zoom increases from 14.5 to 17.5
    double opacity = 0.85;
    if (currentZoom >= 14.5) {
      opacity = (0.85 * (1.0 - (currentZoom - 14.5) / 3.0)).clamp(0.0, 0.85);
    }

    // Calculate dynamic radius: larger radius when zoomed out, smaller when zoomed in
    int radius = 45;
    if (currentZoom < 10.0) {
      radius = 70;
    } else if (currentZoom >= 10.0 && currentZoom < 13.0) {
      radius = 60;
    } else if (currentZoom >= 13.0 && currentZoom < 15.0) {
      radius = 50;
    } else {
      radius = 45;
    }

    return {
      Heatmap(
        heatmapId: const HeatmapId('explore_heatmap'),
        data: points,
        radius: HeatmapRadius.fromPixels(radius),
        dissipating: true, // Let it dissipate normally so it is fully compatible and displays correctly on all platforms
        opacity: opacity,
        gradient: const HeatmapGradient(
          [
            HeatmapGradientColor(Color(0x404CAF50), 0.2),   // Green for low density
            HeatmapGradientColor(Color(0x90FFEB3B), 0.55),  // Yellow for medium density
            HeatmapGradientColor(Color(0xC0FF9800), 0.8),   // Orange for high density
            HeatmapGradientColor(Color(0xE0F44336), 1.0),   // Red for maximum density
          ],
        ),
      ),
    };
  }
}
