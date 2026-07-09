import 'package:flutter/material.dart';
import 'story_overlay_item.dart';

class StoryEditorState {
  final List<StoryOverlayItem> overlays;
  final bool isPublishing;
  final List<Map<String, dynamic>> followedUsers;
  final List<Map<String, dynamic>> mentionSuggestions;
  final bool isAudioMuted;
  final String? selectedOverlayId;
  final bool isEditingText;
  final bool isEditingMention;

  // Active text tool styling state
  final Color selectedTextColor;
  final Color? selectedBgColor;
  final String selectedFontFamily;
  final TextAlign selectedAlignment;
  final bool selectedIsBold;
  final String selectedBackgroundStyle;
  final String selectedEffect;

  // Dragging and guides
  final bool isDragging;
  final bool isNearTrash;
  final bool showVerticalCenterGuide;
  final bool showHorizontalCenterGuide;
  final bool showLeftGuide;
  final bool showRightGuide;
  final bool showTopGuide;
  final bool showBottomGuide;

  StoryEditorState({
    required this.overlays,
    required this.isPublishing,
    required this.followedUsers,
    required this.mentionSuggestions,
    required this.isAudioMuted,
    this.selectedOverlayId,
    required this.isEditingText,
    required this.isEditingMention,
    required this.selectedTextColor,
    this.selectedBgColor,
    required this.selectedFontFamily,
    required this.selectedAlignment,
    required this.selectedIsBold,
    required this.selectedBackgroundStyle,
    required this.selectedEffect,
    required this.isDragging,
    required this.isNearTrash,
    required this.showVerticalCenterGuide,
    required this.showHorizontalCenterGuide,
    required this.showLeftGuide,
    required this.showRightGuide,
    required this.showTopGuide,
    required this.showBottomGuide,
  });

  factory StoryEditorState.initial() {
    return StoryEditorState(
      overlays: [],
      isPublishing: false,
      followedUsers: [],
      mentionSuggestions: [],
      isAudioMuted: false,
      selectedOverlayId: null,
      isEditingText: false,
      isEditingMention: false,
      selectedTextColor: Colors.white,
      selectedBgColor: Colors.black87,
      selectedFontFamily: 'Default',
      selectedAlignment: TextAlign.center,
      selectedIsBold: false,
      selectedBackgroundStyle: 'normal',
      selectedEffect: 'none',
      isDragging: false,
      isNearTrash: false,
      showVerticalCenterGuide: false,
      showHorizontalCenterGuide: false,
      showLeftGuide: false,
      showRightGuide: false,
      showTopGuide: false,
      showBottomGuide: false,
    );
  }

  StoryEditorState copyWith({
    List<StoryOverlayItem>? overlays,
    bool? isPublishing,
    List<Map<String, dynamic>>? followedUsers,
    List<Map<String, dynamic>>? mentionSuggestions,
    bool? isAudioMuted,
    String? selectedOverlayId,
    bool clearSelectedOverlayId = false,
    bool? isEditingText,
    bool? isEditingMention,
    Color? selectedTextColor,
    Color? selectedBgColor,
    bool clearSelectedBgColor = false,
    String? selectedFontFamily,
    TextAlign? selectedAlignment,
    bool? selectedIsBold,
    String? selectedBackgroundStyle,
    String? selectedEffect,
    bool? isDragging,
    bool? isNearTrash,
    bool? showVerticalCenterGuide,
    bool? showHorizontalCenterGuide,
    bool? showLeftGuide,
    bool? showRightGuide,
    bool? showTopGuide,
    bool? showBottomGuide,
  }) {
    return StoryEditorState(
      overlays: overlays ?? this.overlays,
      isPublishing: isPublishing ?? this.isPublishing,
      followedUsers: followedUsers ?? this.followedUsers,
      mentionSuggestions: mentionSuggestions ?? this.mentionSuggestions,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      selectedOverlayId: clearSelectedOverlayId ? null : (selectedOverlayId ?? this.selectedOverlayId),
      isEditingText: isEditingText ?? this.isEditingText,
      isEditingMention: isEditingMention ?? this.isEditingMention,
      selectedTextColor: selectedTextColor ?? this.selectedTextColor,
      selectedBgColor: clearSelectedBgColor ? null : (selectedBgColor ?? this.selectedBgColor),
      selectedFontFamily: selectedFontFamily ?? this.selectedFontFamily,
      selectedAlignment: selectedAlignment ?? this.selectedAlignment,
      selectedIsBold: selectedIsBold ?? this.selectedIsBold,
      selectedBackgroundStyle: selectedBackgroundStyle ?? this.selectedBackgroundStyle,
      selectedEffect: selectedEffect ?? this.selectedEffect,
      isDragging: isDragging ?? this.isDragging,
      isNearTrash: isNearTrash ?? this.isNearTrash,
      showVerticalCenterGuide: showVerticalCenterGuide ?? this.showVerticalCenterGuide,
      showHorizontalCenterGuide: showHorizontalCenterGuide ?? this.showHorizontalCenterGuide,
      showLeftGuide: showLeftGuide ?? this.showLeftGuide,
      showRightGuide: showRightGuide ?? this.showRightGuide,
      showTopGuide: showTopGuide ?? this.showTopGuide,
      showBottomGuide: showBottomGuide ?? this.showBottomGuide,
    );
  }
}
