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
  final DateTime? createdAt;
  final String? authorName;
  final String? authorAvatar;
  final String? authorId;
  final double? latitude;
  final double? longitude;
  final String? placeId;

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
    this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.authorId,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) return [];
    return imageUrl!.split(',');
  }

  String get shortLocationAddress {
    if (locationAddress.isEmpty) return '';
    
    // Split by comma (standard and Arabic)
    List<String> parts = locationAddress.split(RegExp(r'[,،]'));
    String primary = parts.first.trim();
    
    // If the primary part contains a dash "-", let's check if we should split by it
    if (primary.contains('-')) {
      final dashParts = primary.split('-');
      if (dashParts.first.trim().isNotEmpty) {
        primary = dashParts.first.trim();
      }
    }
    
    // If the resulting string is still extremely long, truncate it
    if (primary.length > 35) {
      return '${primary.substring(0, 32)}...';
    }
    
    return primary;
  }

  String get shortTitle {
    if (title.isEmpty) return '';
    
    // Split by comma (standard and Arabic)
    List<String> parts = title.split(RegExp(r'[,،]'));
    String primary = parts.first.trim();
    
    // If the primary part contains a dash "-", let's check if we should split by it
    if (primary.contains('-')) {
      final dashParts = primary.split('-');
      if (dashParts.first.trim().isNotEmpty) {
        primary = dashParts.first.trim();
      }
    }
    
    // If the resulting string is still extremely long, truncate it
    if (primary.length > 35) {
      return '${primary.substring(0, 32)}...';
    }
    
    return primary;
  }


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
    DateTime? createdAt,
    String? authorName,
    String? authorAvatar,
    String? authorId,
    double? latitude,
    double? longitude,
    String? placeId,
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
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorId: authorId ?? this.authorId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
    );
  }

  static TimelinePost fromMap(Map<String, dynamic> postData) {
    final categoryName = postData['category_name'] as String? ?? 'Hotel';
    CategoryIconType catIcon = CategoryIconType.building;
    if (categoryName.toLowerCase() == 'coffee' || categoryName.toLowerCase() == 'cafe') {
      catIcon = CategoryIconType.coffee;
    } else if (categoryName.toLowerCase() == 'attraction' || categoryName.toLowerCase() == 'camera') {
      catIcon = CategoryIconType.camera;
    }

    String postTimeStr = 'Just now';
    final createdAtStr = postData['created_at'] as String?;
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    if (createdAt != null) {
      final difference = DateTime.now().difference(createdAt.toLocal());
      if (difference.inMinutes < 1) {
        postTimeStr = 'Just now';
      } else if (difference.inMinutes < 60) {
        postTimeStr = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        postTimeStr = '${difference.inHours}h ago';
      } else {
        postTimeStr = '${difference.inDays}d ago';
      }
    }

    final taggedListRaw = postData['tagged_friends'];
    final List<String> tagged = [];
    if (taggedListRaw is List) {
      for (final t in taggedListRaw) {
        tagged.add(t.toString());
      }
    }

    final authorProfile = postData['author'];
    String? authorName;
    String? authorAvatar;
    String? authorId;
    if (authorProfile != null) {
      final firstName = authorProfile['first_name'] as String? ?? '';
      final lastName = authorProfile['last_name'] as String? ?? '';
      authorName = '$firstName $lastName'.trim();
      if (authorName.isEmpty) {
        authorName = authorProfile['username'] as String?;
      }
      authorAvatar = authorProfile['avatar_url'] as String?;
      authorId = authorProfile['id'] as String?;
    } else {
      authorId = postData['user_id'] as String?;
    }

    return TimelinePost(
      id: postData['id'] as String,
      title: postData['title'] as String? ?? '',
      categoryName: categoryName,
      locationAddress: postData['location_address'] as String? ?? '',
      visitorCount: postData['visitor_count'] as int? ?? 1,
      postTime: postTimeStr,
      description: postData['description'] as String? ?? '',
      imageUrl: postData['image_url'] as String?,
      likesCount: postData['likes_count'] as int? ?? 0,
      commentsCount: postData['comments_count'] as int? ?? 0,
      categoryIcon: catIcon,
      comments: [],
      isPrivate: postData['is_private'] as bool? ?? false,
      stickerIndex: postData['sticker_index'] as int? ?? -1,
      taggedFriends: tagged,
      createdAt: createdAt,
      isLiked: postData['is_liked'] as bool? ?? false,
      isBookmarked: postData['is_bookmarked'] as bool? ?? false,
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorId: authorId,
      latitude: (postData['latitude'] as num?)?.toDouble(),
      longitude: (postData['longitude'] as num?)?.toDouble(),
      placeId: postData['place_id'] as String?,
    );
  }
}
