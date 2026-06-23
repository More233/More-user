import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timeline_post.dart';
import '../models/collection_model.dart';
import '../view_models/collections_view_model.dart';
import 'collection_details_screen.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String _activeTab = 'All'; // 'All', 'Collections', 'Posts'
  bool _isLoadingPosts = true;
  List<TimelinePost> _savedPosts = [];
  
  List<Map<String, dynamic>> _profilesList = [];
  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(collectionsViewModelProvider.notifier).init();
      _loadSavedPosts();
      _loadProfiles();
    });
  }

  Future<void> _loadSavedPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('posts')
          .select()
          .eq('is_bookmarked', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _savedPosts = (response as List).map((data) => TimelinePost.fromMap(data)).toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading saved posts: $e");
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final res = await Supabase.instance.client.from('profiles').select();
      if (mounted) {
        setState(() {
          _profilesList = List<Map<String, dynamic>>.from(res);
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profiles: $e");
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  Widget _buildFolderPlaceholder({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.folder_rounded,
          color: const Color(0xFF7C57FC),
          size: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildCollectionCover(CollectionModel col, {double size = 100}) {
    String? coverUrl = col.coverImageUrl;
    
    // Fallback to first post's image if coverUrl is null
    if ((coverUrl == null || coverUrl.isEmpty) && col.postIds.isNotEmpty) {
      try {
        final match = _savedPosts.firstWhere(
          (p) => col.postIds.contains(p.id) && p.imageUrl != null,
        );
        coverUrl = match.imageUrl;
      } catch (_) {
        // No post with image found
      }
    }
    
    if (coverUrl != null && coverUrl.isNotEmpty) {
      if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
        return Image.network(
          coverUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFolderPlaceholder(size: size),
        );
      }
      final isAsset = !coverUrl.startsWith('/') && !coverUrl.startsWith('file:');
      if (isAsset) {
        return Image.asset(
          coverUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(coverUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }
    }
    return _buildFolderPlaceholder(size: size);
  }

  Widget _buildOverlappingSharedAvatars(List<String> userIds, {double size = 20}) {
    if (userIds.isEmpty) return const SizedBox.shrink();
    
    final List<Map<String, dynamic>> matchingProfiles = [];
    for (final id in userIds) {
      final profile = _profilesList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (profile.isNotEmpty) {
        matchingProfiles.add(profile);
      }
    }
    
    if (matchingProfiles.isEmpty) return const SizedBox.shrink();
    
    final displayProfiles = matchingProfiles.take(3).toList();
    return SizedBox(
      width: size + (displayProfiles.length - 1) * (size * 0.5),
      height: size,
      child: Stack(
        children: List.generate(displayProfiles.length, (index) {
          final p = displayProfiles[index];
          final avatarUrl = p['avatar_url'] as String?;
          
          return Positioned(
            left: index * (size * 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (avatarUrl.startsWith('http')
                        ? Image.network(avatarUrl, fit: BoxFit.cover)
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatSharedNames(List<String> userIds) {
    if (userIds.isEmpty) return "Private";
    
    final List<String> names = [];
    for (final id in userIds) {
      final profile = _profilesList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (profile.isNotEmpty) {
        final fName = profile['first_name'] as String? ?? '';
        final name = fName.isNotEmpty ? fName : (profile['username'] as String? ?? 'User');
        names.add(name);
      }
    }
    
    if (names.isEmpty) return "Shared";
    if (names.length == 1) return "with ${names[0]}";
    if (names.length == 2) return "with ${names[0]} and ${names[1]}";
    return "with ${names[0]} and ${names.length - 1} others";
  }

  void _openCreateCollectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateCollectionBottomSheet(
          profilesList: _profilesList,
          isLoadingProfiles: _isLoadingProfiles,
          onCreated: (name, sharedUserIds) async {
            final notifier = ref.read(collectionsViewModelProvider.notifier);
            await notifier.addCollection(name, null, sharedUserIds: sharedUserIds);
            _loadSavedPosts();
          },
        );
      },
    );
  }

  Widget _buildFilterPills() {
    final tabs = ['All', 'Collections', 'Posts'];
    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF7C57FC) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF3B3C4F),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionsGrid(List<CollectionModel> collections, {bool shrinkWrap = false, Axis scrollDirection = Axis.vertical}) {
    if (collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No collections created yet.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF82858C),
            ),
          ),
        ),
      );
    }

    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: 155,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final col = collections[index];
            final isShared = col.sharedUserIds.isNotEmpty;
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CollectionDetailsScreen(
                      collectionId: col.id,
                      collectionName: col.name,
                      onRefresh: () {
                        ref.read(collectionsViewModelProvider.notifier).loadCollections();
                        _loadSavedPosts();
                      },
                    ),
                  ),
                );
                _loadSavedPosts();
              },
              child: Container(
                width: 110,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCollectionCover(col, size: 100),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      col.name,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (isShared) ...[
                          _buildOverlappingSharedAvatars(col.sharedUserIds, size: 14),
                          const SizedBox(width: 4),
                        ] else ...[
                          const Icon(Icons.lock_outline, size: 10, color: Color(0xFF82858C)),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(
                            isShared ? _formatSharedNames(col.sharedUserIds) : 'Private',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 10,
                              color: const Color(0xFF82858C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final col = collections[index];
        final isShared = col.sharedUserIds.isNotEmpty;
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CollectionDetailsScreen(
                  collectionId: col.id,
                  collectionName: col.name,
                  onRefresh: () {
                    ref.read(collectionsViewModelProvider.notifier).loadCollections();
                    _loadSavedPosts();
                  },
                ),
              ),
            );
            _loadSavedPosts();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildCollectionCover(col, size: 150),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                col.name,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isShared) ...[
                    _buildOverlappingSharedAvatars(col.sharedUserIds, size: 16),
                    const SizedBox(width: 4),
                  ] else ...[
                    const Icon(Icons.lock_outline, size: 12, color: Color(0xFF82858C)),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      isShared ? _formatSharedNames(col.sharedUserIds) : 'Private',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 11,
                        color: const Color(0xFF82858C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsGrid(List<TimelinePost> posts, {bool shrinkWrap = false, String? defaultColId}) {
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No saved posts yet.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              color: const Color(0xFF82858C),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () async {
            if (defaultColId == null) return;
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoViewerScreen(
                  posts: posts,
                  initialIndex: index,
                  collectionId: defaultColId,
                ),
              ),
            );
            if (updated == true) {
              _loadSavedPosts();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: post.imageUrl != null
                ? Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildTextGridPlaceholder(post),
                  )
                : _buildTextGridPlaceholder(post),
          ),
        );
      },
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
          const SizedBox(height: 6),
          Text(
            post.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11,
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
    final colState = ref.watch(collectionsViewModelProvider);
    final collections = colState.collections;
    final savedCol = collections.firstWhere(
      (c) => c.name.toLowerCase() == 'saved',
      orElse: () => CollectionModel(id: '', name: '', postIds: []),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Saved',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: _openCreateCollectionSheet,
          ),
        ],
      ),
      body: _isLoadingPosts || colState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C57FC)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                _buildFilterPills(),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_activeTab == 'Collections') {
                        return _buildCollectionsGrid(collections);
                      } else if (_activeTab == 'Posts') {
                        return _buildPostsGrid(_savedPosts, defaultColId: savedCol.id);
                      } else {
                        // 'All' tab
                        if (collections.isEmpty && _savedPosts.isEmpty) {
                          return Center(
                            child: Text(
                              'No saved items yet.',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 14,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (collections.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Text(
                                    'Collections',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                _buildCollectionsGrid(collections, scrollDirection: Axis.horizontal),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                              ],
                              if (_savedPosts.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'All Posts',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                _buildPostsGrid(
                                  _savedPosts,
                                  shrinkWrap: true,
                                  defaultColId: savedCol.id,
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CreateCollectionBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> profilesList;
  final bool isLoadingProfiles;
  final Function(String name, List<String> sharedUserIds) onCreated;

  const _CreateCollectionBottomSheet({
    required this.profilesList,
    required this.isLoadingProfiles,
    required this.onCreated,
  });

  @override
  State<_CreateCollectionBottomSheet> createState() => _CreateCollectionBottomSheetState();
}

class _CreateCollectionBottomSheetState extends State<_CreateCollectionBottomSheet> {
  bool _isAddPeopleView = false;
  final TextEditingController _nameController = TextEditingController();
  bool _isSaveEnabled = false;
  final Set<String> _selectedSharedUserIds = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _isSaveEnabled = _nameController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildOverlappingSharedAvatars(List<String> userIds, {double size = 16}) {
    if (userIds.isEmpty) return const SizedBox.shrink();
    
    final List<Map<String, dynamic>> matchingProfiles = [];
    for (final id in userIds) {
      final profile = widget.profilesList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (profile.isNotEmpty) {
        matchingProfiles.add(profile);
      }
    }
    
    if (matchingProfiles.isEmpty) return const SizedBox.shrink();
    
    final displayProfiles = matchingProfiles.take(3).toList();
    return SizedBox(
      width: size + (displayProfiles.length - 1) * (size * 0.5),
      height: size,
      child: Stack(
        children: List.generate(displayProfiles.length, (index) {
          final p = displayProfiles[index];
          final avatarUrl = p['avatar_url'] as String?;
          
          return Positioned(
            left: index * (size * 0.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? (avatarUrl.startsWith('http')
                        ? Image.network(avatarUrl, fit: BoxFit.cover)
                        : Image.asset(avatarUrl, fit: BoxFit.cover))
                    : Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatSharedNames(List<String> userIds) {
    if (userIds.isEmpty) return "Private";
    
    final List<String> names = [];
    for (final id in userIds) {
      final profile = widget.profilesList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (profile.isNotEmpty) {
        final fName = profile['first_name'] as String? ?? '';
        final name = fName.isNotEmpty ? fName : (profile['username'] as String? ?? 'User');
        names.add(name);
      }
    }
    
    if (names.isEmpty) return "Shared";
    if (names.length == 1) return "with ${names[0]}";
    if (names.length == 2) return "with ${names[0]} and ${names[1]}";
    return "with ${names[0]} and ${names.length - 1} others";
  }

  Widget _buildMainView() {
    final isShared = _selectedSharedUserIds.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC1C1C1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF82858C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'New Collection',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _isSaveEnabled
                    ? () async {
                        final name = _nameController.text.trim();
                        widget.onCreated(name, _selectedSharedUserIds.toList());
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  'Save',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSaveEnabled
                        ? const Color(0xFF7C57FC)
                        : const Color(0xFF82858C).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Collection name',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a collection name',
                hintStyle: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  color: const Color(0xFF82858C),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline, color: Color(0xFF5A5D67)),
            title: Text(
              'Add people to collection',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            subtitle: Row(
              children: [
                if (isShared) ...[
                  _buildOverlappingSharedAvatars(_selectedSharedUserIds.toList(), size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  isShared
                      ? _formatSharedNames(_selectedSharedUserIds.toList())
                      : 'Save to a collection together',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF82858C)),
            onTap: () {
              setState(() {
                _isAddPeopleView = true;
                _searchQuery = "";
              });
            },
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAddPeopleView() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final otherProfiles = widget.profilesList.where((p) => p['id'] != currentUser?.id).toList();
    final filteredProfiles = otherProfiles.where((p) {
      final query = _searchQuery.toLowerCase();
      final username = (p['username'] as String? ?? '').toLowerCase();
      final firstName = (p['first_name'] as String? ?? '').toLowerCase();
      final lastName = (p['last_name'] as String? ?? '').toLowerCase();
      return username.contains(query) || firstName.contains(query) || lastName.contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 56,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC1C1C1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddPeopleView = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF82858C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Add people',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAddPeopleView = false;
                  });
                },
                child: Text(
                  'Done',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    color: const Color(0xFF7C57FC),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: GoogleFonts.ibmPlexSansArabic(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.isLoadingProfiles
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C57FC)))
                : filteredProfiles.isEmpty
                    ? Center(
                        child: Text(
                          "No friends found",
                          style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProfiles.length,
                        itemBuilder: (context, index) {
                          final p = filteredProfiles[index];
                          final pId = p['id'] as String;
                          final username = p['username'] as String? ?? '';
                          final fName = p['first_name'] as String? ?? '';
                          final lName = p['last_name'] as String? ?? '';
                          final fullName = fName.isNotEmpty ? '$fName $lName' : username;
                          final avatarUrl = p['avatar_url'] as String?;
                          final isSelected = _selectedSharedUserIds.contains(pId);
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? (avatarUrl.startsWith('http')
                                      ? NetworkImage(avatarUrl)
                                      : AssetImage(avatarUrl) as ImageProvider)
                                  : const AssetImage('assets/home/images/avatar_placeholder.png'),
                            ),
                            title: Text(
                              fullName,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '@$username',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                            trailing: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF7C57FC) : const Color(0xFFD1D1D6),
                                  width: 2,
                                ),
                                color: isSelected ? const Color(0xFF7C57FC) : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSharedUserIds.remove(pId);
                                } else {
                                  _selectedSharedUserIds.add(pId);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isAddPeopleView ? _buildAddPeopleView() : _buildMainView(),
        ),
      ),
    );
  }
}
