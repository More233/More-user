import 'dart:convert';

class DeliveryAddressModel {
  final String title;
  final String fullAddress;
  final String details;
  final double latitude;
  final double longitude;
  final bool isCovered;

  const DeliveryAddressModel({
    required this.title,
    required this.fullAddress,
    this.details = '',
    required this.latitude,
    required this.longitude,
    this.isCovered = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'fullAddress': fullAddress,
      'details': details,
      'latitude': latitude,
      'longitude': longitude,
      'isCovered': isCovered,
    };
  }

  factory DeliveryAddressModel.fromMap(Map<String, dynamic> map) {
    return DeliveryAddressModel(
      title: map['title'] as String? ?? 'موقع التوصيل',
      fullAddress: map['fullAddress'] as String? ?? '',
      details: map['details'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 24.7136,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 46.6753,
      isCovered: map['isCovered'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeliveryAddressModel.fromJson(String source) =>
      DeliveryAddressModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
