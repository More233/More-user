import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../config/secrets.dart';

class PlaceDetailsInfo extends StatelessWidget {
  final Map<String, dynamic> place;
  final num ratingVal;
  final int reviewsCount;
  final String distanceStr;
  final double lat;
  final double lng;
  final VoidCallback onAddHoursTap;
  final VoidCallback onSuggestEditTap;
  final VoidCallback onSeeMoreInfoTap;

  const PlaceDetailsInfo({
    super.key,
    required this.place,
    required this.ratingVal,
    required this.reviewsCount,
    required this.distanceStr,
    required this.lat,
    required this.lng,
    required this.onAddHoursTap,
    required this.onSuggestEditTap,
    required this.onSeeMoreInfoTap,
  });

  Widget _buildInfoRow({
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF82858C),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildGreyPillButton(String label, VoidCallback onTap, {bool isDark = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2430) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F242E),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1F242E);
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF82858C);
    final Color borderColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          place['name']?.toString() ?? 'Maxim Pizza & Restaurant',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),

        // Metadata Subtitle
        Text(
          "${place['type'] ?? 'Pizzeria'} • ${place['address'] ?? 'Zagazig, Eastern'} • ${place['price'] ?? '\$\$'} • $distanceStr",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            color: textMutedColor,
          ),
        ),
        const SizedBox(height: 8),

        // Overall Rating Row
        Row(
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              "$ratingVal",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "($reviewsCount)",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: textMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // About Header Title
        Text(
          "About",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Access hours row
        () {
          final weekdayText = place['weekdayText'] as List<dynamic>?;
          String? todayHours;
          if (weekdayText != null && weekdayText.length >= 7) {
            final int weekday = DateTime.now().weekday; // 1 (Mon) - 7 (Sun)
            final rawDayText = weekdayText[weekday - 1].toString();
            final colonIndex = rawDayText.indexOf(':');
            if (colonIndex != -1) {
              todayHours = rawDayText.substring(colonIndex + 1).trim();
            } else {
              todayHours = rawDayText;
            }
          }

          final bool? openNow = place['openNow'] as bool?;

          return _buildInfoRow(
            icon: Icons.access_time,
            child: todayHours != null
                ? Row(
                    children: [
                      Text(
                        todayHours,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (openNow != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: openNow
                                ? (isDark ? const Color(0xFF133F1F) : const Color(0xFFE6F7ED))
                                : (isDark ? const Color(0xFF5F1F1F) : const Color(0xFFFDECEB)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            openNow ? "Open Now" : "Closed",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: openNow
                                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                                  : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      _buildGreyPillButton("Add opening hours", onAddHoursTap, isDark: isDark),
                    ],
                  ),
          );
        }(),

        // Phone row
        if (place['phone'] != null && place['phone'].toString().isNotEmpty)
          _buildInfoRow(
            icon: Icons.phone,
            child: Text(
              place['phone'].toString(),
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                color: textColor,
              ),
            ),
          ),

        // Website row
        if (place['website'] != null && place['website'].toString().isNotEmpty)
          _buildInfoRow(
            icon: Icons.language,
            child: GestureDetector(
              onTap: () async {
                final url = place['website'].toString();
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                place['website'].toString(),
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  color: const Color(0xFF7C57FC),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

        // Address and Map preview row
        _buildInfoRow(
          icon: Icons.location_on,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place['address']?.toString().isNotEmpty == true
                    ? place['address'].toString()
                    : (place['name']?.toString() ?? 'Zagazig'),
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Real Mapbox Map Preview Container
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      _MiniMapPreview(
                        lat: lat,
                        lng: lng,
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                      const Center(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Suggest edit
              GestureDetector(
                onTap: onSuggestEditTap,
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Color(0xFF82858C), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Suggest an edit",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // See more info button link
        GestureDetector(
          onTap: onSeeMoreInfoTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "See more information",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF82858C)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMapPreview extends StatefulWidget {
  final double lat;
  final double lng;
  final bool isDark;

  const _MiniMapPreview({
    required this.lat,
    required this.lng,
    required this.isDark,
  });

  @override
  State<_MiniMapPreview> createState() => _MiniMapPreviewState();
}

class _MiniMapPreviewState extends State<_MiniMapPreview> {
  mapbox.MapboxMap? _mapController;
  bool? _lastIsDark;

  @override
  Widget build(BuildContext context) {
    if (_lastIsDark != null && _lastIsDark != widget.isDark) {
      _lastIsDark = widget.isDark;
      if (_mapController != null) {
        final newStyle = widget.isDark
            ? "mapbox://styles/mapbox/dark-v11"
            : "mapbox://styles/basiii/cmri3vcu7007401qr2y7l5bue";
        _mapController!.style.setStyleURI(newStyle);
      }
    } else {
      _lastIsDark = widget.isDark;
    }

    return mapbox.MapWidget(
      key: const ValueKey('place_details_mini_map_key'),
      resourceOptions: mapbox.ResourceOptions(accessToken: const String.fromEnvironment("MAPBOX_ACCESS_TOKEN", defaultValue: Secrets.mapboxAccessToken)),
      styleUri: widget.isDark
          ? "mapbox://styles/mapbox/dark-v11"
          : "mapbox://styles/basiii/cmri3vcu7007401qr2y7l5bue",
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(widget.lng, widget.lat)).toJson(),
        zoom: 15.0,
      ),
      onMapCreated: (controller) async {
        _mapController = controller;
        await controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
        await controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
      },
      onStyleLoadedListener: (styleLoaded) async {
        if (_mapController != null) {
          try {
            final layers = await _mapController!.style.getStyleLayers();
            const List<String> hideKeywords = [
              'poi', 'transit', 'rail', 'bus', 'station', 'ferry', 'shield', 'motorway',
              'number', 'crossing', 'traffic', 'landmark', 'symbol', 'monument', 'worship',
              'cemetery', 'lodging', 'hotel', 'restaurant', 'cafe', 'shop', 'food',
              'beverage', 'intersection', 'entrance', 'parking'
            ];
            for (final layerInfo in layers) {
              if (layerInfo != null) {
                final idLower = layerInfo.id.toLowerCase();
                if (idLower.contains('pointannotation') || idLower.contains('annotation')) {
                  continue;
                }
                bool shouldHide = false;
                for (final keyword in hideKeywords) {
                  if (idLower.contains(keyword)) {
                    shouldHide = true;
                    break;
                  }
                }
                if (shouldHide) {
                  await _mapController!.style.setStyleLayerProperty(
                    layerInfo.id,
                    'visibility',
                    'none',
                  );
                }
              }
            }
          } catch (_) {}
        }
      },
    );
  }
}
