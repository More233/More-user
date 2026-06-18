import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/dynamic_place_image.dart';

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
  late String _imageUrl;
  List<dynamic> _visitors = [];

  @override
  void initState() {
    super.initState();
    _isSaved = widget.place['isSaved'] as bool? ?? false;
    _imageUrl = widget.place['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500';
    _visitors = List.from(widget.place['visitors'] as Iterable? ?? []);
    _loadLatestPhoto();
    _fetchRealVisitors();
  }

  Future<void> _loadLatestPhoto() async {
    // Photos are preloaded on the explore screen using the Foursquare v2 explore endpoint
    // to avoid credits_exhausted errors (402) on individual place details calls.
  }

  Future<void> _fetchRealVisitors() async {
    final placeId = widget.place['id']?.toString();
    if (placeId == null || placeId.isEmpty) return;

    try {
      final client = Supabase.instance.client;
      final visitorsRes = await client
          .from('posts')
          .select('*, author:profiles(*)')
          .eq('place_id', placeId)
          .eq('is_private', false)
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        final list = List<Map<String, dynamic>>.from(visitorsRes as List);
        final List<Map<String, dynamic>> parsedVisitors = [];
        for (final v in list) {
          final author = v['author'] as Map<String, dynamic>?;
          if (author != null) {
            final String name = '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim();
            parsedVisitors.add({
              'name': name.isEmpty ? 'Anonymous' : name,
              'avatarUrl': author['avatar_url'] as String?,
            });
          }
        }
        
        final seen = <String>{};
        final uniqueVisitors = <Map<String, dynamic>>[];
        for (final visitor in parsedVisitors) {
          final name = visitor['name'] as String;
          if (!seen.contains(name)) {
            seen.add(name);
            uniqueVisitors.add(visitor);
          }
        }

        setState(() {
          _visitors = uniqueVisitors;
        });
      }
    } catch (e) {
      debugPrint("Error fetching visitors in details screen: $e");
    }
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
              DynamicPlaceImage(
                placeId: place['id']?.toString() ?? '',
                placeName: place['name']?.toString() ?? '',
                iconUrl: place['iconUrl']?.toString(),
                imageUrl: _imageUrl,
                width: double.infinity,
                height: 300,
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
                          place['name']?.toString() ?? '',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place['price']?.toString() ?? r'$$',
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
                        "${place['type'] ?? 'Other'} • ${place['address'] ?? ''}",
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 16,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${place['rating'] ?? '4.5'} (${place['reviewsCount'] ?? '25'} reviews)",
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
                  if (_visitors.isNotEmpty) ...[
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
                          width: _visitors.length == 1 ? 32.0 : (_visitors.length == 2 ? 50.0 : 72.0),
                          height: 32,
                          child: Stack(
                            children: List.generate(_visitors.length > 3 ? 3 : _visitors.length, (index) {
                              final visitor = _visitors[index] as Map<String, dynamic>;
                              final avatarUrl = visitor['avatarUrl'] as String?;
                              
                              Widget avatarChild;
                              if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                avatarChild = CircleAvatar(
                                  radius: 15,
                                  backgroundImage: NetworkImage(avatarUrl),
                                );
                              } else {
                                final initials = visitor['name'].toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
                                avatarChild = CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFFEDE6FC),
                                  child: Text(
                                    initials.isNotEmpty ? initials : '?',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C57FC)),
                                  ),
                                );
                              }
                              
                              return Positioned(
                                  left: index * 18.0,
                                  child: CircleAvatar(
                                    radius: 16,
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
                              final visitorsList = List<Map<String, dynamic>>.from(_visitors);
                              final int count = visitorsList.length;
                              String text = '';
                              if (count == 1) {
                                text = '${visitorsList[0]['name']} checked in here today.';
                              } else if (count == 2) {
                                text = '${visitorsList[0]['name']} and ${visitorsList[1]['name']} checked in here today.';
                              } else {
                                text = '${visitorsList[0]['name']}, ${visitorsList[1]['name']} and ${count - 2} others checked in here today.';
                              }
                              return Text(
                                text,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
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
                        (place['actionType'] == 'check-in') ? 'Check-in' : (place['actionType'] as String? ?? 'Order'),
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
