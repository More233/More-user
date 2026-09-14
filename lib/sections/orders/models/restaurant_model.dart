class RestaurantModel {
  final String id;
  final String name;
  final String businessType;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final bool isActive;
  final bool supportsOrdering;
  final double rating;
  final int reviewsCount;
  final String? logoUrl;
  final String? coverUrl;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final double deliveryFee;
  final double minOrderAmount;
  final String? regionId;
  final List<String> cuisineTypes;
  final bool isFeatured;
  final bool isPromoted;
  final String? offerText;

  const RestaurantModel({
    required this.id,
    required this.name,
    this.businessType = 'restaurant',
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.isActive = true,
    this.supportsOrdering = true,
    this.rating = 4.8,
    this.reviewsCount = 100,
    this.logoUrl,
    this.coverUrl,
    this.deliveryTimeMin = 15,
    this.deliveryTimeMax = 25,
    this.deliveryFee = 0.0,
    this.minOrderAmount = 0.0,
    this.regionId,
    this.cuisineTypes = const [],
    this.isFeatured = false,
    this.isPromoted = false,
    this.offerText,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedCuisines = [];
    if (map['cuisine_types'] != null) {
      if (map['cuisine_types'] is List) {
        parsedCuisines = (map['cuisine_types'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return RestaurantModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      businessType: map['business_type']?.toString() ?? 'restaurant',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 24.7136,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 46.6753,
      address: map['address']?.toString(),
      phone: map['phone']?.toString(),
      isActive: map['is_active'] == true,
      supportsOrdering: map['supports_ordering'] == true,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (map['reviews_count'] as num?)?.toInt() ?? 100,
      logoUrl: map['logo_url']?.toString(),
      coverUrl: map['cover_url']?.toString(),
      deliveryTimeMin: (map['delivery_time_min'] as num?)?.toInt() ?? 15,
      deliveryTimeMax: (map['delivery_time_max'] as num?)?.toInt() ?? 25,
      deliveryFee: (map['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      regionId: map['region_id']?.toString(),
      cuisineTypes: parsedCuisines,
      isFeatured: map['is_featured'] == true,
      isPromoted: map['is_promoted'] == true,
      offerText: map['offer_text']?.toString(),
    );
  }

  String get deliveryTimeFormatted => '$deliveryTimeMin - $deliveryTimeMax دقيقة';

  String get deliveryFeeFormatted =>
      deliveryFee == 0 ? 'مجاني' : '${deliveryFee.toStringAsFixed(0)} ج.م';

  String get reviewsFormatted =>
      reviewsCount >= 1000 ? '+${(reviewsCount / 1000).toStringAsFixed(0)}k' : '($reviewsCount)';
}
