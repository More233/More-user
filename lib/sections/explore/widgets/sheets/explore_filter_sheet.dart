import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/filter_state.dart';

class ExploreFilterSheet extends StatefulWidget {
  final FilterState initialState;
  final ValueChanged<FilterState> onApply;

  const ExploreFilterSheet({
    super.key,
    required this.initialState,
    required this.onApply,
  });

  @override
  State<ExploreFilterSheet> createState() => _ExploreFilterSheetState();
}

class _ExploreFilterSheetState extends State<ExploreFilterSheet> {
  late FilterState _state;
  bool _isGoodForExpanded = false;
  bool _isFeaturesExpanded = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildFilterButton<T>({
    required String label,
    required T value,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
  }) {
    final bool isSelected = value == selectedValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            onChanged(null);
          } else {
            onChanged(value);
          }
        },
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isActive,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        onChanged(!isActive);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF1A1A2E),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipList({
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return GestureDetector(
          onTap: () {
            final newList = List<String>.from(selectedOptions);
            if (isSelected) {
              newList.remove(option);
            } else {
              newList.add(option);
            }
            onChanged(newList);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7C57FC) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
                width: 1,
              ),
            ),
            child: Text(
              option,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortBySelector() {
    final options = ['Relevance', 'Distance', 'Rating'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _state.sortBy == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _state = _state.copyWith(sortBy: opt);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC4C4C4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 36), // Spacer for centering
              Text(
                "Filter",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F3F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF1A1A2E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Scroll Area
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  _buildSectionTitle("Sort by"),
                  _buildSortBySelector(),

                  // Price
                  _buildSectionTitle("Price"),
                  Row(
                    children: [
                      _buildFilterButton<String>(
                        label: "\$",
                        value: "\$",
                        selectedValue: _state.priceRange,
                        onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                      ),
                      _buildFilterButton<String>(
                        label: "\$\$",
                        value: "\$\$",
                        selectedValue: _state.priceRange,
                        onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                      ),
                      _buildFilterButton<String>(
                        label: "\$\$\$",
                        value: "\$\$\$",
                        selectedValue: _state.priceRange,
                        onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                      ),
                      _buildFilterButton<String>(
                        label: "\$\$\$\$",
                        value: "\$\$\$\$",
                        selectedValue: _state.priceRange,
                        onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                      ),
                    ],
                  ),

                  // Time
                  _buildSectionTitle("Time"),
                  Row(
                    children: [
                      _buildFilterButton<bool>(
                        label: "Open now",
                        value: true,
                        selectedValue: _state.openNow ? true : null,
                        onChanged: (val) => setState(() => _state = _state.copyWith(openNow: val ?? false)),
                      ),
                      _buildFilterButton<bool>(
                        label: "Open at",
                        value: true,
                        selectedValue: _state.openAt ? true : null,
                        onChanged: (val) => setState(() => _state = _state.copyWith(openAt: val ?? false)),
                      ),
                    ],
                  ),

                  // Places
                  _buildSectionTitle("Places"),
                  Wrap(
                    children: [
                      _buildToggleChip(
                        label: "Visited",
                        isActive: _state.visited,
                        icon: Icons.history,
                        onChanged: (val) => setState(() => _state = _state.copyWith(visited: val)),
                      ),
                      _buildToggleChip(
                        label: "New to me",
                        isActive: _state.newToMe,
                        icon: Icons.explore,
                        onChanged: (val) => setState(() => _state = _state.copyWith(newToMe: val)),
                      ),
                      _buildToggleChip(
                        label: "Saved",
                        isActive: _state.saved,
                        icon: Icons.bookmark,
                        onChanged: (val) => setState(() => _state = _state.copyWith(saved: val)),
                      ),
                      _buildToggleChip(
                        label: "Liked",
                        isActive: _state.liked,
                        icon: Icons.sentiment_satisfied_alt,
                        onChanged: (val) => setState(() => _state = _state.copyWith(liked: val)),
                      ),
                      _buildToggleChip(
                        label: "On my list",
                        isActive: _state.onList,
                        icon: Icons.format_list_bulleted,
                        onChanged: (val) => setState(() => _state = _state.copyWith(onList: val)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F3F5)),

                  // Good For
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isGoodForExpanded = !_isGoodForExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Good for",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Icon(
                            _isGoodForExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isGoodForExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildFilterChipList(
                        options: ['Brunch', 'Date', 'Quiet', 'Large groups'],
                        selectedOptions: _state.goodFor,
                        onChanged: (newList) {
                          setState(() {
                            _state = _state.copyWith(goodFor: newList);
                          });
                        },
                      ),
                    ),
                  ],
                  const Divider(color: Color(0xFFF1F3F5)),

                  // Features
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _isFeaturesExpanded = !_isFeaturesExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Features",
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Icon(
                            _isFeaturesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isFeaturesExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildFilterChipList(
                        options: ['Wi-Fi', 'Outdoor seating', 'Delivery'],
                        selectedOptions: _state.features,
                        onChanged: (newList) {
                          setState(() {
                            _state = _state.copyWith(features: newList);
                          });
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Bar (Clear All / Apply)
          Container(
            padding: EdgeInsets.only(bottom: bottomPadding + 8, top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _state = FilterState();
                    });
                  },
                  child: Text(
                    "Clear all",
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_state);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C57FC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Apply",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
