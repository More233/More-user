import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant_model.dart';

final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'الكل');
final restaurantSearchQueryProvider = StateProvider<String>((ref) => '');

/// Stream of all restaurants from Supabase
final restaurantsStreamProvider = StreamProvider<List<RestaurantModel>>((ref) {
  final client = Supabase.instance.client;
  return client
      .from('venues')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final list = rows
            .map((m) => RestaurantModel.fromMap(m))
            .where((r) => r.isActive && r.supportsOrdering)
            .toList();
        list.sort((a, b) => (b.isPromoted ? 1 : 0).compareTo(a.isPromoted ? 1 : 0));
        return list;
      });
});

/// Filtered restaurants based on search query, category, and current region
final filteredRestaurantsProvider = Provider<List<RestaurantModel>>((ref) {
  final restaurantsAsync = ref.watch(restaurantsStreamProvider);
  final list = restaurantsAsync.value ?? [];

  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(restaurantSearchQueryProvider).trim().toLowerCase();

  return list.where((r) {
    // 1. Search Query Filter
    if (searchQuery.isNotEmpty) {
      final nameMatches = r.name.toLowerCase().contains(searchQuery);
      final cuisinesMatch = r.cuisineTypes.any((c) => c.toLowerCase().contains(searchQuery));
      if (!nameMatches && !cuisinesMatch) return false;
    }

    // 2. Category Tab Filter
    if (selectedCategory != 'الكل') {
      if (selectedCategory == 'المطاعم') {
        // match all restaurants or bakery/dessert
        return true;
      }
      final catLower = selectedCategory.toLowerCase();
      final matchesCuisine = r.cuisineTypes.any((c) => c.toLowerCase().contains(catLower));
      final matchesName = r.name.toLowerCase().contains(catLower);
      if (!matchesCuisine && !matchesName) return false;
    }

    return true;
  }).toList();
});
