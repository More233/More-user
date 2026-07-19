import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/timeline_post.dart';
import '../../models/collection_model.dart';
import '../../models/collections_state.dart';
import '../../view_models/collections_view_model.dart';

class SaveToListBottomSheet extends ConsumerStatefulWidget {
  final TimelinePost post;
  final Function(bool) onSavedStateChanged;

  const SaveToListBottomSheet({
    super.key,
    required this.post,
    required this.onSavedStateChanged,
  });

  @override
  ConsumerState<SaveToListBottomSheet> createState() => _SaveToListBottomSheetState();
}

class _SaveToListBottomSheetState extends ConsumerState<SaveToListBottomSheet> {
  bool _isNewCollectionView = false;
  bool _isAddPeopleView = false;
  final TextEditingController _collectionNameController = TextEditingController();
  bool _isSaveButtonEnabled = false;
  
  final Set<String> _selectedSharedUserIds = {};
  List<Map<String, dynamic>> _profilesList = [];
  bool _isLoadingProfiles = true;
  String _addPeopleSearchQuery = "";
  Timer? _searchDebounce;

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
            iconSvg = 'assets/home/icons/coffee_02.svg';
            break;
          case CategoryIconType.camera:
            bgColor = const Color(0xFFFFF0F5);
            iconColor = const Color(0xFFFF5B9D);
            iconSvg = 'assets/home/icons/camera_01_1.svg';
            break;
          case CategoryIconType.building:
          default:
            bgColor = const Color(0xFFF2EEFC);
            iconColor = const Color(0xFF7C57FC);
            iconSvg = 'assets/home/icons/building_05.svg';
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
      return CachedNetworkImage(
        imageUrl: path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Center(
              child: CupertinoActivityIndicator(
                color: Color(0xFF7C57FC),
                radius: 8,
              ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
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
    Future.microtask(() {
      ref.read(collectionsViewModelProvider.notifier).init();
      _loadProfiles();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _collectionNameController.removeListener(_updateSaveButtonState);
    _collectionNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final Set<String> idsToFetch = {};
      if (currentUser != null) {
        idsToFetch.add(currentUser.id);
      }

      final collections = ref.read(collectionsViewModelProvider).collections;
      for (final col in collections) {
        idsToFetch.addAll(col.sharedUserIds);
      }

      if (idsToFetch.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', idsToFetch.toList());
        if (mounted) {
          setState(() {
            _profilesList = List<Map<String, dynamic>>.from(res);
            _isLoadingProfiles = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _profilesList = [];
            _isLoadingProfiles = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profiles: $e");
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  Future<void> _loadAllProfilesForSearch() async {
    setState(() => _isLoadingProfiles = true);
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, username, first_name, last_name, avatar_url')
          .limit(100);
      if (mounted) {
        setState(() {
          final existingIds = _profilesList.map((p) => p['id']).toSet();
          for (final p in res) {
            if (!existingIds.contains(p['id'])) {
              _profilesList.add(p);
            }
          }
          _isLoadingProfiles = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profiles for search: $e");
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  void _onSearchQueryChanged(String val) {
    setState(() {
      _addPeopleSearchQuery = val;
    });

    if (val.trim().isEmpty) return;

    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .or('username.ilike.%$val%,first_name.ilike.%$val%,last_name.ilike.%$val%')
            .limit(50);
        if (mounted) {
          setState(() {
            final existingIds = _profilesList.map((p) => p['id']).toSet();
            for (final p in res) {
              if (!existingIds.contains(p['id'])) {
                _profilesList.add(p);
              }
            }
          });
        }
      } catch (e) {
        debugPrint("Error searching profiles: $e");
      }
    });
  }

  Widget _buildOverlappingSharedAvatars(List<String> userIds, {double size = 24}) {
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
                        ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => Image.asset('assets/home/images/avatar_placeholder.png', fit: BoxFit.cover))
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
                Navigator.pop(dialogCtx);
                final notifier = ref.read(collectionsViewModelProvider.notifier);
                final state = ref.read(collectionsViewModelProvider);
                try {
                  final savedCol = state.collections.firstWhere(
                    (c) => c.name.toLowerCase() == 'saved',
                    orElse: () => CollectionModel(id: '', name: '', postIds: []),
                  );
                  if (savedCol.id.isNotEmpty) {
                    await notifier.removePostFromCollection(savedCol.id, widget.post.id);
                  }
                  await notifier.removePostFromAllCollections(widget.post.id);
                  await notifier.updatePostBookmarkState(widget.post.id, false);
                  widget.post.isBookmarked = false;
                  widget.onSavedStateChanged(false);
                } catch (e) {
                  debugPrint("Error unsaving post: $e");
                } finally {
                  if (mounted) {
                    Navigator.pop(context);
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
    final notifier = ref.read(collectionsViewModelProvider.notifier);
    final state = ref.read(collectionsViewModelProvider);
    try {
      final savedColId = await notifier.getOrCreateSavedCollection();
      if (save) {
        await notifier.addPostToCollection(savedColId, widget.post.id);
        await notifier.updatePostBookmarkState(widget.post.id, true);
        widget.post.isBookmarked = true;
        widget.onSavedStateChanged(true);
      } else {
        await notifier.removePostFromCollection(savedColId, widget.post.id);
        bool inOther = false;
        for (final col in state.collections) {
          if (col.name.toLowerCase() != 'saved' && col.postIds.contains(widget.post.id)) {
            inOther = true;
            break;
          }
        }
        if (!inOther) {
          await notifier.updatePostBookmarkState(widget.post.id, false);
          widget.post.isBookmarked = false;
          widget.onSavedStateChanged(false);
        }
      }
    } catch (e) {
      debugPrint("Error toggling saved tile: $e");
    }
  }

  Widget _buildMainView(CollectionsState colState) {
    final postImage = widget.post.imageUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color dragHandleColor = isDark ? const Color(0xFF323A4E) : const Color(0xFFC1C1C1);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);

    final savedCol = colState.collections.firstWhere(
      (c) => c.name.toLowerCase() == 'saved',
      orElse: () => CollectionModel(id: '', name: '', postIds: []),
    );
    final isSavedInSaved = savedCol.postIds.contains(widget.post.id);

    final customCollections = colState.collections
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
                color: dragHandleColor,
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
                color: titleColor,
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
                color: textColor,
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
                    ? 'assets/home/icons/bookmark_02.svg'
                    : 'assets/home/icons/bookmark_02_1.svg',
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
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collections',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isNewCollectionView = true;
                    _collectionNameController.clear();
                    _selectedSharedUserIds.clear();
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
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: customCollections.length,
                    itemBuilder: (context, index) {
                      final col = customCollections[index];
                      final notifier = ref.read(collectionsViewModelProvider.notifier);
                      final inCollection = notifier.isPostInCollection(col.id, widget.post.id);
                      final isShared = col.sharedUserIds.isNotEmpty;

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
                            color: textColor,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (isShared) ...[
                              _buildOverlappingSharedAvatars(col.sharedUserIds, size: 16),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(Icons.lock_outline, size: 12, color: Color(0xFF82858C)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              isShared
                                  ? _formatSharedNames(col.sharedUserIds)
                                  : 'Private',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: const Color(0xFF82858C),
                              ),
                            ),
                          ],
                        ),
                        trailing: GestureDetector(
                          onTap: () async {
                            try {
                              if (inCollection) {
                                await notifier.removePostFromCollection(col.id, widget.post.id);
                                bool inOther = false;
                                for (final c in colState.collections) {
                                  if (c.postIds.contains(widget.post.id)) {
                                    inOther = true;
                                    break;
                                  }
                                }
                                if (!inOther) {
                                  await notifier.updatePostBookmarkState(widget.post.id, false);
                                  widget.post.isBookmarked = false;
                                  widget.onSavedStateChanged(false);
                                }
                              } else {
                                await notifier.addPostToCollection(col.id, widget.post.id);
                                if (!widget.post.isBookmarked) {
                                  await notifier.updatePostBookmarkState(widget.post.id, true);
                                  widget.post.isBookmarked = true;
                                  widget.onSavedStateChanged(true);
                                }
                              }
                            } catch (e) {
                              debugPrint("Error toggling custom collection: $e");
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              inCollection
                                  ? 'assets/home/icons/checkmark_circle_01.svg'
                                  : 'assets/home/icons/add_circle.svg',
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
                          try {
                            if (inCollection) {
                              await notifier.removePostFromCollection(col.id, widget.post.id);
                              bool inOther = false;
                              for (final c in colState.collections) {
                                  if (c.postIds.contains(widget.post.id)) {
                                    inOther = true;
                                    break;
                                  }
                              }
                              if (!inOther) {
                                await notifier.updatePostBookmarkState(widget.post.id, false);
                                widget.post.isBookmarked = false;
                                widget.onSavedStateChanged(false);
                              }
                            } else {
                              await notifier.addPostToCollection(col.id, widget.post.id);
                              if (!widget.post.isBookmarked) {
                                await notifier.updatePostBookmarkState(widget.post.id, true);
                                widget.post.isBookmarked = true;
                                widget.onSavedStateChanged(true);
                              }
                            }
                          } catch (e) {
                            debugPrint("Error toggling custom collection: $e");
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

  Widget _buildNewCollectionForm(CollectionsState colState) {
    final postImage = widget.post.imageUrl;
    final isShared = _selectedSharedUserIds.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color dragHandleColor = isDark ? const Color(0xFF323A4E) : const Color(0xFFC1C1C1);
    final Color fieldColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF6F6F6);
    final Color dividerColor = isDark ? const Color(0xFF1E2433) : const Color(0xFFE8E8E8);
    final Color textMutedColor = isDark ? Colors.white70 : const Color(0xFF5A5D67);

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
                color: dragHandleColor,
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
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: _isSaveButtonEnabled
                    ? () async {
                        final name = _collectionNameController.text.trim();
                        final notifier = ref.read(collectionsViewModelProvider.notifier);
                        try {
                          await notifier.addCollection(
                            name,
                            postImage,
                            sharedUserIds: _selectedSharedUserIds.toList(),
                          );
                          
                          // Look up the newly created collection ID
                          final updatedState = ref.read(collectionsViewModelProvider);
                          final newCol = updatedState.collections.firstWhere((c) => c.name == name);
                          await notifier.addPostToCollection(newCol.id, widget.post.id);

                          if (!widget.post.isBookmarked) {
                            await notifier.updatePostBookmarkState(widget.post.id, true);
                            widget.post.isBookmarked = true;
                            widget.onSavedStateChanged(true);
                          }
                        } catch (e) {
                          debugPrint("Error creating new collection: $e");
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isNewCollectionView = false;
                              _selectedSharedUserIds.clear();
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
                size: 150,
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
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _collectionNameController,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: textColor,
              ),
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
          
          // Shared Friends Entry Point
          Divider(height: 1, color: dividerColor),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.people_outline, color: textMutedColor),
            title: Text(
              'Add people to collection',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
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
                _addPeopleSearchQuery = "";
              });
              _loadAllProfilesForSearch();
            },
          ),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAddPeopleView() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final otherProfiles = _profilesList.where((p) => p['id'] != currentUser?.id).toList();
    final filteredProfiles = otherProfiles.where((p) {
      final query = _addPeopleSearchQuery.toLowerCase();
      final username = (p['username'] as String? ?? '').toLowerCase();
      final firstName = (p['first_name'] as String? ?? '').toLowerCase();
      final lastName = (p['last_name'] as String? ?? '').toLowerCase();
      return username.contains(query) || firstName.contains(query) || lastName.contains(query);
    }).toList();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color dragHandleColor = isDark ? const Color(0xFF323A4E) : const Color(0xFFC1C1C1);
    final Color searchBgColor = isDark ? const Color(0xFF1F2430) : const Color(0xFFF2F2F7);

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
                color: dragHandleColor,
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
                  color: textColor,
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
              color: searchBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: _onSearchQueryChanged,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search",
                      hintStyle: GoogleFonts.ibmPlexSansArabic(
                        color: const Color(0xFF82858C),
                        fontSize: 14,
                      ),
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
            child: _isLoadingProfiles
                ? const Center(child: CupertinoActivityIndicator())
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
                                      ? CachedNetworkImageProvider(avatarUrl)
                                      : AssetImage(avatarUrl) as ImageProvider)
                                  : const AssetImage('assets/home/images/avatar_placeholder.png'),
                            ),
                            title: Text(
                              fullName,
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
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
    final colState = ref.watch(collectionsViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: colState.isLoading
            ? const SizedBox(
                height: 250,
                child: Center(
                  child: CupertinoActivityIndicator(
                    color: Color(0xFF7C57FC),
                    radius: 12,
                  ),
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isAddPeopleView
                    ? _buildAddPeopleView()
                    : _isNewCollectionView
                        ? _buildNewCollectionForm(colState)
                        : _buildMainView(colState),
              ),
      ),
    );
  }
}
