import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/timeline_post.dart';
import '../../widgets/bottom_sheets/share_bottom_sheet.dart';
import '../../view_models/collections_view_model.dart';
import '../../models/collection_model.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  final List<TimelinePost> posts;
  final int initialIndex;
  final String collectionId;

  const PhotoViewerScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    required this.collectionId,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmDeletePhoto(BuildContext context, TimelinePost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? const Color(0xFF1E2433) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Are you sure you want to delete this photo? This action cannot be undone.',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8)),
              InkWell(
                onTap: () async {
                  Navigator.pop(dialogCtx); // Close Dialog
                  
                  final navigator = Navigator.of(context);
                  
                  final collectionsState = ref.read(collectionsViewModelProvider);
                  final col = collectionsState.collections.firstWhere(
                    (c) => c.id == widget.collectionId,
                    orElse: () => CollectionModel(id: '', name: '', postIds: []),
                  );
                  final isSavedCollection = col.name.toLowerCase() == 'saved';

                  if (isSavedCollection) {
                    await Supabase.instance.client
                        .from('posts')
                        .update({'is_bookmarked': false})
                        .eq('id', post.id);
                    post.isBookmarked = false;
                    await ref.read(collectionsViewModelProvider.notifier).removePostFromCollection(col.id, post.id);
                    await ref.read(collectionsViewModelProvider.notifier).removePostFromAllCollections(post.id);
                  } else {
                    await ref.read(collectionsViewModelProvider.notifier).removePostFromCollection(widget.collectionId, post.id);
                    bool inOther = false;
                    for (final c in collectionsState.collections) {
                      if (c.postIds.contains(post.id)) {
                        inOther = true;
                        break;
                      }
                    }
                    if (!inOther) {
                      await Supabase.instance.client
                          .from('posts')
                          .update({'is_bookmarked': false})
                          .eq('id', post.id);
                      post.isBookmarked = false;
                    }
                  }
                  
                  // Return true to show it was updated
                  navigator.pop(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text(
                    'Delete',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD80000),
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? const Color(0xFF2C354A) : const Color(0xFFE8E8E8)),
              InkWell(
                onTap: () => Navigator.pop(dialogCtx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF6D6D6D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewerImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CupertinoActivityIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 64),
        ),
      );
    }
    final isAsset = !path.startsWith('/') && !path.startsWith('file:');
    if (isAsset) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildTextPostCardViewer(TimelinePost post) {
    Color iconColor;
    String iconSvg;

    switch (post.categoryIcon) {
      case CategoryIconType.coffee:
        iconColor = const Color(0xFFE6A23C);
        iconSvg = 'assets/home/icons/coffee_02.svg';
        break;
      case CategoryIconType.camera:
        iconColor = const Color(0xFFFF5B9D);
        iconSvg = 'assets/home/icons/camera_01_1.svg';
        break;
      case CategoryIconType.building:
        iconColor = const Color(0xFF7C57FC);
        iconSvg = 'assets/home/icons/building_05.svg';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF221F26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconSvg,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            post.title,
            style: GoogleFonts.ibmPlexSansArabic(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (post.locationAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.locationAddress,
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              post.description,
              style: GoogleFonts.ibmPlexSansArabic(
                color: const Color(0xFFEFEFEF),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131116),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              return Center(
                child: post.imageUrls.isNotEmpty
                    ? _buildViewerImage(post.imageUrls.first)
                    : _buildTextPostCardViewer(post),
              );
            },
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} of ${widget.posts.length}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5B9D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Icon(Icons.public, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.posts[_currentIndex].description.isNotEmpty
                            ? widget.posts[_currentIndex].description
                            : widget.posts[_currentIndex].title,
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage(
                              'assets/home/images/element.png',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    widget.posts[_currentIndex].title,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.posts[_currentIndex].postTime,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: SvgPicture.asset(
                                'assets/home/icons/delete_03_1.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFD80000),
                                  BlendMode.srcIn,
                                ),
                              ),
                              onPressed: () => _confirmDeletePhoto(context, widget.posts[_currentIndex]),
                            ),
                            IconButton(
                              icon: SvgPicture.asset(
                                'assets/home/icons/share_icon_1.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => ShareBottomSheet(
                                    post: widget.posts[_currentIndex],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
