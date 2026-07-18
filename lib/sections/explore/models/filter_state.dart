class FilterState {
  final double? maxDistance; // in km (1.0, 2.0, 3.0, 4.0, 10.0)
  final bool openNow;
  final double? minRating; // (3.0, 4.0, 4.5, 4.7, 5.0)
  final String? priceRange; // ($, $$, $$$, $$$$)
  final bool visited;
  final bool saved;
  final bool newToMe;
  final bool onList;
  final String sortBy; // 'Relevance', 'Distance', 'Rating'
  final bool openAt;
  final bool liked;

  final List<String> goodFor;
  final List<String> features;

  FilterState({
    this.maxDistance,
    this.openNow = false,
    this.minRating,
    this.priceRange,
    this.visited = false,
    this.saved = false,
    this.newToMe = false,
    this.onList = false,
    this.sortBy = 'Relevance',
    this.openAt = false,
    this.liked = false,
    this.goodFor = const [],
    this.features = const [],
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
    String? sortBy,
    bool? openAt,
    bool? liked,
    List<String>? goodFor,
    List<String>? features,
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
      sortBy: sortBy ?? this.sortBy,
      openAt: openAt ?? this.openAt,
      liked: liked ?? this.liked,
      goodFor: goodFor ?? this.goodFor,
      features: features ?? this.features,
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
        onList ||
        sortBy != 'Relevance' ||
        openAt ||
        liked ||
        goodFor.isNotEmpty ||
        features.isNotEmpty;
  }
}
