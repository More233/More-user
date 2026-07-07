import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExploreMapWidget extends StatelessWidget {
  final String? mapStyleJson;
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Heatmap> heatmaps;
  final bool myLocationEnabled;
  final MapCreatedCallback? onMapCreated;
  final CameraPositionCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final ArgumentCallback<LatLng>? onTap;
  final ArgumentCallback<LatLng>? onLongPress;

  const ExploreMapWidget({
    super.key,
    this.mapStyleJson,
    required this.initialCameraPosition,
    required this.markers,
    required this.heatmaps,
    required this.myLocationEnabled,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      onMapCreated: (controller) {
        if (mapStyleJson != null) {
          // ignore: deprecated_member_use
          controller.setMapStyle(mapStyleJson);
        }
        if (onMapCreated != null) {
          onMapCreated!(controller);
        }
      },
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: false,
      markers: markers,
      heatmaps: heatmaps,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
