import 'package:flutter/material.dart';

class StoryOverlayItem {
  final String id;
  final String type; // 'music', 'mention', 'sticker', 'text'
  final dynamic data;
  final Offset position;
  final double scale;
  final double rotation;
  final Size size;

  StoryOverlayItem({
    required this.id,
    required this.type,
    required this.data,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.size = const Size(100, 100),
  });

  StoryOverlayItem copyWith({
    String? id,
    String? type,
    dynamic data,
    Offset? position,
    double? scale,
    double? rotation,
    Size? size,
  }) {
    return StoryOverlayItem(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      size: size ?? this.size,
    );
  }
}
