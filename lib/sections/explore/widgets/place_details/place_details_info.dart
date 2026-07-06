import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Widget _buildGreyPillButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F242E),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          place['name']?.toString() ?? 'Maxim Pizza & Restaurant',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F242E),
          ),
        ),
        const SizedBox(height: 4),

        // Metadata Subtitle
        Text(
          "${place['type'] ?? 'Pizzeria'} • ${place['address'] ?? 'Zagazig, Eastern'} • ${place['price'] ?? '\$\$'} • $distanceStr",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 14,
            color: const Color(0xFF82858C),
          ),
        ),
        const SizedBox(height: 8),

        // Overall Rating Row
        Row(
          children: [
            const Icon(
              Icons.sentiment_satisfied_alt,
              color: Color(0xFF1F242E),
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              "$ratingVal",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F242E),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "($reviewsCount)",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: const Color(0xFF82858C),
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
            color: const Color(0xFF1F242E),
          ),
        ),
        const SizedBox(height: 12),

        // Access hours row
        _buildInfoRow(
          icon: Icons.access_time,
          child: Row(
            children: [
              _buildGreyPillButton("Add hours", onAddHoursTap),
            ],
          ),
        ),

        // Phone row
        if (place['phone'] != null && place['phone'].toString().isNotEmpty)
          _buildInfoRow(
            icon: Icons.phone,
            child: Text(
              place['phone'].toString(),
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                color: const Color(0xFF1F242E),
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
                  color: const Color(0xFF1F242E),
                ),
              ),
              const SizedBox(height: 12),

              // Real Google Maps Preview Container
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('place_location_marker'),
                        position: LatLng(lat, lng),
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
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
                        color: const Color(0xFF1F242E),
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
                    color: const Color(0xFF1F242E),
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
