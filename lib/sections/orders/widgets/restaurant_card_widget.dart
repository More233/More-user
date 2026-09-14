import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/restaurant_model.dart';
import '../screens/restaurant_details_screen.dart';

class RestaurantCardWidget extends StatefulWidget {
  final RestaurantModel restaurant;
  final VoidCallback? onFavoriteTapped;

  const RestaurantCardWidget({
    super.key,
    required this.restaurant,
    this.onFavoriteTapped,
  });

  @override
  State<RestaurantCardWidget> createState() => _RestaurantCardWidgetState();
}

class _RestaurantCardWidgetState extends State<RestaurantCardWidget> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailsScreen(restaurant: r),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Restaurant Info (Left side in RTL)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Featured Badge
                      if (r.isFeatured) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مميز 🏆',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Name + Pro Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.isPromoted) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C57FC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'pro',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          Flexible(
                            child: Text(
                              r.name,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1E2022),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Delivery & Rating Details row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.deliveryFeeFormatted,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            r.deliveryTimeFormatted,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${r.rating.toStringAsFixed(1)} ★ ${r.reviewsFormatted}',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Offer Badge Pill
                      if (r.offerText != null && r.offerText!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: r.isPromoted
                                ? const Color(0xFF7C57FC)
                                : const Color(0xFFCCFF00), // Lime green offer badge
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (r.isPromoted) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'pro',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF7C57FC),
                                    ),
                                  ),
                                ),
                              ],
                              Text(
                                r.offerText!,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: r.isPromoted ? Colors.white : const Color(0xFF1E2022),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // 2. Restaurant Logo Image Box (Right side in RTL)
                Stack(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: r.logoUrl != null && r.logoUrl!.isNotEmpty
                            ? Image.network(
                                r.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),

                    // Favorite Heart Icon Button
                    Positioned(
                      top: 4,
                      left: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          widget.onFavoriteTapped?.call();
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 15,
                            color: _isFavorite ? const Color(0xFFE11D48) : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),

                    // Ad / إعلان Badge if sponsored
                    if (r.isPromoted)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A651).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'إعلان',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF1F1F1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: Color(0xFF0284C7), size: 30),
      ),
    );
  }
}
