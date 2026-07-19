import 'package:flutter/material.dart';
import 'full_screen_image_viewer.dart';
import '../common/cached_image.dart';

class PostImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final double width;

  const PostImageSlider({
    super.key,
    required this.imageUrls,
    required this.height,
    required this.width,
  });

  @override
  State<PostImageSlider> createState() => _PostImageSliderState();
}

class _PostImageSliderState extends State<PostImageSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    if (widget.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImageViewer(
                imageUrls: widget.imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: _buildSingleImage(widget.imageUrls.first),
      );
    }

    return Stack(
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imageUrls: widget.imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: _buildSingleImage(widget.imageUrls[index], applyBorderRadius: false),
                );
              },
            ),
          ),
        ),
        // Indicator
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImage(String path, {bool applyBorderRadius = true}) {
    final Widget image = CustomCachedImage(
      url: path,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      errorWidget: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );

    if (applyBorderRadius) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: image,
      );
    }
    return image;
  }
}
