class DeliveryRegionModel {
  final String id;
  final String name;
  final String? nameEn;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? addressDetails;
  final bool isActive;

  const DeliveryRegionModel({
    required this.id,
    required this.name,
    this.nameEn,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    this.addressDetails,
    this.isActive = true,
  });

  factory DeliveryRegionModel.fromMap(Map<String, dynamic> map) {
    return DeliveryRegionModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      nameEn: map['name_en'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusKm: (map['radius_km'] as num?)?.toDouble() ?? 35.0,
      addressDetails: map['address_details'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'address_details': addressDetails,
      'is_active': isActive,
    };
  }
}
