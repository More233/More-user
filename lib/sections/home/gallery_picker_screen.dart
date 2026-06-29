import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'crop_preview_screen.dart';

class GalleryPickerScreen extends StatefulWidget {
  final List<String> previouslySelected;

  const GalleryPickerScreen({super.key, this.previouslySelected = const []});

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  final List<GalleryImage> _galleryImages = [];
  List<GalleryImage> _currentGridPhotos = [];
  final List<GalleryImage> _selectedImages = [];
  bool _isMultiSelect = false;
  GalleryImage? _activePreviewImage;
  bool _isDropdownOpen = false;
  String _selectedCategory = "Recents";
  List<AssetPathEntity> _deviceAlbums = [];

  final ScrollController _scrollController = ScrollController();
  AssetPathEntity? _currentAlbum;
  int _currentPage = 0;
  final int _pageSize = 80;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Wrap any previously selected files
    for (var path in widget.previouslySelected) {
      _selectedImages.add(GalleryImage(filePath: path));
    }
    if (_selectedImages.isNotEmpty) {
      _isMultiSelect = true;
      _activePreviewImage = _selectedImages.first;
    }
    _loadGalleryImages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final threshold = _scrollController.position.maxScrollExtent - 200;
      if (_scrollController.position.pixels >= threshold) {
        if (_currentAlbum != null && _hasMore && !_isLoadingMore) {
          _loadAssetsFromAlbum(_currentAlbum!, isLoadMore: true);
        }
      }
    }
  }

  Future<void> _loadGalleryImages() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
        );
        
        final List<AssetPathEntity> validAlbums = [];
        final List<Future<int>> countsFutures = albums.map((a) => a.assetCountAsync).toList();
        final List<int> counts = await Future.wait(countsFutures);
        for (int i = 0; i < albums.length; i++) {
          if (counts[i] > 0) {
            validAlbums.add(albums[i]);
          }
        }

        if (mounted) {
          setState(() {
            _deviceAlbums = validAlbums;
          });
        }
        if (validAlbums.isNotEmpty) {
          await _loadAssetsFromAlbum(validAlbums[0]);
        }
      } else {
        debugPrint("Permission denied to access photo library");
      }
    } catch (e) {
      debugPrint("Error loading gallery images: $e");
    }
  }

  Future<void> _loadAssetsFromAlbum(AssetPathEntity album, {bool isLoadMore = false}) async {
    try {
      if (!isLoadMore) {
        _currentAlbum = album;
        _currentPage = 0;
        _hasMore = true;
        _isLoadingMore = false;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      } else {
        if (!_hasMore || _isLoadingMore) return;
        setState(() {
          _isLoadingMore = true;
        });
      }

      final int start = _currentPage * _pageSize;
      final int end = start + _pageSize;
      final int totalCount = await album.assetCountAsync;

      if (start >= totalCount) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _isLoadingMore = false;
          });
        }
        return;
      }

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: start,
        end: end > totalCount ? totalCount : end,
      );
      
      final List<GalleryImage> images = assets.map((entity) => GalleryImage(entity: entity)).toList();
      
      if (mounted) {
        setState(() {
          if (!isLoadMore) {
            _galleryImages.clear();
          }
          _galleryImages.addAll(images);
          _currentGridPhotos = List.from(_galleryImages);
          _selectedCategory = album.name;
          
          if (!isLoadMore && _selectedImages.isEmpty && _currentGridPhotos.isNotEmpty) {
            _activePreviewImage = _currentGridPhotos.first;
          }
          
          _currentPage++;
          _hasMore = _galleryImages.length < totalCount;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading assets from album: $e");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final galleryImg = GalleryImage(filePath: photo.path);
        setState(() {
          _galleryImages.insert(0, galleryImg);
          _currentGridPhotos = List.from(_galleryImages);
          _activePreviewImage = galleryImg;
          if (_isMultiSelect) {
            if (!_isSelected(galleryImg)) {
              _selectedImages.add(galleryImg);
            }
          } else {
            _selectedImages.clear();
            _selectedImages.add(galleryImg);
          }
        });
        if (!_isMultiSelect) {
          _navigateToCropPreview();
        }
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
    }
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelect = !_isMultiSelect;
      if (!_isMultiSelect) {
        _selectedImages.clear();
      } else {
        if (_activePreviewImage != null && !_isSelected(_activePreviewImage!)) {
          _selectedImages.add(_activePreviewImage!);
        }
      }
    });
  }

  void _onPhotoTapped(GalleryImage img) {
    setState(() {
      if (_isMultiSelect) {
        if (_isSelected(img)) {
          _removeSelected(img);
          if (_activePreviewImage == img && _selectedImages.isNotEmpty) {
            _activePreviewImage = _selectedImages.last;
          }
        } else {
          _selectedImages.add(img);
          _activePreviewImage = img;
        }
      } else {
        _selectedImages.clear();
        _selectedImages.add(img);
        _activePreviewImage = img;
      }
    });
  }

  void _onCategorySelected(int index) async {
    if (index >= 0 && index < _deviceAlbums.length) {
      setState(() {
        _isDropdownOpen = false;
      });
      await _loadAssetsFromAlbum(_deviceAlbums[index]);
    }
  }

  void _onAlbumSelected(AssetPathEntity album) async {
    setState(() {
      _isDropdownOpen = false;
    });
    await _loadAssetsFromAlbum(album);
  }

  bool _isSelected(GalleryImage img) {
    return _selectedImages.any((selected) {
      if (img.isEntity && selected.isEntity) {
        return img.entity!.id == selected.entity!.id;
      }
      if (img.isFile && selected.isFile) {
        return img.filePath == selected.filePath;
      }
      if (img.isAsset && selected.isAsset) {
        return img.assetPath == selected.assetPath;
      }
      return false;
    });
  }

  void _removeSelected(GalleryImage img) {
    _selectedImages.removeWhere((selected) {
      if (img.isEntity && selected.isEntity) {
        return img.entity!.id == selected.entity!.id;
      }
      if (img.isFile && selected.isFile) {
        return img.filePath == selected.filePath;
      }
      if (img.isAsset && selected.isAsset) {
        return img.assetPath == selected.assetPath;
      }
      return false;
    });
  }

  Future<String?> _resolveImagePath(GalleryImage img) async {
    if (img.isFile) return img.filePath;
    if (img.isAsset) return img.assetPath;
    if (img.isEntity) {
      final file = await img.entity!.file;
      return file?.path;
    }
    return null;
  }

  void _navigateToCropPreview() async {
    if (_selectedImages.isEmpty && _activePreviewImage != null) {
      _selectedImages.add(_activePreviewImage!);
    }
    if (_selectedImages.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7C57FC),
        ),
      ),
    );

    List<String> resolvedPaths = [];
    try {
      for (var img in _selectedImages) {
        final path = await _resolveImagePath(img);
        if (path != null) {
          resolvedPaths.add(path);
        }
      }
    } catch (e) {
      debugPrint("Error resolving paths: $e");
    }

    if (mounted) {
      Navigator.pop(context);
    }

    if (resolvedPaths.isEmpty) return;

    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropPreviewScreen(selectedImages: resolvedPaths),
      ),
    );

    if (result != null) {
      if (result == 'ADD_MORE') {
        return;
      }
      if (result is List<String>) {
        if (!mounted) return;
        Navigator.pop(context, result);
      }
    }
  }

  void _openAlbumsBottomSheet() {
    setState(() {
      _isDropdownOpen = false;
    });

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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _deviceAlbums.isEmpty
                    ? Center(
                        child: Text(
                          'No albums found',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _deviceAlbums.length,
                        itemBuilder: (context, index) {
                          final album = _deviceAlbums[index];
                          return AlbumGridItem(
                            album: album,
                            onTap: () {
                              _onAlbumSelected(album);
                              Navigator.pop(context);
                            },
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

  Widget _buildActivePreviewWidget(GalleryImage img) {
    if (img.isAsset) {
      return Image.asset(img.assetPath!, fit: BoxFit.cover);
    } else if (img.isFile) {
      return Image.file(File(img.filePath!), fit: BoxFit.cover);
    } else {
      return AssetEntityImage(
        img.entity!,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize(800, 800),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildGridImageWidget(GalleryImage img) {
    if (img.isAsset) {
      return Image.asset(img.assetPath!, fit: BoxFit.cover);
    } else if (img.isFile) {
      return Image.file(File(img.filePath!), fit: BoxFit.cover);
    } else {
      return AssetEntityImage(
        img.entity!,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize(200, 200),
        fit: BoxFit.cover,
      );
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
                          'assets/home/icons/cancel_01.svg',
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
                  child: _activePreviewImage != null
                      ? _buildActivePreviewWidget(_activePreviewImage!)
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
                              'assets/home/icons/arrow_down_01.svg',
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
                                    ? 'assets/home/icons/cancel_01.svg'
                                    : 'assets/home/icons/select_multiple.svg',
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
                    controller: _scrollController,
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
                        return GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            color: Colors.black,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/home/icons/camera_01.svg',
                                width: 32,
                                height: 32,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        );
                      }

                      // Adjust list pointer for index 3 injection
                      final photoIndex = index < 3 ? index : index - 1;
                      if (photoIndex >= _currentGridPhotos.length) {
                        return const SizedBox.shrink();
                      }
                      
                      final img = _currentGridPhotos[photoIndex];
                      final isSelected = _isSelected(img);
                      final selectedIndex = _selectedImages.indexWhere((selected) {
                        if (img.isEntity && selected.isEntity) {
                          return img.entity!.id == selected.entity!.id;
                        }
                        if (img.isFile && selected.isFile) {
                          return img.filePath == selected.filePath;
                        }
                        if (img.isAsset && selected.isAsset) {
                          return img.assetPath == selected.assetPath;
                        }
                        return false;
                      });

                      return GestureDetector(
                        onTap: () => _onPhotoTapped(img),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildGridImageWidget(img),
                            
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
                    padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding > 0 ? bottomPadding + 8 : 16),
                    child: Row(
                      children: [
                        // Selected thumbnails list
                        Expanded(
                          child: SizedBox(
                            height: 66,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                final img = _selectedImages[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: _buildGridImageWidget(img),
                                        ),
                                      ),
                                      // Small delete/deselect tag
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              _removeSelected(img);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(5),
                                            child: const Icon(
                                              Icons.close,
                                              size: 13,
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
                            if (_deviceAlbums.isEmpty) ...[
                              _buildDropdownItem(
                                iconPath: 'assets/home/icons/image_02.svg',
                                title: 'Recents',
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = 'Recents';
                                    _isDropdownOpen = false;
                                  });
                                },
                              ),
                            ] else ...[
                              ..._deviceAlbums.take(3).map((album) {
                                final int index = _deviceAlbums.indexOf(album);
                                return _buildDropdownItem(
                                  iconPath: 'assets/home/icons/image_01.svg',
                                  title: album.name,
                                  onTap: () => _onCategorySelected(index),
                                );
                              }),
                            ],
                            _buildDropdownItem(
                              iconPath: 'assets/home/icons/album_02.svg',
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

class GalleryImage {
  final String? assetPath;
  final String? filePath;
  final AssetEntity? entity;

  GalleryImage({this.assetPath, this.filePath, this.entity});

  bool get isAsset => entity == null && filePath == null;
  bool get isFile => filePath != null;
  bool get isEntity => entity != null;
}

class AlbumGridItem extends StatelessWidget {
  final AssetPathEntity album;
  final VoidCallback onTap;

  const AlbumGridItem({super.key, required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: album.assetCountAsync,
      builder: (context, countSnapshot) {
        final count = countSnapshot.data ?? 0;
        return FutureBuilder<List<AssetEntity>>(
          future: album.getAssetListRange(start: 0, end: 1),
          builder: (context, assetsSnapshot) {
            final assets = assetsSnapshot.data;
            final hasCover = assets != null && assets.isNotEmpty;

            return GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: hasCover
                          ? AssetEntityImage(
                              assets[0],
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize(200, 200),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
