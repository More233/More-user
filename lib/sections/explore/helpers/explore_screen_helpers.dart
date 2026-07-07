import '../models/explore_state.dart';

class ExploreScreenHelpers {
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
        final int checkIns = (place['peopleCount'] as num? ?? 0).toInt();
        if (checkIns <= 0) return false;
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
        final int checkIns = (place['peopleCount'] as num? ?? 0).toInt();
        if (currentZoom < 5.0) {
          return checkIns >= 2;
        } else if (currentZoom >= 5.0 && currentZoom < 8.0) {
          return checkIns >= 2;
        } else if (currentZoom >= 8.0 && currentZoom < 12.0) {
          return checkIns >= 2;
        } else {
          return checkIns >= 1;
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
