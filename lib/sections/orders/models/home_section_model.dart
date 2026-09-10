class HomeSectionItemModel {
  final String id;
  final String sectionId;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? badgeText;
  final String? badgeColor;
  final double? price;
  final double? oldPrice;
  final double? rating;
  final int? ratingCount;
  final String? promoText;
  final int sortOrder;
  final bool isActive;

  const HomeSectionItemModel({
    required this.id,
    required this.sectionId,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.badgeText,
    this.badgeColor,
    this.price,
    this.oldPrice,
    this.rating,
    this.ratingCount,
    this.promoText,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory HomeSectionItemModel.fromMap(Map<String, dynamic> map) {
    return HomeSectionItemModel(
      id: map['id']?.toString() ?? '',
      sectionId: map['section_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      imageUrl: map['image_url']?.toString() ?? '',
      badgeText: map['badge_text']?.toString(),
      badgeColor: map['badge_color']?.toString() ?? 'yellow',
      price: map['price'] != null ? double.tryParse(map['price'].toString()) : null,
      oldPrice: map['old_price'] != null ? double.tryParse(map['old_price'].toString()) : null,
      rating: map['rating'] != null ? double.tryParse(map['rating'].toString()) : null,
      ratingCount: map['rating_count'] != null ? int.tryParse(map['rating_count'].toString()) : null,
      promoText: map['promo_text']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class HomeSectionModel {
  final String id;
  final String sectionKey;
  final String title;
  final String? subtitle;
  final String? bannerImageUrl;
  final int sortOrder;
  final bool isActive;
  final List<HomeSectionItemModel> items;

  const HomeSectionModel({
    required this.id,
    required this.sectionKey,
    required this.title,
    this.subtitle,
    this.bannerImageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.items = const [],
  });

  HomeSectionModel copyWith({
    List<HomeSectionItemModel>? items,
  }) {
    return HomeSectionModel(
      id: id,
      sectionKey: sectionKey,
      title: title,
      subtitle: subtitle,
      bannerImageUrl: bannerImageUrl,
      sortOrder: sortOrder,
      isActive: isActive,
      items: items ?? this.items,
    );
  }

  factory HomeSectionModel.fromMap(Map<String, dynamic> map, [List<HomeSectionItemModel> items = const []]) {
    return HomeSectionModel(
      id: map['id']?.toString() ?? '',
      sectionKey: map['section_key']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      bannerImageUrl: map['banner_image_url']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      items: items,
    );
  }
}
