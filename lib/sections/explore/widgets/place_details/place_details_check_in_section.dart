import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaceDetailsCheckInSection extends StatelessWidget {
  final List<Map<String, dynamic>> visitors;
  final bool hasCheckedIn;
  final VoidCallback onCheckInTap;

  const PlaceDetailsCheckInSection({
    super.key,
    required this.visitors,
    required this.hasCheckedIn,
    required this.onCheckInTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Who's here now",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F242E),
          ),
        ),
        const SizedBox(height: 12),
        if (visitors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  color: Color(0xFF82858C),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  "No one has checked in yet. Be the first to check in!",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF636268),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onCheckInTap,
                  icon: const Icon(Icons.location_on, size: 16, color: Colors.white),
                  label: Text(
                    "Check In",
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               color: const Color(0xFFF5F6F8),
               borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: visitors.length == 1 ? 24.0 : (visitors.length == 2 ? 38.0 : 52.0),
                  height: 24,
                  child: Stack(
                    children: List.generate(visitors.length > 3 ? 3 : visitors.length, (index) {
                      final visitor = visitors[index];
                      final avatarUrl = visitor['avatarUrl'] as String?;
                      
                      Widget avatarChild;
                      if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        avatarChild = CircleAvatar(
                          radius: 11,
                          backgroundImage: CachedNetworkImageProvider(avatarUrl),
                        );
                      } else {
                        final initials = visitor['name']
                            .toString()
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase();
                        avatarChild = CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFFEDE6FC),
                          child: Text(
                            initials.isNotEmpty ? initials : '?',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C57FC),
                            ),
                          ),
                        );
                      }
                      
                      return Positioned(
                        left: index * 14.0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: avatarChild,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final int count = visitors.length;
                      String text = '';
                      if (count == 1) {
                        text = '${visitors[0]['name']} is here now.';
                      } else if (count == 2) {
                        text = '${visitors[0]['name']} and ${visitors[1]['name']} are here.';
                      } else {
                        text = '${visitors[0]['name']}, ${visitors[1]['name']} and ${count - 2} others are here.';
                      }
                      return Text(
                        text,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13,
                          color: const Color(0xFF636268),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                  ),
                ),
                if (!hasCheckedIn) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onCheckInTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE6FC),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        "Check In",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
