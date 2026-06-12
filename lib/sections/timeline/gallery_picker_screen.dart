import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crop_preview_screen.dart';

class GalleryPickerScreen extends StatefulWidget {
  final List<String> previouslySelected;

  const GalleryPickerScreen({super.key, this.previouslySelected = const []});

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  // Mock list of local images available in gallery
  final List<String> _galleryImages = [
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-1.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-2.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-3.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-4.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-5.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-6.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-7.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-8.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-9.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-10.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-11.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-12.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-13.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle-14.png',
    'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/image/Rectangle0.png',
  ];

  late List<String> _currentGridPhotos;
  final List<String> _selectedImages = [];
  bool _isMultiSelect = false;
  late String _activePreviewImage;
  bool _isDropdownOpen = false;
  String _selectedCategory = "Recents";

  @override
  void initState() {
    super.initState();
    _currentGridPhotos = List.from(_galleryImages);
    _selectedImages.addAll(widget.previouslySelected);
    _activePreviewImage = _selectedImages.isNotEmpty ? _selectedImages.first : _galleryImages.first;
    if (_selectedImages.isNotEmpty) {
      _isMultiSelect = true;
    }
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelect = !_isMultiSelect;
      if (!_isMultiSelect) {
        _selectedImages.clear();
      } else {
        // If entering multi-select and we have an active preview, select it
        if (!_selectedImages.contains(_activePreviewImage)) {
          _selectedImages.add(_activePreviewImage);
        }
      }
    });
  }

  void _onPhotoTapped(String path) {
    setState(() {
      if (_isMultiSelect) {
        if (_selectedImages.contains(path)) {
          _selectedImages.remove(path);
          if (_activePreviewImage == path && _selectedImages.isNotEmpty) {
            _activePreviewImage = _selectedImages.last;
          }
        } else {
          _selectedImages.add(path);
          _activePreviewImage = path;
        }
      } else {
        _activePreviewImage = path;
      }
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _isDropdownOpen = false;
      if (category == 'Recents') {
        _currentGridPhotos = List.from(_galleryImages);
      } else if (category == 'Photos') {
        _currentGridPhotos = _galleryImages.take(8).toList();
      } else if (category == 'Google Photos') {
        _currentGridPhotos = _galleryImages.skip(4).take(8).toList();
      }
      
      // Update active preview
      if (_currentGridPhotos.isNotEmpty) {
        _activePreviewImage = _currentGridPhotos.first;
      }
    });
  }

  void _onAlbumSelected(String albumName) {
    setState(() {
      _selectedCategory = albumName;
      _isDropdownOpen = false;
      // Shuffle list to simulate album contents
      _currentGridPhotos = List.from(_galleryImages)..shuffle();
      if (_currentGridPhotos.isNotEmpty) {
        _activePreviewImage = _currentGridPhotos.first;
      }
    });
  }

  void _openAlbumsBottomSheet() {
    setState(() {
      _isDropdownOpen = false;
    });

    final albums = [
      {'name': 'Facebook', 'count': 785, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 19487548413.png'},
      {'name': 'Instagram', 'count': 1000, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 1948754843.png'},
      {'name': 'Sport', 'count': 247, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 19487548d43.png'},
      {'name': 'Outside', 'count': 511, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 19487548s43.png'},
      {'name': 'Mine', 'count': 403, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 194875d4843.png'},
      {'name': 'Tourism', 'count': 24985, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 1948d754843.png'},
      {'name': 'Snapchat', 'count': 612, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 1948s754843.png'},
      {'name': 'WhatsApp', 'count': 942, 'cover': 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Select Album Bottom Sheet/image/Frame 1s948754843.png'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Bottom sheet handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Select albums',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balancing spacing
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Albums Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return GestureDetector(
                      onTap: () {
                        _onAlbumSelected(album['name'] as String);
                        Navigator.pop(context);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                album['cover'] as String,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            album['name'] as String,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${album['count']}',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCropPreview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropPreviewScreen(selectedImages: _selectedImages),
      ),
    );

    if (result != null) {
      if (result == 'ADD_MORE') {
        // Just remain here in multi-select state
        return;
      }
      if (result is List<String>) {
        if (!mounted) return;
        Navigator.pop(context, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Top Custom Header
                Padding(
                  padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                          'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/icon/cancel-01.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Add photos',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                
                // Active Preview Container
                Container(
                  width: double.infinity,
                  height: 266,
                  color: const Color(0xFFF9F9F9),
                  child: _activePreviewImage.isNotEmpty
                      ? (_activePreviewImage.startsWith('/') || _activePreviewImage.startsWith('file:')
                          ? Image.file(
                              File(_activePreviewImage),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              _activePreviewImage,
                              fit: BoxFit.cover,
                            ))
                      : Container(color: Colors.grey[300]),
                ),
                
                // Dropdown selector & Select / Cancel Button Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Dropdown Selector Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDropdownOpen = !_isDropdownOpen;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCategory,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/icon/arrow-down-01.svg',
                              width: 20,
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      
                      // Select / Cancel Action Chip
                      GestureDetector(
                        onTap: _toggleMultiSelect,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                _isMultiSelect
                                    ? 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/icon/cancel-01.svg'
                                    : 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/icon/Frame 1948754838.svg',
                                width: 16,
                                height: 16,
                                colorFilter: const ColorFilter.mode(Color(0xFF333333), BlendMode.srcIn),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isMultiSelect ? 'Cancel' : 'Select',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Photo Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: _currentGridPhotos.length + 1, // Photos + 1 camera card
                    itemBuilder: (context, index) {
                      if (index == 3) {
                        // Camera card (4th item)
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Gallery Picker/icon/camera-01.svg',
                              width: 32,
                              height: 32,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        );
                      }

                      // Adjust list pointer for index 3 injection
                      final photoIndex = index < 3 ? index : index - 1;
                      if (photoIndex >= _currentGridPhotos.length) {
                        return const SizedBox.shrink();
                      }
                      
                      final photoPath = _currentGridPhotos[photoIndex];
                      final isPhotoAsset = !photoPath.startsWith('/') && !photoPath.startsWith('file:');
                      final selectedIndex = _selectedImages.indexOf(photoPath);
                      final isSelected = selectedIndex != -1;

                      return GestureDetector(
                        onTap: () => _onPhotoTapped(photoPath),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            isPhotoAsset
                                ? Image.asset(
                                    photoPath,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(photoPath),
                                    fit: BoxFit.cover,
                                  ),
                            
                            // Dim overlay when selected
                            if (isSelected)
                              Container(
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                            
                            // Selection checkboxes (only in multi-select mode)
                            if (_isMultiSelect)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: isSelected
                                    ? Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF7C57FC),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${selectedIndex + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          color: Colors.black.withValues(alpha: 0.2),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Selected Bottom Tray (Visible when selection not empty)
                if (_isMultiSelect && _selectedImages.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding > 0 ? bottomPadding + 8 : 16),
                    child: Row(
                      children: [
                        // Selected thumbnails list
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                final path = _selectedImages[index];
                                final isThumbAsset = !path.startsWith('/') && !path.startsWith('file:');
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: isThumbAsset
                                              ? Image.asset(path, fit: BoxFit.cover)
                                              : Image.file(File(path), fit: BoxFit.cover),
                                        ),
                                      ),
                                      // Small delete/deselect tag
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black87,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: const Icon(
                                              Icons.close,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Next button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2EEFC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: _navigateToCropPreview,
                          child: Row(
                            children: [
                              Text(
                                'Next',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7C57FC),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF7C57FC),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            // Custom Dropdown Menu Overlay
            if (_isDropdownOpen)
              Positioned.fill(
                child: Stack(
                  children: [
                    // Click outside backdrop to close
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDropdownOpen = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    // Dropdown menu Card
                    Positioned(
                      top: topPadding + 44 + 266 + 12 + 24, // aligned below 'Recents v' selector
                      left: 16,
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E2E), // Slick dark background matching Figma
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDropdownItem(
                              iconPath: 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Selected Photos Bottom Tray/icon/image-02.svg',
                              title: 'Recents',
                              onTap: () => _onCategorySelected('Recents'),
                            ),
                            _buildDropdownItem(
                              iconPath: 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Selected Photos Bottom Tray/icon/image-01.svg',
                              title: 'Photos',
                              onTap: () => _onCategorySelected('Photos'),
                            ),
                            _buildDropdownItem(
                              iconPath: 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Selected Photos Bottom Tray/icon/google-photos.svg',
                              title: 'Google Photos',
                              onTap: () => _onCategorySelected('Google Photos'),
                            ),
                            _buildDropdownItem(
                              iconPath: 'assets/Timeline Phase need to rename/Timeline Section  Add Photos  Selected Photos Bottom Tray/icon/album-02.svg',
                              title: 'All albums',
                              onTap: _openAlbumsBottomSheet,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
