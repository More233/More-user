import 'dart:math' as math;
import '../models/explore_state.dart';

class ExploreScreenHelpers {
  static double calculateTimeDecayWeight(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return 0.0;
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return 0.0;
    
    final difference = DateTime.now().difference(createdAt);
    final diffInMinutes = difference.inMinutes;

    // Check-in sliding window of 3 hours (180 minutes)
    if (diffInMinutes > 180 || diffInMinutes < 0) {
      return 0.0;
    }

    // Exponential decay formula: e^(-t / 60.0)
    // At t=0: weight = 1.0
    // At t=60: weight = 0.36
    // At t=120: weight = 0.13
    // At t=180: weight = 0.05
    final double exponent = -diffInMinutes / 60.0;
    return math.exp(exponent);
  }

  static double calculateHybridWeight({
    required Map<String, dynamic> place,
    required bool isSaved,
  }) {
    // 1. Check-In Weight (with Time Decay) from our app
    double checkInWeight = 0.0;
    final visitors = place['visitors'] as List<dynamic>? ?? [];
    for (final visitor in visitors) {
      if (visitor is Map<String, dynamic>) {
        final String? createdAtStr = visitor['createdAt'] as String?;
        checkInWeight += calculateTimeDecayWeight(createdAtStr);
      }
    }
    final double activeCheckins = checkInWeight.clamp(0.0, 10.0);

    // 2. Real-world Popularity Base (Google/Foursquare Reviews Count)
    final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
    double reviewsContribution = 0.5; // default low baseline
    if (reviewsCount >= 1500) {
      reviewsContribution = 20.0;
    } else if (reviewsCount >= 800) {
      reviewsContribution = 14.0;
    } else if (reviewsCount >= 300) {
      reviewsContribution = 8.0;
    } else if (reviewsCount >= 100) {
      reviewsContribution = 4.0;
    } else if (reviewsCount >= 20) {
      reviewsContribution = 2.0;
    }

    // 3. Place Quality / Rating contribution
    final double rating = (place['rating'] as num? ?? 0.0).toDouble();
    double ratingContribution = 1.0;
    if (rating >= 4.5 || rating >= 9.0) { // Google 4.5+ or Foursquare 9.0+
      ratingContribution = 1.5;
    } else if (rating >= 4.0 || rating >= 8.0) {
      ratingContribution = 1.25;
    }

    // 4. Baseline Real-world Crowd Density (combines popularity and rating)
    final double baselineDensity = reviewsContribution * ratingContribution;

    // 5. App Active Check-ins Multiplier (Amplifies the heatmap dynamically in real-time)
    final double activeMultiplier = 1.0 + (activeCheckins * 4.0);

    // 6. Saved places bonus (people bookmarked it)
    final double savedBonus = isSaved ? 5.0 : 0.0;

    // Final logical crowd density weight
    final double totalWeight = (baselineDensity * activeMultiplier) + savedBonus;

    return totalWeight;
  }

  static double? parseDistance(String? distanceStr) {
    if (distanceStr == null) return null;
    final str = distanceStr.toLowerCase().trim();
    if (str.contains('m') && !str.contains('k')) {
      final numVal = double.tryParse(str.replaceAll('m', '').trim());
      if (numVal != null) return numVal / 1000.0;
    } else if (str.contains('km')) {
      return double.tryParse(str.replaceAll('km', '').trim());
    }
    return null;
  }

  static bool isProminentPlace(Map<String, dynamic> place) {
    if (place['isCheckIn'] == true) return true;
    final String id = place['id']?.toString() ?? '';
    if (id.startsWith('tapped_') || id.startsWith('swarm_')) return true;
    if (place['isCustomVenue'] == true || place['isRegistered'] == true) return true;

    final String type = place['type'] as String? ?? '';
    final String typeLower = type.toLowerCase();
    if (typeLower.contains('airport') ||
        typeLower.contains('hotel') ||
        typeLower.contains('park') ||
        typeLower.contains('ticket')) {
      return true;
    }

    final String name = (place['name'] as String? ?? '').toLowerCase();
    final String address = (place['address'] as String? ?? '').toLowerCase();
    if (name.contains('tower') || name.contains('mall') || name.contains('center') || name.contains('plaza') ||
        name.contains('برج') || name.contains('مول') || name.contains('مركز') || name.contains('بلازا') || name.contains('ساحة')) {
      return true;
    }
    if (address.contains('highway') || address.contains('road') || address.contains('main') ||
        address.contains('طريق') || address.contains('رئيسي') || address.contains('سريع')) {
      return true;
    }

    if (address.contains('alley') || address.contains('lane') || address.contains('side') ||
        address.contains('زقاق') || address.contains('حارة') || address.contains('فرعي')) {
      return false;
    }

    final double rating = (place['rating'] as num? ?? 0.0).toDouble();
    final int reviewsCount = (place['reviewsCount'] as num? ?? 0).toInt();
    if (rating >= 4.4 && reviewsCount >= 10) {
      return true;
    }

    return false;
  }

  static List<Map<String, dynamic>> getFilteredPlaces(
    ExploreState state,
    double currentZoom, {
    bool forHeatmap = false,
  }) {
    final unfiltered = state.allPlaces.where((place) {
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase();
        final nameMatches = (place['name'] as String? ?? '').toLowerCase().contains(query);
        final arMatches = (place['arabicName'] as String? ?? '').toLowerCase().contains(query);
        if (!nameMatches && !arMatches) return false;
      }

      if (state.selectedMapTab == 3) {
        final filterVisited = state.filterState.visited;
        final filterSaved = state.filterState.saved;
        if (filterVisited && !(place['isVisited'] as bool? ?? false)) return false;
        if (filterSaved && !(place['isSaved'] as bool? ?? false)) return false;
        if (!filterVisited && !filterSaved) {
          return (place['isVisited'] as bool? ?? false) || (place['isSaved'] as bool? ?? false);
        }
        return true;
      }

      if (state.selectedMapTab == 0 && state.selectedCategory.isNotEmpty) {
        final type = place['type'] as String? ?? 'Other';
        if (state.selectedCategory == "Restaurant" && type != "Restaurant") return false;
        if (state.selectedCategory == "Coffee" && type != "Coffee") return false;
        if (state.selectedCategory == "Bakery" && type != "Bakery") return false;
        if (state.selectedCategory == "Bars" && type != "Bars") return false;
      }

      if (state.selectedMapTab == 1) {
        return place['actionType'] == 'Book';
      }
      if (state.selectedMapTab == 2 && !forHeatmap) {
        final double hybridWeight = calculateHybridWeight(
          place: place,
          isSaved: place['isSaved'] as bool? ?? false,
        );
        if (hybridWeight < 0.3) return false;
      }

      if (state.filterState.maxDistance != null) {
        final double? dist = parseDistance(place['distance'] as String?);
        if (dist == null || dist > state.filterState.maxDistance!) {
          return false;
        }
      }

      if (state.filterState.openNow) {
        final openNow = place['openNow'] as bool? ?? true;
        if (!openNow) return false;
      }

      if (state.filterState.minRating != null) {
        final rating = (place['rating'] as num? ?? 0.0).toDouble();
        if (rating < state.filterState.minRating!) return false;
      }

      if (state.filterState.priceRange != null) {
        final price = place['price'] as String? ?? r'$$';
        if (price != state.filterState.priceRange) return false;
      }

      if (state.filterState.newToMe && (place['isVisited'] as bool? ?? false)) return false;
      if (state.filterState.onList && !(place['isSaved'] as bool? ?? false)) return false;

      return true;
    }).toList();

    if (forHeatmap) {
      return unfiltered;
    }

    // Progressive zoom density filtering
    return unfiltered.where((place) {
      final isSelected = state.selectedPlace != null && state.selectedPlace!['id'] == place['id'];
      if (isSelected) return true;

      final isManual = place['id'].toString().startsWith('tapped_');
      if (isManual) return true;

      if (state.selectedMapTab == 2) {
        final double hybridWeight = calculateHybridWeight(
          place: place,
          isSaved: place['isSaved'] as bool? ?? false,
        );
        if (currentZoom < 8.0) {
          return hybridWeight >= 0.7; // Very popular only
        } else if (currentZoom >= 8.0 && currentZoom < 12.0) {
          return hybridWeight >= 0.5; // Moderately popular
        } else {
          return hybridWeight >= 0.3; // All relevant swarms
        }
      }

      if (currentZoom < 11.0) {
        // Zoomed out very far: show absolutely nothing except selected/dropped pins
        return false;
      }

      final isCheckIn = place['isCheckIn'] as bool? ?? false;
      if (isCheckIn) return true;

      final double rating = (place['rating'] as num? ?? 0.0).toDouble();
      final int reviews = (place['reviewsCount'] as num? ?? 0).toInt();

      if (currentZoom >= 11.0 && currentZoom < 13.0) {
        return rating >= 4.7 && reviews >= 30;
      } else if (currentZoom >= 13.0 && currentZoom < 14.5) {
        return rating >= 4.2 && reviews >= 10;
      } else {
        // Zoom >= 14.5: show everything
        return true;
      }
    }).toList();
  }
}
