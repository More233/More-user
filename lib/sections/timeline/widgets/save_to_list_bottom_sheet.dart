import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timeline_post.dart';

class CollectionModel {
  final String id;
  final String name;
  final String? coverImageUrl;
  final List<String> postIds;
  final bool isPrivate;

  CollectionModel({
    required this.id,
    required this.name,
    this.coverImageUrl,
    required this.postIds,
    this.isPrivate = true,
  });
}

class CollectionsManager {
  static final CollectionsManager _instance = CollectionsManager._internal();
  factory CollectionsManager() => _instance;
  CollectionsManager._internal();

  final List<CollectionModel> _collections = [];

  List<CollectionModel> get collections => _collections;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> loadCollections() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final colsResponse = await client
          .from('collections')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      _collections.clear();

      final List<String> userColIds = [];
      for (final colData in colsResponse) {
        userColIds.add(colData['id'] as String);
      }

      dynamic postsResponse = [];
      if (userColIds.isNotEmpty) {
        postsResponse = await client
            .from('collection_posts')
            .select('collection_id, post_id')
            .inFilter('collection_id', userColIds);
      }

      for (final colData in colsResponse) {
        final colId = colData['id'] as String;
        final name = colData['name'] as String;
        final coverUrl = colData['cover_image_url'] as String?;
        final isPrivate = colData['is_private'] as bool? ?? true;

        final List<String> postIds = [];
        if (postsResponse is List) {
          for (final item in postsResponse) {
            if (item['collection_id'] == colId) {
              postIds.add(item['post_id'] as String);
            }
          }
        }

        _collections.add(
          CollectionModel(
            id: colId,
            name: name,
            coverImageUrl: coverUrl,
            postIds: postIds,
            isPrivate: isPrivate,
          ),
        );
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint("Error loading collections from DB: $e");
    }
  }

  Future<String> getOrCreateSavedCollection() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Check memory first
    final idx = _collections.indexWhere((c) => c.name.toLowerCase() == 'saved');
    if (idx != -1) {
      return _collections[idx].id;
    }

    try {
      final existing = await client
          .from('collections')
          .select()
          .eq('user_id', user.id)
          .eq('name', 'Saved')
          .maybeSingle();

      if (existing != null) {
        final colId = existing['id'] as String;
        if (!_collections.any((c) => c.id == colId)) {
          _collections.add(CollectionModel(
            id: colId,
            name: 'Saved',
            coverImageUrl: existing['cover_image_url'] as String?,
            postIds: [],
          ));
        }
        return colId;
      }

      final insertResponse = await client.from('collections').insert({
        'name': 'Saved',
        'user_id': user.id,
      }).select().single();

      final colId = insertResponse['id'] as String;
      _collections.add(CollectionModel(
        id: colId,
        name: 'Saved',
        postIds: [],
      ));
      return colId;
    } catch (e) {
      debugPrint("Error in getOrCreateSavedCollection: $e");
      rethrow;
    }
  }

  Future<void> addCollection(String name, String? coverImageUrl) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final insertResponse = await client.from('collections').insert({
        'name': name,
        'cover_image_url': coverImageUrl,
        'user_id': user.id,
      }).select().single();

      final colId = insertResponse['id'] as String;
      _collections.add(
        CollectionModel(
          id: colId,
          name: name,
          coverImageUrl: coverImageUrl,
          postIds: [],
        ),
      );
    } catch (e) {
      debugPrint("Error adding collection to DB: $e");
    }
  }

  Future<void> removeCollection(String collectionId) async {
    final client = Supabase.instance.client;
    try {
      await client.from('collections').delete().eq('id', collectionId);
      _collections.removeWhere((c) => c.id == collectionId);
    } catch (e) {
      debugPrint("Error removing collection from DB: $e");
    }
  }

  Future<void> addPostToCollection(String collectionId, String postId) async {
    final client = Supabase.instance.client;

    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      final col = _collections[idx];
      if (!col.postIds.contains(postId)) {
        col.postIds.add(postId);
      }
    }

    try {
      await client.from('collection_posts').upsert({
        'collection_id': collectionId,
        'post_id': postId,
      });
    } catch (e) {
      debugPrint("Error adding post to collection in DB: $e");
    }
  }

  Future<void> removePostFromCollection(String collectionId, String postId) async {
    final client = Supabase.instance.client;

    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      final col = _collections[idx];
      col.postIds.remove(postId);
    }

    try {
      await client
          .from('collection_posts')
          .delete()
          .eq('collection_id', collectionId)
          .eq('post_id', postId);
    } catch (e) {
      debugPrint("Error removing post from collection in DB: $e");
    }
  }

  Future<void> removePostFromAllCollections(String postId) async {
    final client = Supabase.instance.client;

    for (final col in _collections) {
      col.postIds.remove(postId);
    }

    try {
      await client.from('collection_posts').delete().eq('post_id', postId);
    } catch (e) {
      debugPrint("Error removing post from all collections in DB: $e");
    }
  }

  bool isPostInCollection(String collectionId, String postId) {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      return _collections[idx].postIds.contains(postId);
    }
    return false;
  }
}

class SaveToListBottomSheet extends StatefulWidget {
  final TimelinePost post;
  final Function(bool) onSavedStateChanged;

  const SaveToListBottomSheet({
    super.key,
    required this.post,
    required this.onSavedStateChanged,
  });

  @override
  State<SaveToListBottomSheet> createState() => _SaveToListBottomSheetState();
}

class _SaveToListBottomSheetState extends State<SaveToListBottomSheet> {
  bool _isNewCollectionView = false;
  final TextEditingController _collectionNameController = TextEditingController();
  final CollectionsManager _manager = CollectionsManager();
  bool _isSaveButtonEnabled = false;
  bool _isLoading = true;

  Widget _buildCoverImage(String? path, {
    double size = 48,
    CategoryIconType? categoryIcon,
    bool isCollection = false,
  }) {
    final bool isPlaceholder = path == null || path.endsWith('sa.png');

    if (isPlaceholder) {
      if (isCollection) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.folder_rounded,
              color: Color(0xFF7C57FC),
              size: 24,
            ),
          ),
        );
      } else {
        Color bgColor;
        Color iconColor;
        String iconSvg;

        switch (categoryIcon) {
          case CategoryIconType.coffee:
            bgColor = const Color(0xFFFDF6EC);
            iconColor = const Color(0xFFE6A23C);
            iconSvg = 'assets/Timeline/Personal Timeline  Default State/icon/coffee-02.svg';
            break;
          case CategoryIconType.camera:
            bgColor = const Color(0xFFFFF0F5);
            iconColor = const Color(0xFFFF5B9D);
            iconSvg = 'assets/Timeline/Personal Timeline  Default State/icon/camera-01.svg';
            break;
          case CategoryIconType.building:
          default:
            bgColor = const Color(0xFFF2EEFC);
            iconColor = const Color(0xFF7C57FC);
            iconSvg = 'assets/Timeline/Personal Timeline  Default State/icon/building-05.svg';
            break;
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: SvgPicture.asset(
              iconSvg,
              width: size * 0.5,
              height: size * 0.5,
              colorFilter: ColorFilter.mode(
                iconColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      }
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    final isAsset = !path.startsWith('/') && !path.startsWith('file:');
    if (isAsset) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _collectionNameController.addListener(_updateSaveButtonState);
    _initCollections();
  }

  Future<void> _initCollections() async {
    setState(() => _isLoading = true);
    await _manager.loadCollections();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _collectionNameController.removeListener(_updateSaveButtonState);
    _collectionNameController.dispose();
    super.dispose();
  }

  void _updateSaveButtonState() {
    final isNotEmpty = _collectionNameController.text.trim().isNotEmpty;
    if (_isSaveButtonEnabled != isNotEmpty) {
      setState(() {
        _isSaveButtonEnabled = isNotEmpty;
      });
    }
  }

  void _showUnsaveConfirmation() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                'Remove from Saved and\nCollections?',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Removing this will also remove it from all collections',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            InkWell(
              onTap: () async {
                Navigator.pop(dialogCtx); // Close Dialog
                setState(() => _isLoading = true);
                try {
                  final savedCol = _manager.collections.firstWhere(
                    (c) => c.name.toLowerCase() == 'saved',
                    orElse: () => CollectionModel(id: '', name: '', postIds: []),
                  );
                  if (savedCol.id.isNotEmpty) {
                    await _manager.removePostFromCollection(savedCol.id, widget.post.id);
                  }
                  await _manager.removePostFromAllCollections(widget.post.id);
                  await Supabase.instance.client
                      .from('posts')
                      .update({'is_bookmarked': false})
                      .eq('id', widget.post.id);
                  widget.post.isBookmarked = false;
                  widget.onSavedStateChanged(false);
                } catch (e) {
                  debugPrint("Error unsaving post: $e");
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.pop(context); // Close Bottom Sheet
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  'Remove from saved',
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
                padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Future<void> _toggleSavedTile(bool save) async {
    setState(() => _isLoading = true);
    try {
      final savedColId = await _manager.getOrCreateSavedCollection();
      if (save) {
        await _manager.addPostToCollection(savedColId, widget.post.id);
        await Supabase.instance.client
            .from('posts')
            .update({'is_bookmarked': true})
            .eq('id', widget.post.id);
        widget.post.isBookmarked = true;
        widget.onSavedStateChanged(true);
      } else {
        await _manager.removePostFromCollection(savedColId, widget.post.id);
        bool inOther = false;
        for (final col in _manager.collections) {
          if (col.name.toLowerCase() != 'saved' && col.postIds.contains(widget.post.id)) {
            inOther = true;
            break;
          }
        }
        if (!inOther) {
          await Supabase.instance.client
              .from('posts')
              .update({'is_bookmarked': false})
              .eq('id', widget.post.id);
          widget.post.isBookmarked = false;
          widget.onSavedStateChanged(false);
        }
      }
    } catch (e) {
      debugPrint("Error toggling saved tile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMainView() {
    final postImage = widget.post.imageUrl;
    
    final savedCol = _manager.collections.firstWhere(
      (c) => c.name.toLowerCase() == 'saved',
      orElse: () => CollectionModel(id: '', name: '', postIds: []),
    );
    final isSavedInSaved = savedCol.postIds.contains(widget.post.id);

    final customCollections = _manager.collections
        .where((c) => c.name.toLowerCase() != 'saved')
        .toList();

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

          Center(
            child: Text(
              'Save to list',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCoverImage(
                postImage,
                size: 48,
                categoryIcon: widget.post.categoryIcon,
                isCollection: true,
              ),
            ),
            title: Text(
              'Saved',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              'Private',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: const Color(0xFF82858C),
              ),
            ),
            trailing: IconButton(
              icon: SvgPicture.asset(
                isSavedInSaved
                    ? 'assets/Timeline/Save Flow  New Collection Creation/icon/bookmark-02.svg'
                    : 'assets/Timeline/Story/icon/bookmark-02.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSavedInSaved ? const Color(0xFF7C57FC) : const Color(0xFF5A5D67),
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                if (isSavedInSaved) {
                  _showUnsaveConfirmation();
                } else {
                  _toggleSavedTile(true);
                }
              },
            ),
            onTap: () {
              if (isSavedInSaved) {
                _showUnsaveConfirmation();
              } else {
                _toggleSavedTile(true);
              }
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collections',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isNewCollectionView = true;
                    _collectionNameController.clear();
                  });
                },
                child: Text(
                  'New Collection',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C57FC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          customCollections.isEmpty
              ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    'No collections yet',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: const Color(0xFF82858C),
                    ),
                  ),
                )
              : Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: customCollections.length,
                    itemBuilder: (context, index) {
                      final col = customCollections[index];
                      final inCollection = _manager.isPostInCollection(col.id, widget.post.id);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildCoverImage(
                            col.coverImageUrl,
                            size: 48,
                            isCollection: true,
                          ),
                        ),
                        title: Text(
                          col.name,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Private',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12,
                            color: const Color(0xFF82858C),
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () async {
                            setState(() => _isLoading = true);
                            try {
                              if (inCollection) {
                                await _manager.removePostFromCollection(col.id, widget.post.id);
                                bool inOther = false;
                                for (final c in _manager.collections) {
                                  if (c.postIds.contains(widget.post.id)) {
                                    inOther = true;
                                    break;
                                  }
                                }
                                if (!inOther) {
                                  await Supabase.instance.client
                                      .from('posts')
                                      .update({'is_bookmarked': false})
                                      .eq('id', widget.post.id);
                                  widget.post.isBookmarked = false;
                                  widget.onSavedStateChanged(false);
                                }
                              } else {
                                await _manager.addPostToCollection(col.id, widget.post.id);
                                if (!widget.post.isBookmarked) {
                                  await Supabase.instance.client
                                      .from('posts')
                                      .update({'is_bookmarked': true})
                                      .eq('id', widget.post.id);
                                  widget.post.isBookmarked = true;
                                  widget.onSavedStateChanged(true);
                                }
                              }
                            } catch (e) {
                              debugPrint("Error toggling custom collection: $e");
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              inCollection
                                  ? 'assets/Timeline/Save Flow  New Collection Creation/icon/checkmark-circle-01.svg'
                                  : 'assets/Timeline/Save Flow  New Collection Creation/icon/add-circle.svg',
                              width: 28,
                              height: 28,
                              colorFilter: ColorFilter.mode(
                                inCollection ? const Color(0xFF5D5D5D) : const Color(0xFF82858C),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        onTap: () async {
                          setState(() => _isLoading = true);
                          try {
                            if (inCollection) {
                              await _manager.removePostFromCollection(col.id, widget.post.id);
                              bool inOther = false;
                              for (final c in _manager.collections) {
                                if (c.postIds.contains(widget.post.id)) {
                                  inOther = true;
                                  break;
                                }
                              }
                              if (!inOther) {
                                await Supabase.instance.client
                                    .from('posts')
                                    .update({'is_bookmarked': false})
                                    .eq('id', widget.post.id);
                                widget.post.isBookmarked = false;
                                widget.onSavedStateChanged(false);
                              }
                            } else {
                              await _manager.addPostToCollection(col.id, widget.post.id);
                              if (!widget.post.isBookmarked) {
                                await Supabase.instance.client
                                    .from('posts')
                                    .update({'is_bookmarked': true})
                                    .eq('id', widget.post.id);
                                widget.post.isBookmarked = true;
                                widget.onSavedStateChanged(true);
                              }
                            }
                          } catch (e) {
                            debugPrint("Error toggling custom collection: $e");
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNewCollectionForm() {
    final postImage = widget.post.imageUrl;

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
                onTap: () {
                  setState(() {
                    _isNewCollectionView = false;
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
                'New Collection',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _isSaveButtonEnabled
                    ? () async {
                        final name = _collectionNameController.text.trim();
                        setState(() => _isLoading = true);
                        try {
                          await _manager.addCollection(name, postImage);
                          final newCol = _manager.collections.firstWhere((c) => c.name == name);
                          await _manager.addPostToCollection(newCol.id, widget.post.id);

                          if (!widget.post.isBookmarked) {
                            await Supabase.instance.client
                                .from('posts')
                                .update({'is_bookmarked': true})
                                .eq('id', widget.post.id);
                            widget.post.isBookmarked = true;
                            widget.onSavedStateChanged(true);
                          }
                        } catch (e) {
                          debugPrint("Error creating new collection: $e");
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                              _isNewCollectionView = false;
                            });
                          }
                        }
                      }
                    : null,
                child: Text(
                  'Save',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSaveButtonEnabled
                        ? const Color(0xFF7C57FC)
                        : const Color(0xFF82858C).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildCoverImage(
                postImage,
                size: 200,
                categoryIcon: widget.post.categoryIcon,
                isCollection: false,
              ),
            ),
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
              controller: _collectionNameController,
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
        child: _isLoading
            ? const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7C57FC),
                  ),
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isNewCollectionView ? _buildNewCollectionForm() : _buildMainView(),
              ),
      ),
    );
  }
}
