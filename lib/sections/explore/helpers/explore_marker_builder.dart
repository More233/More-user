import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'explore_screen_helpers.dart';
import 'marker_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    List<Map<String, dynamic>> placesToDraw = List.from(filtered);

    if (state.selectedMapTab == 2) {
      placesToDraw = placesToDraw.where((place) {
        final String id = place['id'].toString();
        if (id.startsWith('mock_world_')) {
          return false;
        }
        return true;
      }).toList();
    }

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

      bool isProminent = ExploreScreenHelpers.isProminentPlace(place);
      bool showAsPin = isSelected || isProminent || currentZoom >= 15.0;

      if (state.selectedMapTab == 0) {
        bool isProminentInDiscover = false;
        if (place['isCustomVenue'] == true || place['isRegistered'] == true) {
          isProminentInDiscover = true;
        } else {
          final double rating = (place['rating'] as num? ?? 0.0).toDouble();
          final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
          final int peopleCount = (place['peopleCount'] as num? ?? 0).toInt();
          if (peopleCount > 0) {
            isProminentInDiscover = true;
          } else if (currentZoom >= 15.0) {
            isProminentInDiscover = rating >= 4.0 && reviewsCount >= 30;
          } else if (currentZoom >= 14.0) {
            isProminentInDiscover = rating >= 4.2 && reviewsCount >= 60;
          } else if (currentZoom >= 13.0) {
            isProminentInDiscover = rating >= 4.4 && reviewsCount >= 100;
          } else {
            isProminentInDiscover = rating >= 4.6 && reviewsCount >= 180;
          }
        }
        showAsPin = isSelected || isProminentInDiscover || currentZoom >= 15.5;
      }

      if (state.selectedMapTab == 1) {
        bool isProminentInEvents = false;
        if (place['isCustomVenue'] == true || place['isRegistered'] == true) {
          isProminentInEvents = true;
        } else {
          final double rating = (place['rating'] as num? ?? 0.0).toDouble();
          final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
          if (currentZoom >= 15.0) {
            isProminentInEvents = rating >= 3.8 && reviewsCount >= 10;
          } else if (currentZoom >= 14.0) {
            isProminentInEvents = rating >= 4.0 && reviewsCount >= 30;
          } else if (currentZoom >= 13.0) {
            isProminentInEvents = rating >= 4.2 && reviewsCount >= 60;
          } else {
            isProminentInEvents = rating >= 4.5 && reviewsCount >= 100;
          }
        }
        showAsPin = isSelected || isProminentInEvents || currentZoom >= 13.5;
      }

      if (state.selectedMapTab == 2) {
        double threshold = 15.5;
        final int peopleCount = (place['peopleCount'] as num? ?? 0).toInt();
        if (peopleCount > 0) {
          threshold -= 2.0; // Hot spots with active people show up early (zoom 13.5)
        } else {
          final double rating = (place['rating'] as num? ?? 0.0).toDouble();
          final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
          if (rating >= 4.5 && reviewsCount >= 100) {
            threshold -= 1.5; // High profile venues show up at zoom 14.0
          } else if (rating >= 4.0 && reviewsCount >= 30) {
            threshold -= 0.75; // Medium profile venues show up at zoom 14.75
          }
        }
        // Add a small unique jitter to prevent uniform block resizing
        final int hash = place['id'].toString().hashCode.abs();
        final double jitter = ((hash % 100) / 100.0 - 0.5) * 0.6; // range [-0.3, 0.3]
        threshold += jitter;

        showAsPin = isSelected || currentZoom >= threshold;
      }

      final bool isSaved = place['isSaved'] as bool? ?? false;
      final bool isVisited = place['isVisited'] as bool? ?? false;
      if ((isSaved || isVisited) && state.selectedMapTab != 2) {
        showAsPin = true;
      }

      if (isManualTapped) {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
        );
      } else if (isCheckIn && authorAvatar != null && markerGenerator.avatarMarkerCache.containsKey(authorAvatar)) {
        icon = markerGenerator.avatarMarkerCache[authorAvatar]!;
      } else if (state.selectedMapTab == 2) {
        // Live Now/Swarm Tab: enforce circular shapes or category dots, bypass all standard teardrop styling!
        final bool showCustomLabel = normalCustomCache.containsKey(place['id'].toString());
        if (showAsPin) {
          if (showCustomLabel) {
            if (isSelected && selectedCustomCache.containsKey(place['id'].toString())) {
              icon = selectedCustomCache[place['id'].toString()]!;
            } else {
              icon = normalCustomCache[place['id'].toString()]!;
            }
            final double finalScale = isSelected ? 1.1 : 0.9;
            final double radius = 16.0 * finalScale;
            final double glowRadius = radius + 4.0;
            final double canvasWidth = 150.0;
            final double cy = glowRadius + 4.0;
            final double textSpacing = 4.0;
            final double textTop = cy + glowRadius + 6.0;

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

            final double canvasHeight = textTop + namePainter.height + textSpacing + visitorsPainter.height + 8.0;
            anchorX = 0.5;
            anchorY = cy / canvasHeight;
          } else {
            icon = markerGenerator.heatmapCircleIcons[type] ?? markerGenerator.heatmapCircleIcons['default'] ?? BitmapDescriptor.defaultMarker;
            anchorX = 0.5;
            anchorY = 0.5;
          }
        } else {
          icon = markerGenerator.heatmapDotIcons[type] ?? markerGenerator.heatmapDotIcons['default'] ?? BitmapDescriptor.defaultMarker;
          anchorX = 0.5;
          anchorY = 0.5;
        }
      } else if (isSaved && markerGenerator.userSavedMarker != null) {
        icon = markerGenerator.userSavedMarker!;
        anchorX = 0.5;
        anchorY = 0.95;
      } else if (isVisited) {
        final List<dynamic> visitors = place['visitors'] as List<dynamic>? ?? [];
        final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final bool userVisited = visitors.any((v) => v is Map && v['userId'] == currentUserId);
        
        if (userVisited && markerGenerator.userVisitedMarker != null) {
          icon = markerGenerator.userVisitedMarker!;
          anchorX = 0.5;
          anchorY = 0.95;
        } else if (visitors.isNotEmpty) {
          final String? friendAvatar = visitors.firstWhere(
            (v) => v is Map && v['avatarUrl'] != null,
            orElse: () => null,
          )?['avatarUrl'] as String?;
          
          if (friendAvatar != null && markerGenerator.avatarMarkerCache.containsKey(friendAvatar)) {
            icon = markerGenerator.avatarMarkerCache[friendAvatar]!;
            anchorX = 0.5;
            anchorY = 0.95;
          } else {
            if (isSelected) {
              icon = markerGenerator.discoverSelectedIcons[type] ?? markerGenerator.discoverSelectedIcons['default'] ?? BitmapDescriptor.defaultMarker;
            } else {
              icon = markerGenerator.discoverNormalIcons[type] ?? markerGenerator.discoverNormalIcons['default'] ?? BitmapDescriptor.defaultMarker;
            }
            anchorX = 0.5;
            anchorY = 0.95;
          }
        } else {
          if (isSelected) {
            icon = markerGenerator.discoverSelectedIcons[type] ?? markerGenerator.discoverSelectedIcons['default'] ?? BitmapDescriptor.defaultMarker;
          } else {
            icon = markerGenerator.discoverNormalIcons[type] ?? markerGenerator.discoverNormalIcons['default'] ?? BitmapDescriptor.defaultMarker;
          }
          anchorX = 0.5;
          anchorY = 0.95;
        }
      } else if (showAsPin) {
        final bool showCustomLabel = state.selectedMapTab == 2 && normalCustomCache.containsKey(place['id'].toString());
        
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
          } else if (state.selectedMapTab == 0 || state.selectedMapTab == 1) {
            // Discover & Events: use the pin-with-dot-below style for all categories
            if (isSelected) {
              icon = markerGenerator.discoverSelectedIcons[type] ?? markerGenerator.discoverSelectedIcons['default'] ?? BitmapDescriptor.defaultMarker;
            } else {
              icon = markerGenerator.discoverNormalIcons[type] ?? markerGenerator.discoverNormalIcons['default'] ?? BitmapDescriptor.defaultMarker;
            }
            anchorX = 0.5;
            anchorY = 0.95;
          } else {
            if (isSelected) {
              icon = markerGenerator.selectedMarkerIcons[type] ?? markerGenerator.selectedMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
            } else {
              icon = markerGenerator.normalMarkerIcons[type] ?? markerGenerator.normalMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
            }
            anchorX = 0.5;
            anchorY = 1.0;
          }
        }
      } else {
        if (state.selectedMapTab == 0 || state.selectedMapTab == 1) {
          icon = markerGenerator.dotMarkerIcons[type] ?? markerGenerator.dotMarkerIcons['default'] ?? BitmapDescriptor.defaultMarker;
          anchorX = 0.5;
          anchorY = 0.5;
        } else {
          if (iconUrl != null &&
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
        }
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

    // Hide heatmap only at extreme close zoom (street level)
    if (currentZoom >= 18.0) {
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

    // Filter places strictly for heatmap to avoid noise and show actual hot spots
    final List<Map<String, dynamic>> placesToHeat = filtered.where((place) {
      final String id = place['id'].toString();
      final bool isMock = id.startsWith('mock_world_');
      
      if (isMock) {
        if (currentZoom >= 11.0) return false;
        // Only show mock world places with reviewsCount > 60 when zoomed out to avoid global noise
        final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
        return reviewsCount > 60;
      }

      // Include all regular/real places for place density calculation
      return true;
    }).toList();

    // Calculate dynamic neighbor radius in degrees based on zoom level (divides professionally as you zoom in)
    double neighborRadiusDegrees = 0.25;
    if (currentZoom < 5.0) {
      neighborRadiusDegrees = 0.6;
    } else if (currentZoom >= 5.0 && currentZoom < 8.0) {
      neighborRadiusDegrees = 0.3;
    } else {
      neighborRadiusDegrees = 0.12;
    }

    final List<int> neighborCounts = List.filled(placesToHeat.length, 0);
    for (int i = 0; i < placesToHeat.length; i++) {
      final double latI = (placesToHeat[i]['latitude'] as num? ?? 0.0).toDouble();
      final double lngI = (placesToHeat[i]['longitude'] as num? ?? 0.0).toDouble();
      
      int count = 0;
      for (int j = 0; j < placesToHeat.length; j++) {
        if (i == j) continue;
        final double latJ = (placesToHeat[j]['latitude'] as num? ?? 0.0).toDouble();
        final double lngJ = (placesToHeat[j]['longitude'] as num? ?? 0.0).toDouble();
        
        final double dx = latI - latJ;
        final double dy = lngI - lngJ;
        final double distDegrees = math.sqrt(dx * dx + dy * dy);
        
        if (distDegrees <= neighborRadiusDegrees) {
          count++;
        }
      }
      neighborCounts[i] = count;
    }

    for (int i = 0; i < placesToHeat.length; i++) {
      final place = placesToHeat[i];
      final double lat = (place['latitude'] as num? ?? 0.0).toDouble();
      final double lng = (place['longitude'] as num? ?? 0.0).toDouble();

      // Density-based weight: 1.0 (base) + neighbors count
      final int neighbors = neighborCounts[i];
      final double densityWeight = (neighbors + 1).toDouble() * 3.0;

      final double finalWeight = (densityWeight * weightBoost).clamp(0.5, 200.0);
      points.add(WeightedLatLng(LatLng(lat, lng), weight: finalWeight));
    }

    debugPrint("buildHeatmaps: points count = ${points.length}, zoom = $currentZoom, weightBoost = $weightBoost");
    if (points.isEmpty) return {};

    // Calculate dynamic opacity: fades out gradually only at close zoom (street level)
    double opacity = 0.85;
    if (currentZoom >= 16.5) {
      opacity = (0.85 * (1.0 - (currentZoom - 16.5) / 1.5)).clamp(0.0, 0.85);
    } else if (currentZoom >= 8.0) {
      opacity = (0.85 - (currentZoom - 8.0) * 0.02).clamp(0.75, 0.85);
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
    } else if (currentZoom >= 12.0 && currentZoom < 15.0) {
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
