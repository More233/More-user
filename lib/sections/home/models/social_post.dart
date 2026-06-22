class SocialPost {
  final String authorName;
  final String authorAvatar;
  final String timeText;
  final String description;
  final String location;
  final String imageUrl;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  bool isBookmarked;

  SocialPost({
    required this.authorName,
    required this.authorAvatar,
    required this.timeText,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}
