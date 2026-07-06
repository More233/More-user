class PlaceDetailsState {
  final bool isSaved;
  final List<String> images;
  final int currentPage;
  final List<Map<String, dynamic>> visitors;
  final bool hasCheckedIn;
  final int? selectedRatingIndex;
  final List<Map<String, dynamic>> placePosts;
  final List<String> peopleImages;
  final List<Map<String, dynamic>> similarPlaces;
  final bool isLoadingPosts;
  final bool isLoadingSimilar;

  PlaceDetailsState({
    required this.isSaved,
    required this.images,
    required this.currentPage,
    required this.visitors,
    required this.hasCheckedIn,
    this.selectedRatingIndex,
    required this.placePosts,
    required this.peopleImages,
    required this.similarPlaces,
    required this.isLoadingPosts,
    required this.isLoadingSimilar,
  });

  factory PlaceDetailsState.initial({required Map<String, dynamic> place, required List<String> initialImages}) {
    final rawVisitors = place['visitors'] as List?;
    final visitorsList = rawVisitors != null
        ? List<Map<String, dynamic>>.from(rawVisitors.map((v) => Map<String, dynamic>.from(v as Map)))
        : <Map<String, dynamic>>[];

    return PlaceDetailsState(
      isSaved: place['isSaved'] as bool? ?? false,
      images: initialImages,
      currentPage: 0,
      visitors: visitorsList,
      hasCheckedIn: false,
      selectedRatingIndex: null,
      placePosts: [],
      peopleImages: [],
      similarPlaces: [],
      isLoadingPosts: false,
      isLoadingSimilar: false,
    );
  }

  PlaceDetailsState copyWith({
    bool? isSaved,
    List<String>? images,
    int? currentPage,
    List<Map<String, dynamic>>? visitors,
    bool? hasCheckedIn,
    int? Function()? selectedRatingIndex,
    List<Map<String, dynamic>>? placePosts,
    List<String>? peopleImages,
    List<Map<String, dynamic>>? similarPlaces,
    bool? isLoadingPosts,
    bool? isLoadingSimilar,
  }) {
    return PlaceDetailsState(
      isSaved: isSaved ?? this.isSaved,
      images: images ?? this.images,
      currentPage: currentPage ?? this.currentPage,
      visitors: visitors ?? this.visitors,
      hasCheckedIn: hasCheckedIn ?? this.hasCheckedIn,
      selectedRatingIndex: selectedRatingIndex != null ? selectedRatingIndex() : this.selectedRatingIndex,
      placePosts: placePosts ?? this.placePosts,
      peopleImages: peopleImages ?? this.peopleImages,
      similarPlaces: similarPlaces ?? this.similarPlaces,
      isLoadingPosts: isLoadingPosts ?? this.isLoadingPosts,
      isLoadingSimilar: isLoadingSimilar ?? this.isLoadingSimilar,
    );
  }
}
