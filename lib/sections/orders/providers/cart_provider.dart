import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../models/restaurant_model.dart';

class CartItemModel {
  final String id;
  final MenuItemModel item;
  final List<ModifierOption> selectedModifiers;
  final int quantity;
  final String? notes;

  const CartItemModel({
    required this.id,
    required this.item,
    required this.selectedModifiers,
    required this.quantity,
    this.notes,
  });

  double get unitPrice {
    double modsTotal = 0;
    for (final m in selectedModifiers) {
      modsTotal += m.price;
    }
    return item.price + modsTotal;
  }

  double get totalPrice => unitPrice * quantity;

  CartItemModel copyWith({
    int? quantity,
    String? notes,
  }) {
    return CartItemModel(
      id: id,
      item: item,
      selectedModifiers: selectedModifiers,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class CartState {
  final RestaurantModel? restaurant;
  final List<CartItemModel> items;

  const CartState({
    this.restaurant,
    this.items = const [],
  });

  int get totalCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  double get deliveryFee => restaurant?.deliveryFee ?? 0.0;

  double get totalAmount => subtotal + deliveryFee;

  bool get reachesMinOrder =>
      restaurant == null || subtotal >= restaurant!.minOrderAmount;

  double get remainingForMinOrder {
    if (restaurant == null) return 0.0;
    final diff = restaurant!.minOrderAmount - subtotal;
    return diff > 0 ? diff : 0.0;
  }

  CartState copyWith({
    RestaurantModel? restaurant,
    List<CartItemModel>? items,
    bool clearRestaurant = false,
  }) {
    return CartState(
      restaurant: clearRestaurant ? null : (restaurant ?? this.restaurant),
      items: items ?? this.items,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem({
    required RestaurantModel restaurant,
    required MenuItemModel item,
    required List<ModifierOption> modifiers,
    required int quantity,
    String? notes,
  }) {
    // If from a different restaurant, reset cart or replace
    if (state.restaurant != null && state.restaurant!.id != restaurant.id) {
      state = CartState(restaurant: restaurant, items: []);
    }

    final String uniqueId = '${item.id}_${modifiers.map((m) => m.name).join("_")}';
    final existingIndex = state.items.indexWhere((i) => i.id == uniqueId);

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedList = List<CartItemModel>.from(state.items);
      updatedList[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      state = state.copyWith(restaurant: restaurant, items: updatedList);
    } else {
      final newItem = CartItemModel(
        id: uniqueId,
        item: item,
        selectedModifiers: modifiers,
        quantity: quantity,
        notes: notes,
      );
      state = state.copyWith(
        restaurant: restaurant,
        items: [...state.items, newItem],
      );
    }
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.id == cartItemId) {
        return i.copyWith(quantity: newQuantity);
      }
      return i;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeItem(String cartItemId) {
    final updated = state.items.filter((i) => i.id != cartItemId).toList();
    if (updated.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void clearCart() {
    state = const CartState();
  }
}

extension _IterableFilter<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
