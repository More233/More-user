import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CropPreviewScreen extends StatefulWidget {
  final List<String> selectedImages;

  const CropPreviewScreen({
    super.key,
    required this.selectedImages,
  });

  @override
  State<CropPreviewScreen> createState() => _CropPreviewScreenState();
}

class _CropPreviewScreenState extends State<CropPreviewScreen> {
  late List<String> _images;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.selectedImages);
    if (_images.isEmpty) {
      // Fallback
      _images.add('assets/Timeline/images/picker_rectangle.png');
    }
  }

  void _deleteActivePhoto() {
    setState(() {
      final removedIndex = _activeIndex;
      _images.removeAt(_activeIndex);
      
      // If we cleared all images, pop back to gallery
      if (_images.isEmpty) {
        Navigator.pop(context, <String>[]);
        return;
      }

      // Adjust active index
      if (removedIndex >= _images.length) {
        _activeIndex = _images.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeImage = _images[_activeIndex];
    final isAsset = !activeImage.startsWith('/') && !activeImage.startsWith('file:');
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: EdgeInsets.only(top: topPadding + 12, left: 8, right: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/Timeline/icons/arrow_left_01.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            
            // Large Crop Preview Container with 3x3 Grid Overlay
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AspectRatio(
                    aspectRatio: 1, // Square preview
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFF3F4F6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Active Image
                          isAsset
                              ? Image.asset(
                                  activeImage,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(activeImage),
                                  fit: BoxFit.cover,
                                ),
                          
                          // Grid Overlay (2 horizontal lines, 2 vertical lines)
                          CustomPaint(
                            painter: CropGridPainter(),
                          ),
                          
                          // Circular Delete Button (top-right)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _deleteActivePhoto,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/Timeline/icons/cancel_01_1.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bottom Horizontal Selected Thumbnails Tray
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1, // Images + Add Button
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      // Light purple Add More button at the end
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: () {
                            // Signal back to gallery picker to add more
                            Navigator.pop(context, 'ADD_MORE');
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EEFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/Timeline/icons/plus_sign_2.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF7C57FC),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final imgPath = _images[index];
                    final isImgAsset = !imgPath.startsWith('/') && !imgPath.startsWith('file:');
                    final isActive = index == _activeIndex;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeIndex = index;
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? const Color(0xFF7C57FC) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: isImgAsset
                                ? Image.asset(
                                    imgPath,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(imgPath),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Primary Add Action Button at Bottom
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding + 8 : 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context, _images);
                  },
                  child: Text(
                    'Add',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    final firstThirdWidth = size.width / 3.0;
    canvas.drawLine(Offset(firstThirdWidth, 0), Offset(firstThirdWidth, size.height), paint);
    canvas.drawLine(Offset(firstThirdWidth * 2, 0), Offset(firstThirdWidth * 2, size.height), paint);

    // Draw horizontal lines
    final firstThirdHeight = size.height / 3.0;
    canvas.drawLine(Offset(0, firstThirdHeight), Offset(size.width, firstThirdHeight), paint);
    canvas.drawLine(Offset(0, firstThirdHeight * 2), Offset(size.width, firstThirdHeight * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CropGridPainter oldDelegate) => false;
}
