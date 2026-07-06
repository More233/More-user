import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/interest_item.dart';

class InterestsStep extends StatefulWidget {
  final void Function(List<String> interests) onCompleted;
  final void Function(List<String> interests) onSkip;

  const InterestsStep({
    super.key,
    required this.onCompleted,
    required this.onSkip,
  });

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  static const List<InterestItem> _interests = [
    InterestItem('Coffee', 'assets/Auth Section/icons/coffee_02.svg'),
    InterestItem('Restaurants', 'assets/Auth Section/icons/restaurant_03.svg'),
    InterestItem('Bakeries', 'assets/Auth Section/icons/cupcake_02.svg'),
    InterestItem('Night spots', 'assets/Auth Section/icons/drink.svg'),
    InterestItem('Work spots', 'assets/Auth Section/icons/work.svg'),
    InterestItem('Outdoor', 'assets/Auth Section/icons/tree_02.svg'),
    InterestItem('Shopping', 'assets/Auth Section/icons/shopping_bag_01.svg'),
    InterestItem('Events', 'assets/Auth Section/icons/calendar_03.svg'),
    InterestItem('Family places', 'assets/Auth Section/icons/user_multiple_1.svg'),
    InterestItem('Hidden gems', 'assets/Auth Section/icons/gem.svg'),
    InterestItem('Desserts', 'assets/Auth Section/icons/ice_cream_02.svg'),
    InterestItem('Brunch', 'assets/Auth Section/icons/croissant.svg'),
  ];

  final Set<int> _selectedIndices = {};

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Widget _buildTag(int index) {
    final item = _interests[index];
    final isSelected = _selectedIndices.contains(index);

    return GestureDetector(
      onTap: () => _toggleSelection(index),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE6FC) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              item.iconPath,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF7C57FC) : const Color(0xFF4A4A4A),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF4A4A4A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedIndices.length >= 3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/Splash/logo.svg',
          width: 120,
          height: 38,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Color(0xFF7C57FC),
            BlendMode.srcIn,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Text(
                      'What are you into?',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick a few interests so More can\nsuggest better places.',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),
                    // Grid of tags (aligned 3 next to each other matching Figma)
                    Column(
                      children: [
                        for (int i = 0; i < _interests.length; i += 3) ...[
                          Row(
                            children: [
                              Expanded(child: _buildTag(i)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTag(i + 1)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTag(i + 2)),
                            ],
                          ),
                          if (i < _interests.length - 3) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Helper info
                    Text(
                      'Choose at least 3 (${_selectedIndices.length} selected)',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: canContinue ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Magic AI personalization banner
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B60FC).withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE6FC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(10),
                            child: SvgPicture.asset(
                              'assets/Auth Section/icons/ai_magic.svg',
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF7C57FC),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Based on your picks, we\'ll personalize places, bookings, and recommendations.',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6B7280),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Opacity(
                      opacity: canContinue ? 1.0 : 0.7,
                      child: ElevatedButton(
                        onPressed: canContinue
                            ? () {
                                final selectedList = _selectedIndices.map((i) => _interests[i].label).toList();
                                widget.onCompleted(selectedList);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C57FC),
                          disabledBackgroundColor: const Color(0xFF7C57FC).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => widget.onSkip([]),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C7C7C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
