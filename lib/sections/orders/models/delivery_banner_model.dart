class DeliveryBannerModel {
  final String id;
  final String? regionId;
  final String? title;
  final String imageUrl;
  final String? linkUrl;
  final int sortOrder;
  final bool isActive;

  const DeliveryBannerModel({
    required this.id,
    this.regionId,
    this.title,
    required this.imageUrl,
    this.linkUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory DeliveryBannerModel.fromMap(Map<String, dynamic> map) {
    return DeliveryBannerModel(
      id: map['id'] as String,
      regionId: map['region_id'] as String?,
      title: map['title'] as String?,
      imageUrl: map['image_url'] as String? ?? '',
      linkUrl: map['link_url'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'region_id': regionId,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
