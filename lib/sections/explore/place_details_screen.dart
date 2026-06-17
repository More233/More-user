import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback onActionTriggered;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.onActionTriggered,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.place['isSaved'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final place = widget.place;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Hero Header Image Stack
          Stack(
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(place['imageUrl'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Fade Gradient overlay at bottom of image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.9, 1.0],
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: topPadding + 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF333333),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Bookmark button
              Positioned(
                top: topPadding + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                      place['isSaved'] = _isSaved;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: const Color(0xFF7C57FC),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Details Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place['name'] as String,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place['price'] as String,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C57FC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Subtitle & Rating
                  Row(
                    children: [
                      Text(
                        "${place['type']} • ${place['address']}",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${place['rating']} (${place['reviewsCount']} reviews)",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),

                  // About / Overview Section
                  Text(
                    "Overview",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Serdab is a highly-rated space offering premium coffee blends, artisanal pastries, and a relaxing lounge environment. Featuring local artists, quiet workspaces, and top-tier baristas, it has become one of Riyadh's most popular destinations for professionals and creatives alike.",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),

                  // Location / Distance details
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDE6FC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF7C57FC),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Distance",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            Text(
                              "Located ${place['distance']} away from your current position.",
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 13,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFE8E8E8)),

                  // Activity / Visitors
                  Text(
                    "Who's here now",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Avatars overlap
                      SizedBox(
                        width: 72,
                        height: 32,
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100'),
                            ),
                            Positioned(
                              left: 18,
                              child: const CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100'),
                              ),
                            ),
                            Positioned(
                              left: 36,
                              child: const CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Maya, Ali, Omar and ${(place['peopleCount'] as int) - 3} others checked in here today.",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Bottom primary Action Button
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding > 0 ? bottomPadding + 8 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onActionTriggered();
                    },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C57FC),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        place['actionType'] as String,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
