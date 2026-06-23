class CollectionModel {
  final String id;
  final String name;
  final String? coverImageUrl;
  final List<String> postIds;
  final bool isPrivate;
  final List<String> sharedUserIds;

  CollectionModel({
    required this.id,
    required this.name,
    this.coverImageUrl,
    required this.postIds,
    this.isPrivate = true,
    this.sharedUserIds = const [],
  });

  CollectionModel copyWith({
    String? id,
    String? name,
    String? Function()? coverImageUrl,
    List<String>? postIds,
    bool? isPrivate,
    List<String>? sharedUserIds,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImageUrl: coverImageUrl != null ? coverImageUrl() : this.coverImageUrl,
      postIds: postIds ?? this.postIds,
      isPrivate: isPrivate ?? this.isPrivate,
      sharedUserIds: sharedUserIds ?? this.sharedUserIds,
    );
  }
}
