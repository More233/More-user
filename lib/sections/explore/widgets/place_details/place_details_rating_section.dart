import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceRatingSection extends StatefulWidget {
  final String ratingVal;
  final String reviewsCount;
  final Function(int) onRatingSubmitted;

  const PlaceRatingSection({
    super.key,
    required this.ratingVal,
    required this.reviewsCount,
    required this.onRatingSubmitted,
  });

  @override
  State<PlaceRatingSection> createState() => _PlaceRatingSectionState();
}

class _PlaceRatingSectionState extends State<PlaceRatingSection> {
  int? _selectedRatingIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Rating",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F242E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ratings summary and progress bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ratingVal,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F242E),
                  ),
                ),
                Text(
                  "${widget.reviewsCount} ratings",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildRatingRow(
                    icon: Icons.sentiment_satisfied_alt,
                    progress: 0.8,
                    count: "24",
                  ),
                  _buildRatingRow(
                    icon: Icons.sentiment_neutral,
                    progress: 0.2,
                    count: "6",
                  ),
                  _buildRatingRow(
                    icon: Icons.sentiment_very_dissatisfied,
                    progress: 0.05,
                    count: "1",
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rating community guide box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.face,
                color: Color(0xFF82858C),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Your review will serve as a guide to your friends and the Swarm community.",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: const Color(0xFF636268),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Smiley Face selectors
        Row(
          children: [
            _buildRateOption(0, Icons.sentiment_very_dissatisfied, "Bad"),
            _buildRateOption(1, Icons.sentiment_satisfied, "Okay"),
            _buildRateOption(2, Icons.sentiment_very_satisfied, "Great"),
          ],
        ),
        const SizedBox(height: 12),

        // Submit Rating Button
        GestureDetector(
          onTap: () {
            if (_selectedRatingIndex != null) {
              widget.onRatingSubmitted(_selectedRatingIndex!);
            }
          },
          child: Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF7C57FC),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              "Submit",
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow({
    required IconData icon,
    required double progress,
    required String count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF82858C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF5F6F8),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            count,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF82858C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateOption(int index, IconData icon, String label) {
    final bool isSelected = _selectedRatingIndex == index;

    Color activeColor;
    Color activeBgColor;
    if (index == 0) {
      activeColor = const Color(0xFFF44336); // Red
      activeBgColor = const Color(0xFFFFEBEE);
    } else if (index == 1) {
      activeColor = const Color(0xFFFF9800); // Amber
      activeBgColor = const Color(0xFFFFF3E0);
    } else {
      activeColor = const Color(0xFF7C57FC); // Purple
      activeBgColor = const Color(0xFFEDE6FC);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRatingIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 6,
            right: index == 2 ? 0 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : const Color(0xFF82858C),
                size: 32,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
