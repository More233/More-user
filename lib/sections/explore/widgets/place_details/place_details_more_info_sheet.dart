import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsMoreInfoSheet extends StatelessWidget {
  final Map<String, dynamic> place;
  final double lat;
  final double lng;

  const PlaceDetailsMoreInfoSheet({
    super.key,
    required this.place,
    required this.lat,
    required this.lng,
  });

  Widget _buildModalDetailRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7C57FC), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: const Color(0xFF82858C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              isLink
                  ? GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(value);
                        if (uri != null) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Text(
                        value,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF7C57FC),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC1C1C1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "More information",
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F242E),
            ),
          ),
          const SizedBox(height: 20),
          _buildModalDetailRow(Icons.storefront_outlined, "Name", place['name']?.toString() ?? 'N/A'),
          const Divider(height: 24, color: Color(0xFFE8E8E8)),
          _buildModalDetailRow(Icons.category_outlined, "Category", place['type']?.toString() ?? 'Other'),
          const Divider(height: 24, color: Color(0xFFE8E8E8)),
          _buildModalDetailRow(Icons.location_on_outlined, "Address", place['address']?.toString() ?? 'Zagazig'),
          const Divider(height: 24, color: Color(0xFFE8E8E8)),
          _buildModalDetailRow(Icons.pin_drop_outlined, "Coordinates", "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}"),
          if (place['phone'] != null && place['phone'].toString().isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFE8E8E8)),
            _buildModalDetailRow(Icons.phone_outlined, "Phone", place['phone'].toString()),
          ],
          if (place['website'] != null && place['website'].toString().isNotEmpty) ...[
            const Divider(height: 24, color: Color(0xFFE8E8E8)),
            _buildModalDetailRow(Icons.language_outlined, "Website", place['website'].toString(), isLink: true),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
