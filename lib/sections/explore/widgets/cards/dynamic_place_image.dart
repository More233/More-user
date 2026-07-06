import 'package:flutter/material.dart';

class DynamicPlaceImage extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String? iconUrl;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const DynamicPlaceImage({
    super.key,
    required this.placeId,
    required this.placeName,
    this.iconUrl,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the imageUrl is a valid real photo (not null, not empty, and not an Unsplash placeholder)
    final bool hasRealImage = imageUrl != null &&
                              imageUrl!.isNotEmpty &&
                              !imageUrl!.contains('unsplash.com/photo-');

    Widget displayWidget;

    if (hasRealImage) {
      displayWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF5F5F7),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C57FC)),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
      );
    } else {
      displayWidget = _buildFallbackIcon();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: displayWidget,
      );
    }
    return displayWidget;
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF5F5F7),
      alignment: Alignment.center,
      child: iconUrl != null && iconUrl!.isNotEmpty
          ? Image.network(
              iconUrl!,
              width: 32,
              height: 32,
              color: const Color(0xFF7C57FC),
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.location_on,
                  color: Color(0xFF7C57FC),
                  size: 28,
                );
              },
            )
          : const Icon(
              Icons.location_on,
              color: Color(0xFF7C57FC),
              size: 28,
            ),
    );
  }
}
