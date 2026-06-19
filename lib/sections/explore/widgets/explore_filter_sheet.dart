import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterState {
  final double? maxDistance; // in km (1.0, 2.0, 3.0, 4.0, 10.0)
  final bool openNow;
  final double? minRating; // (3.0, 4.0, 4.5, 4.7, 5.0)
  final String? priceRange; // ($, $$, $$$, $$$$)
  final bool visited;
  final bool saved;
  final bool newToMe;
  final bool onList;

  FilterState({
    this.maxDistance,
    this.openNow = false,
    this.minRating,
    this.priceRange,
    this.visited = false,
    this.saved = false,
    this.newToMe = false,
    this.onList = false,
  });

  FilterState copyWith({
    double? Function()? maxDistance,
    bool? openNow,
    double? Function()? minRating,
    String? Function()? priceRange,
    bool? visited,
    bool? saved,
    bool? newToMe,
    bool? onList,
  }) {
    return FilterState(
      maxDistance: maxDistance != null ? maxDistance() : this.maxDistance,
      openNow: openNow ?? this.openNow,
      minRating: minRating != null ? minRating() : this.minRating,
      priceRange: priceRange != null ? priceRange() : this.priceRange,
      visited: visited ?? this.visited,
      saved: saved ?? this.saved,
      newToMe: newToMe ?? this.newToMe,
      onList: onList ?? this.onList,
    );
  }

  bool get isModified {
    return maxDistance != null ||
        openNow ||
        minRating != null ||
        priceRange != null ||
        visited ||
        saved ||
        newToMe ||
        onList;
  }
}

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

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3C3C43).withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildChip<T>({
    required String label,
    required T value,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    IconData? icon,
    Widget? prefix,
  }) {
    final bool isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          onChanged(null);
        } else {
          onChanged(value);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE6FC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefix != null) ...[
              prefix,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFF636268),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool isActive,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () {
        onChanged(!isActive);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE6FC) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? const Color(0xFF7C57FC) : const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF82858C),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF7C57FC) : const Color(0xFF636268),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isApplyActive = _state.isModified;

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
              Text(
                "Filters",
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F242E),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _state = FilterState();
                  });
                },
                child: Text(
                  "Reset",
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9E8BFC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content scroll area
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance Section
                  _buildSectionTitle("Distance"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip<double>(
                          label: "1 km",
                          value: 1.0,
                          selectedValue: _state.maxDistance,
                          onChanged: (val) => setState(() => _state = _state.copyWith(maxDistance: () => val)),
                        ),
                        _buildChip<double>(
                          label: "2 km",
                          value: 2.0,
                          selectedValue: _state.maxDistance,
                          onChanged: (val) => setState(() => _state = _state.copyWith(maxDistance: () => val)),
                        ),
                        _buildChip<double>(
                          label: "3 km",
                          value: 3.0,
                          selectedValue: _state.maxDistance,
                          onChanged: (val) => setState(() => _state = _state.copyWith(maxDistance: () => val)),
                        ),
                        _buildChip<double>(
                          label: "4 km",
                          value: 4.0,
                          selectedValue: _state.maxDistance,
                          onChanged: (val) => setState(() => _state = _state.copyWith(maxDistance: () => val)),
                        ),
                        _buildChip<double>(
                          label: "10 km",
                          value: 10.0,
                          selectedValue: _state.maxDistance,
                          onChanged: (val) => setState(() => _state = _state.copyWith(maxDistance: () => val)),
                        ),
                      ],
                    ),
                  ),

                  // Open Now Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Open now",
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3C3C43).withValues(alpha: 0.6),
                          ),
                        ),
                        Switch.adaptive(
                          value: _state.openNow,
                          activeTrackColor: const Color(0xFF7C57FC),
                          onChanged: (val) => setState(() => _state = _state.copyWith(openNow: val)),
                        ),
                      ],
                    ),
                  ),

                  // Rating Section
                  _buildSectionTitle("Rating"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip<double>(
                          label: "5.0",
                          value: 5.0,
                          selectedValue: _state.minRating,
                          onChanged: (val) => setState(() => _state = _state.copyWith(minRating: () => val)),
                          prefix: const Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                        _buildChip<double>(
                          label: "4.7",
                          value: 4.7,
                          selectedValue: _state.minRating,
                          onChanged: (val) => setState(() => _state = _state.copyWith(minRating: () => val)),
                          prefix: const Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                        _buildChip<double>(
                          label: "4.5",
                          value: 4.5,
                          selectedValue: _state.minRating,
                          onChanged: (val) => setState(() => _state = _state.copyWith(minRating: () => val)),
                          prefix: const Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                        _buildChip<double>(
                          label: "4.0",
                          value: 4.0,
                          selectedValue: _state.minRating,
                          onChanged: (val) => setState(() => _state = _state.copyWith(minRating: () => val)),
                          prefix: const Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                        _buildChip<double>(
                          label: "3.0",
                          value: 3.0,
                          selectedValue: _state.minRating,
                          onChanged: (val) => setState(() => _state = _state.copyWith(minRating: () => val)),
                          prefix: const Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                      ],
                    ),
                  ),

                  // Price Section
                  _buildSectionTitle("Price"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChip<String>(
                          label: "\$",
                          value: "\$",
                          selectedValue: _state.priceRange,
                          onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                        ),
                        _buildChip<String>(
                          label: "\$\$",
                          value: "\$\$",
                          selectedValue: _state.priceRange,
                          onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                        ),
                        _buildChip<String>(
                          label: "\$\$\$",
                          value: "\$\$\$",
                          selectedValue: _state.priceRange,
                          onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                        ),
                        _buildChip<String>(
                          label: "\$\$\$\$",
                          value: "\$\$\$\$",
                          selectedValue: _state.priceRange,
                          onChanged: (val) => setState(() => _state = _state.copyWith(priceRange: () => val)),
                        ),
                      ],
                    ),
                  ),

                  // Places Section
                  _buildSectionTitle("Places"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToggleChip(
                          label: "Visited",
                          isActive: _state.visited,
                          onChanged: (val) => setState(() => _state = _state.copyWith(visited: val)),
                          icon: Icons.history,
                        ),
                        _buildToggleChip(
                          label: "Saved",
                          isActive: _state.saved,
                          onChanged: (val) => setState(() => _state = _state.copyWith(saved: val)),
                          icon: Icons.bookmark,
                        ),
                        _buildToggleChip(
                          label: "New to me",
                          isActive: _state.newToMe,
                          onChanged: (val) => setState(() => _state = _state.copyWith(newToMe: val)),
                          icon: Icons.auto_awesome,
                        ),
                        _buildToggleChip(
                          label: "On list",
                          isActive: _state.onList,
                          onChanged: (val) => setState(() => _state = _state.copyWith(onList: val)),
                          icon: Icons.format_list_bulleted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Actions
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF636268),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: isApplyActive
                      ? () {
                          widget.onApply(_state);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isApplyActive ? const Color(0xFF7C57FC) : const Color(0xFF7C57FC).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isApplyActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7C57FC).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Apply",
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
