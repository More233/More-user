class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

class CameraPosition {
  final LatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  const CameraPosition({
    required this.target,
    this.zoom = 0.0,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });
}
