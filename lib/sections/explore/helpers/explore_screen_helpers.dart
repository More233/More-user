import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/explore_state.dart';
import 'world_cities_data.dart';

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

    // Exponential time decay function
    // At t=0: weight = 1.0
    // At t=60: weight = 0.36
    // At t=120: weight = 0.13
    // At t=180: weight = 0.05
    final double exponent = -diffInMinutes / 60.0;
    return math.exp(exponent);
  }

  static List<Map<String, dynamic>> getGlobalSwarmLandmarks(double userLat, double userLng) {
    return [
      {
        'id': 'global_swarm_toronto_yyz',
        'name': 'Toronto Pearson International Airport (YYZ)',
        'arabicName': 'مطار تورونتو بيرسون الدولي (YYZ)',
        'address': 'Toronto, ON, Canada',
        'latitude': 43.6777,
        'longitude': -79.6248,
        'rating': 4.5,
        'reviewsCount': 79,
        'price': r'$$',
        'peopleCount': 79,
        'basePeopleCount': 79,
        'type': 'Airport',
        'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500',
        'isSaved': false,
        'isVisited': false,
        'actionType': 'Other',
        'isRegistered': true,
        'visitors': <Map<String, dynamic>>[],
      },
      {
        'id': 'global_swarm_kafd_riyadh',
        'name': 'King Abdullah Financial District',
        'arabicName': 'مركز الملك عبدالله المالي (KAFD)',
        'address': 'Riyadh, Saudi Arabia',
        'latitude': 24.7622,
        'longitude': 46.6409,
        'rating': 4.8,
        'reviewsCount': 164,
        'price': r'$$$',
        'peopleCount': 164,
        'basePeopleCount': 164,
        'type': 'Other',
        'imageUrl': 'https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=500',
        'isSaved': false,
        'isVisited': false,
        'actionType': 'Other',
        'isRegistered': true,
        'visitors': <Map<String, dynamic>>[],
      },
      {
        'id': 'global_swarm_tokyo_hnd',
        'name': 'Tokyo International (Haneda) Airport (HND)',
        'arabicName': 'مطار طوكيو هانيدا الدولي (HND)',
        'address': 'Tokyo, Japan',
        'latitude': 35.5494,
        'longitude': 139.7798,
        'rating': 4.7,
        'reviewsCount': 51,
        'price': r'$$',
        'peopleCount': 51,
        'basePeopleCount': 51,
        'type': 'Airport',
        'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500',
        'isSaved': false,
        'isVisited': false,
        'actionType': 'Other',
        'isRegistered': true,
        'visitors': <Map<String, dynamic>>[],
      },
      {
        'id': 'global_swarm_singapore_sin',
        'name': 'Singapore Changi Airport (SIN)',
        'arabicName': 'مطار سنغافورة تشانغي (SIN)',
        'address': 'Singapore',
        'latitude': 1.3644,
        'longitude': 103.9915,
        'rating': 4.9,
        'reviewsCount': 25,
        'price': r'$$',
        'peopleCount': 25,
        'basePeopleCount': 25,
        'type': 'Airport',
        'imageUrl': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=500',
        'isSaved': false,
        'isVisited': false,
        'actionType': 'Other',
        'isRegistered': true,
        'visitors': <Map<String, dynamic>>[],
      },
    ].map((landmark) {
      final double lat = landmark['latitude'] as double;
      final double lng = landmark['longitude'] as double;
      final double meters = Geolocator.distanceBetween(userLat, userLng, lat, lng);
      final double km = meters / 1000;
      final String distanceStr = km < 1 
          ? '${meters.toStringAsFixed(0)} m' 
          : '${km.toStringAsFixed(1)} km';
      
      final Map<String, dynamic> copy = Map<String, dynamic>.from(landmark);
      copy['distance'] = distanceStr;
      return copy;
    }).toList();
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

    // Base density contribution from current/base people count (essential for global swarm landmarks)
    final int peopleCount = (place['peopleCount'] as num? ?? 0).toInt();
    double peopleDensityContribution = 0.0;
    if (peopleCount >= 150) {
      peopleDensityContribution = 18.0;
    } else if (peopleCount >= 100) {
      peopleDensityContribution = 14.0;
    } else if (peopleCount >= 50) {
      peopleDensityContribution = 10.0;
    } else if (peopleCount >= 20) {
      peopleDensityContribution = 6.0;
    } else if (peopleCount >= 5) {
      peopleDensityContribution = 3.0;
    } else if (peopleCount > 0) {
      peopleDensityContribution = 1.5;
    }

    final double baselinePopularity = math.max(reviewsContribution, peopleDensityContribution);

    // 3. Place Quality / Rating contribution
    final double rating = (place['rating'] as num? ?? 0.0).toDouble();
    double ratingContribution = 1.0;
    if (rating >= 4.5 || rating >= 9.0) { // Google 4.5+ or Foursquare 9.0+
      ratingContribution = 1.5;
    } else if (rating >= 4.0 || rating >= 8.0) {
      ratingContribution = 1.25;
    }

    // 4. Baseline Real-world Crowd Density (combines popularity and rating)
    final double baselineDensity = baselinePopularity * ratingContribution;

    // 5. App Active Check-ins Multiplier (Amplifies the heatmap dynamically in real-time)
    final double activeMultiplier = 1.0 + (activeCheckins * 4.0);

    // 6. Saved places bonus (people bookmarked it)
    final double savedBonus = isSaved ? 5.0 : 0.0;

    // Final logical crowd density weight
    final double totalWeight = (baselineDensity * activeMultiplier) + savedBonus;

    return totalWeight;
  }

  static List<Map<String, dynamic>> generateMockWorldPlaces() {
    final List<Map<String, dynamic>> mockPlaces = [];
    final random = math.Random(42); // Seeded random for consistent layout
    
    for (final city in WorldCitiesData.cities) {
      final String cityName = city['name'] as String;
      final double lat = city['lat'] as double;
      final double lng = city['lng'] as double;
      final double density = city['density'] as double;
      
      // Number of places is proportional to the city density factor
      final int placeCount = (density * 10).toInt();
      
      for (int i = 0; i < placeCount; i++) {
        // Offset radius concentrates heat in the center
        final double maxOffset = 0.05 + (random.nextDouble() * 0.15);
        final double angle = random.nextDouble() * 2 * math.pi;
        final double offsetLat = lat + maxOffset * math.sin(angle);
        final double offsetLng = lng + maxOffset * math.cos(angle);
        
        mockPlaces.add({
          'id': 'mock_world_${cityName.toLowerCase()}_$i',
          'name': 'Mock Place $i in $cityName',
          'arabicName': 'مكان افتراضي $i في $cityName',
          'address': '$cityName, World',
          'latitude': offsetLat,
          'longitude': offsetLng,
          'rating': 4.0 + (random.nextDouble() * 1.0),
          'reviewsCount': 10 + random.nextInt(100),
          'peopleCount': 0,
          'type': i % 3 == 0 ? 'Restaurant' : (i % 3 == 1 ? 'Coffee' : 'Bars'),
          'imageUrl': '',
          'isSaved': false,
          'isVisited': false,
          'actionType': 'Other',
          'isRegistered': false,
          'visitors': <Map<String, dynamic>>[],
        });
      }
    }
    return mockPlaces;
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
      final String id = place['id'].toString();
      if (id.startsWith('mock_world_') && !forHeatmap) {
        return false;
      }
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
        if (type != state.selectedCategory) return false;
      }

      if (state.selectedMapTab == 1) {
        final type = place['type'] as String? ?? 'Other';
        if (state.selectedCategory.isNotEmpty) {
          if (type != state.selectedCategory) return false;
        } else {
          if (type != 'Movies' && type != 'Sports' && type != 'Concerts' && type != 'Ticket') {
            return false;
          }
        }
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
        final bool isGlobal = place['id'].toString().startsWith('global_swarm_');
        
        if (currentZoom < 6.0) {
          return isGlobal || isSelected;
        } else if (currentZoom < 11.0) {
          return isGlobal || isSelected;
        }

        final double rating = (place['rating'] as num? ?? 0.0).toDouble();
        final int reviews = (place['reviewsCount'] as num? ?? 0).toInt();

        if (currentZoom >= 11.0 && currentZoom < 13.0) {
          return rating >= 4.7 && reviews >= 30;
        } else if (currentZoom >= 13.0 && currentZoom < 14.5) {
          return rating >= 4.2 && reviews >= 10;
        } else {
          final int peopleCount = (place['peopleCount'] as num? ?? 0).toInt();
          if (currentZoom >= 14.5 && currentZoom < 15.5) {
            return peopleCount > 0 || (rating >= 4.0 && reviews >= 15);
          } else if (currentZoom >= 15.5 && currentZoom < 16.5) {
            return peopleCount > 0 || (rating >= 3.5 && reviews >= 5);
          } else {
            return true;
          }
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
