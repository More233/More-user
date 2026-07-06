class SuggestedUser {
  final String name;
  final String username;
  final String subtitle;
  final String? avatarUrl;
  final String? avatarAsset;
  final bool isOnMore;
  final bool hasMutualFriends;

  const SuggestedUser({
    required this.name,
    required this.username,
    required this.subtitle,
    this.avatarUrl,
    this.avatarAsset,
    this.isOnMore = false,
    this.hasMutualFriends = false,
  });
}
