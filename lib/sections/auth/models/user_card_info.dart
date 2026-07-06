import 'package:flutter/material.dart';

class UserCardInfo {
  final String name;
  final String username;
  final String avatarPath;
  final String detailText;
  final Widget? detailIcon;
  final bool isRegistered;
  bool isFollowing;
  bool isInvited;

  UserCardInfo({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.detailText,
    this.detailIcon,
    this.isRegistered = true,
    this.isFollowing = false,
    this.isInvited = false,
  });
}
