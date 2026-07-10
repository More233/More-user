import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceTipsSection extends StatelessWidget {
  final List<Map<String, dynamic>> placePosts;

  const PlaceTipsSection({
    super.key,
    required this.placePosts,
  });

  void _showAllTipsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Tips & Comments",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F242E),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: placePosts.length,
                    itemBuilder: (context, index) {
                      final post = placePosts[index];
                      final author = post['author'] as Map<String, dynamic>?;
                      final String authorName = author != null
                          ? '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim()
                          : 'Anonymous';
                      final String? avatarUrl = author?['avatar_url'] as String?;
                      final String tipText = post['description'] as String? ?? post['title'] as String? ?? '';
                      
                      if (tipText.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipOval(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: const Color(0xFFF5F6F8),
                                    child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                                        ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.person, color: Color(0xFF82858C), size: 20);
                                            },
                                          )
                                        : const Icon(Icons.person, color: Color(0xFF82858C), size: 20),
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFAE34), // Gold/Orange star badge
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authorName,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F242E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tipText,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13,
                                      color: const Color(0xFF636268),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (placePosts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What people are saying",
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F242E),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: placePosts.length > 3 ? 3 : placePosts.length,
          itemBuilder: (context, index) {
            final post = placePosts[index];
            final author = post['author'] as Map<String, dynamic>?;
            final String authorName = author != null
                ? '${author['first_name'] ?? ''} ${author['last_name'] ?? ''}'.trim()
                : 'Anonymous';
            final String? avatarUrl = author?['avatar_url'] as String?;
            final String tipText = post['description'] as String? ?? post['title'] as String? ?? '';
            
            if (tipText.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 40,
                          height: 40,
                          color: const Color(0xFFF5F6F8),
                          child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, color: Color(0xFF82858C), size: 20);
                                  },
                                )
                              : const Icon(Icons.person, color: Color(0xFF82858C), size: 20),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFAE34), // Gold/Orange star badge
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F242E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tipText,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            color: const Color(0xFF636268),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (placePosts.length > 3) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showAllTipsDialog(context),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(
                "See all ${placePosts.length} tips",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F242E),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
