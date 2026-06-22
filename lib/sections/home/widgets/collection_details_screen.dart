import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timeline_post.dart';
import '../models/collection_model.dart';
import '../view_models/collections_view_model.dart';

class CollectionDetailsScreen extends ConsumerStatefulWidget {
  final String collectionId;
  final String collectionName;
  final VoidCallback? onRefresh;

  const CollectionDetailsScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
    this.onRefresh,
  });

  @override
  ConsumerState<CollectionDetailsScreen> createState() => _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends ConsumerState<CollectionDetailsScreen> {
  bool _isLoading = true;
  List<TimelinePost> _collectionPosts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final collectionsState = ref.read(collectionsViewModelProvider);
      if (collectionsState.collections.isEmpty && !collectionsState.isLoading) {
        await ref.read(collectionsViewModelProvider.notifier).loadCollections();
      }

      final client = Supabase.instance.client;
      final response = await client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final allPosts = response.map((data) => TimelinePost.fromMap(data)).toList();

      final updatedColState = ref.read(collectionsViewModelProvider);
      final col = updatedColState.collections.firstWhere(
        (c) => c.id == widget.collectionId,
        orElse: () => CollectionModel(id: '', name: '', postIds: []),
      );
      _collectionPosts = allPosts.where((p) => col.postIds.contains(p.id)).toList();
    } catch (e) {
      debugPrint("Error loading collection posts: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDeleteCollection() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Delete this collection? This action cannot be undone.',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
              InkWell(
                onTap: () async {
                  Navigator.pop(dialogCtx); // Close Dialog
                  await ref.read(collectionsViewModelProvider.notifier).removeCollection(widget.collectionId);
                  if (mounted) {
                    Navigator.pop(context); // Close Collection Details Screen
                  }
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
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
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
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
                      color: const Color(0xFF6D6D6D),
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

  Widget _buildGridImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    final isAsset = !path.startsWith('/') && !path.startsWith('file:');
    if (isAsset) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildTextGridPlaceholder(TimelinePost post) {
    Color bgColor;
    Color iconColor;
    String iconSvg;

    switch (post.categoryIcon) {
      case CategoryIconType.coffee:
        bgColor = const Color(0xFFFDF6EC);
        iconColor = const Color(0xFFE6A23C);
        iconSvg = 'assets/home/icons/coffee_02.svg';
        break;
      case CategoryIconType.camera:
        bgColor = const Color(0xFFFFF0F5);
        iconColor = const Color(0xFFFF5B9D);
        iconSvg = 'assets/home/icons/camera_01_1.svg';
        break;
      case CategoryIconType.building:
        bgColor = const Color(0xFFF2EEFC);
        iconColor = const Color(0xFF7C57FC);
        iconSvg = 'assets/home/icons/building_05.svg';
        break;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            iconSvg,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsState = ref.watch(collectionsViewModelProvider);
    final col = collectionsState.collections.firstWhere(
      (c) => c.id == widget.collectionId,
      orElse: () => CollectionModel(id: '', name: '', postIds: []),
    );
    final isCustomCollection = col.name.toLowerCase() != 'saved';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
            if (widget.onRefresh != null) {
              widget.onRefresh!();
            }
          },
        ),
        title: Text(
          widget.collectionName,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isCustomCollection)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF82858C)),
              onPressed: _confirmDeleteCollection,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collectionPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No saved check-in photos yet.',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          color: const Color(0xFF82858C),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _collectionPosts.length,
                  itemBuilder: (context, index) {
                    final post = _collectionPosts[index];
                    return GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoViewerScreen(
                              posts: _collectionPosts,
                              initialIndex: index,
                              collectionId: widget.collectionId,
                            ),
                          ),
                        );
                        if (updated == true) {
                          _loadPosts();
                          if (widget.onRefresh != null) {
                            widget.onRefresh!();
                          }
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: post.imageUrl != null
                            ? _buildGridImage(post.imageUrl!)
                            : _buildTextGridPlaceholder(post),
                      ),
                    );
                  },
                ),
    );
  }
}

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
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
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
                    color: Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
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
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
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
                      color: const Color(0xFF6D6D6D),
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
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
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
                child: post.imageUrl != null
                    ? _buildViewerImage(post.imageUrl!)
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
                              // Share mock
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
