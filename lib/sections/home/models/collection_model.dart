class CollectionModel {
  final String id;
  final String name;
  final String? coverImageUrl;
  final List<String> postIds;
  final bool isPrivate;

  CollectionModel({
    required this.id,
    required this.name,
    this.coverImageUrl,
    required this.postIds,
    this.isPrivate = true,
  });

  CollectionModel copyWith({
    String? id,
    String? name,
    String? Function()? coverImageUrl,
    List<String>? postIds,
    bool? isPrivate,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImageUrl: coverImageUrl != null ? coverImageUrl() : this.coverImageUrl,
      postIds: postIds ?? this.postIds,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
