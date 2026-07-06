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
