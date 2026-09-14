class MenuCategoryModel {
  final String id;
  final String venueId;
  final String name;
  final int sortOrder;

  const MenuCategoryModel({
    required this.id,
    required this.venueId,
    required this.name,
    this.sortOrder = 0,
  });

  factory MenuCategoryModel.fromMap(Map<String, dynamic> map) {
    return MenuCategoryModel(
      id: map['id']?.toString() ?? '',
      venueId: map['venue_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class ModifierOption {
  final String name;
  final double price;
  final bool isPopular;

  const ModifierOption({
    required this.name,
    required this.price,
    this.isPopular = false,
  });

  factory ModifierOption.fromMap(Map<String, dynamic> map) {
    return ModifierOption(
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isPopular: map['is_popular'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'is_popular': isPopular,
    };
  }
}

class MenuModifierModel {
  final String id;
  final String menuItemId;
  final String name;
  final bool isRequired;
  final int minSelections;
  final int maxSelections;
  final List<ModifierOption> options;

  const MenuModifierModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections = 99,
    this.options = const [],
  });

  factory MenuModifierModel.fromMap(Map<String, dynamic> map) {
    List<ModifierOption> opts = [];
    if (map['options'] != null && map['options'] is List) {
      opts = (map['options'] as List)
          .map((o) => ModifierOption.fromMap(o as Map<String, dynamic>))
          .toList();
    }

    return MenuModifierModel(
      id: map['id']?.toString() ?? '',
      menuItemId: map['menu_item_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      isRequired: map['is_required'] == true,
      minSelections: (map['min_selections'] as num?)?.toInt() ?? 0,
      maxSelections: (map['max_selections'] as num?)?.toInt() ?? 99,
      options: opts,
    );
  }
}

class MenuItemModel {
  final String id;
  final String venueId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? proPrice;
  final String? imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final String? orderCountLabel;
  final int sortOrder;

  const MenuItemModel({
    required this.id,
    required this.venueId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.proPrice,
    this.imageUrl,
    this.isAvailable = true,
    this.isPopular = false,
    this.orderCountLabel,
    this.sortOrder = 0,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id']?.toString() ?? '',
      venueId: map['venue_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      proPrice: (map['pro_price'] as num?)?.toDouble(),
      imageUrl: map['image_url']?.toString(),
      isAvailable: map['is_available'] != false,
      isPopular: map['is_popular'] == true,
      orderCountLabel: map['order_count_label']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
