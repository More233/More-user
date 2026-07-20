import 'package:flutter/cupertino.dart';
import 'package:moor/sections/explore/helpers/marker_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../home/widgets/common/cached_image.dart';

class DynamicPlaceImage extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String? iconUrl;
  final String? imageUrl;
  final String? placeType;
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
    this.placeType,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRealImage = imageUrl != null &&
                              imageUrl!.isNotEmpty &&
                              !imageUrl!.contains('unsplash.com/photo-') &&
                              !imageUrl!.contains('placeholder_for_');

    Widget displayWidget;

    if (hasRealImage) {
      displayWidget = CustomCachedImage(
        url: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: Container(
          width: width,
          height: height,
          color: const Color(0xFFF5F5F7),
          child: const Center(
            child: CupertinoActivityIndicator(
              color: Color(0xFF7C57FC),
              radius: 8,
            ),
          ),
        ),
        errorWidget: _buildFallbackIcon(),
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
    final String type = MarkerGenerator.resolveType(placeType ?? '', placeName);
    final IconData iconData = MarkerGenerator.getIconDataForType(type);
    final Color color = MarkerGenerator.getMarkerColor(type);

    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF5F5F7),
      alignment: Alignment.center,
      child: iconUrl != null && iconUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: iconUrl!,
              width: 32,
              height: 32,
              color: color,
              errorWidget: (context, url, error) {
                return Icon(
                  iconData,
                  color: color,
                  size: 28,
                );
              },
            )
          : Icon(
              iconData,
              color: color,
              size: 28,
            ),
    );
  }
}
