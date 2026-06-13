class TimelineComment {
  final String authorName;
  final String authorAvatar;
  final String commentText;
  final String timeAgo;
  bool isLiked;
  int likesCount;

  TimelineComment({
    required this.authorName,
    required this.authorAvatar,
    required this.commentText,
    required this.timeAgo,
    this.isLiked = false,
    this.likesCount = 0,
  });
}

enum CategoryIconType {
  coffee,
  building,
  camera,
}

class TimelinePost {
  final String id;
  final String title;
  final String categoryName;
  final String locationAddress;
  final int visitorCount;
  final String postTime;
  final String description;
  final String? imageUrl;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool isBookmarked;
  final CategoryIconType categoryIcon;
  final List<TimelineComment> comments;
  final bool isPrivate;
  final int stickerIndex;
  final List<String> taggedFriends;

  TimelinePost({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.locationAddress,
    required this.visitorCount,
    required this.postTime,
    required this.description,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.categoryIcon,
    required this.comments,
    this.isPrivate = false,
    this.stickerIndex = -1,
    this.taggedFriends = const [],
  });

  TimelinePost copyWith({
    String? id,
    String? title,
    String? categoryName,
    String? locationAddress,
    int? visitorCount,
    String? postTime,
    String? description,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isBookmarked,
    CategoryIconType? categoryIcon,
    List<TimelineComment>? comments,
    bool? isPrivate,
    int? stickerIndex,
    List<String>? taggedFriends,
  }) {
    return TimelinePost(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryName: categoryName ?? this.categoryName,
      locationAddress: locationAddress ?? this.locationAddress,
      visitorCount: visitorCount ?? this.visitorCount,
      postTime: postTime ?? this.postTime,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      comments: comments ?? this.comments,
      isPrivate: isPrivate ?? this.isPrivate,
      stickerIndex: stickerIndex ?? this.stickerIndex,
      taggedFriends: taggedFriends ?? this.taggedFriends,
    );
  }
}
