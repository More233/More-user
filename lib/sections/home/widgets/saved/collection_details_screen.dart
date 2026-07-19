import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/timeline_post.dart';
import '../../models/collection_model.dart';
import '../../view_models/collections_view_model.dart';
import 'photo_viewer_screen.dart';
import '../common/cached_image.dart';

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
    return CustomCachedImage(
      url: path,
      fit: BoxFit.cover,
      errorWidget: Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
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
              icon: SvgPicture.asset(
                'assets/home/icons/delete_03_1.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF82858C),
                  BlendMode.srcIn,
                ),
              ),
              onPressed: _confirmDeleteCollection,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
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
                        child: post.imageUrls.isNotEmpty
                            ? _buildGridImage(post.imageUrls.first)
                            : _buildTextGridPlaceholder(post),
                      ),
                    );
                  },
                ),
    );
  }
}


