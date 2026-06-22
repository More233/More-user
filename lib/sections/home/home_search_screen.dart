import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/timeline_post.dart';
import 'view_models/collections_view_model.dart';
import 'widgets/timeline_post_card.dart';
import 'widgets/check_in_composer_screen.dart';
import 'widgets/jump_to_date_bottom_sheet.dart';
import 'widgets/save_to_list_bottom_sheet.dart';

class TimelineSearchScreen extends ConsumerStatefulWidget {
  final List<TimelinePost> posts;
  final Function(String) onLikeToggle;
  final Function(String, bool) onBookmarkToggle;
  final VoidCallback? onPostUpdated;

  const TimelineSearchScreen({
    super.key,
    required this.posts,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    this.onPostUpdated,
  });

  @override
  ConsumerState<TimelineSearchScreen> createState() => _TimelineSearchScreenState();
}

class _TimelineSearchScreenState extends ConsumerState<TimelineSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TimelinePost> _searchResults = [];
  String _searchQuery = '';
  DateTime? _selectedDate;
  String? _selectedDateText;

  @override
  void initState() {
    super.initState();
    _searchResults = [];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      // Clear date filter if user starts typing a text search
      if (query.isNotEmpty && _selectedDateText != null) {
        _selectedDate = null;
        _selectedDateText = null;
      }
      
      if (query.trim().isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = widget.posts
            .where((post) =>
                post.title.toLowerCase().contains(query.toLowerCase()) ||
                post.locationAddress.toLowerCase().contains(query.toLowerCase()) ||
                post.categoryName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectDate() async {
    final date = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => JumpToDateBottomSheet(
        initialDate: _selectedDate ?? DateTime.now(),
      ),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedDateText = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        _searchQuery = _selectedDateText!;
        _searchController.clear(); // Clear text search to show date results
        _searchResults = widget.posts.where((post) {
          if (post.createdAt == null) return false;
          final postDate = post.createdAt!.toLocal();
          return postDate.year == date.year &&
              postDate.month == date.month &&
              postDate.day == date.day;
        }).toList();
      });
    }
  }

  void _editPost(TimelinePost post) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckInComposerScreen(
          editPost: post,
        ),
      ),
    );

    if (result == true) {
      widget.onPostUpdated?.call();
      setState(() {
        _onSearchChanged(_searchQuery);
      });
    }
  }

  void _confirmDeletePost(TimelinePost post) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 286,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete this check-in?',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF323232),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Delete Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(post.id);
                  },
                  child: Container(
                    width: 286,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                        bottom: BorderSide(color: Color(0xFFBFBFBF), width: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Delete',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFD80000),
                      ),
                    ),
                  ),
                ),
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 286,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF373737),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      final client = Supabase.instance.client;
      await client.from('posts').delete().eq('id', postId);
      
      if (mounted) {
        setState(() {
          widget.posts.removeWhere((p) => p.id == postId);
          _searchResults.removeWhere((p) => p.id == postId);
        });
        widget.onPostUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Check-in deleted successfully."),
            backgroundColor: Color(0xFF7C57FC),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting post: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete check-in: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openSaveToList(TimelinePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SaveToListBottomSheet(
          post: post,
          onSavedStateChanged: (isSaved) {
            setState(() {
              post.isBookmarked = isSaved;
            });
            widget.onBookmarkToggle(post.id, isSaved);
            widget.onPostUpdated?.call();
          },
        );
      },
    );
  }

  Future<void> _handleBookmarkTap(TimelinePost post) async {
    final notifier = ref.read(collectionsViewModelProvider.notifier);
    final colState = ref.read(collectionsViewModelProvider);

    if (post.isBookmarked) {
      _openSaveToList(post);
    } else {
      if (colState.collections.isEmpty) {
        try {
          final savedColId = await notifier.getOrCreateSavedCollection();
          await notifier.addPostToCollection(savedColId, post.id);
          setState(() {
            post.isBookmarked = true;
          });
          widget.onBookmarkToggle(post.id, true);
          widget.onPostUpdated?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Saved to Saved list"),
                backgroundColor: Color(0xFF7C57FC),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error auto-saving post: $e");
        }
      } else {
        _openSaveToList(post);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Search Input Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/home/icons/search_01.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF82858C),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search your history',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(Icons.close, color: Color(0xFF82858C), size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.ibmPlexSansArabic(
                  color: const Color(0xFF7C57FC),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Jump to date picker tag
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _selectedDateText != null ? null : _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE6FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/home/icons/calendar_03.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF7C57FC),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDateText ?? 'Jump to',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: const Color(0xFF7C57FC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedDateText != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = null;
                              _selectedDateText = null;
                              _searchQuery = '';
                              _searchResults = [];
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF7C57FC),
                          ),
                        )
                      else
                        SvgPicture.asset(
                          'assets/home/icons/arrow_down_01_1.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF7C57FC),
                            BlendMode.srcIn,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Search Results or Suggested Searches
          Expanded(
            child: _searchQuery.isEmpty ? _buildSuggestedSearches() : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedSearches() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 16),
            child: Text(
              'Suggested Searches',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          // Item 1: Atmosphere (Coffee Shop)
          _buildSuggestedItem(
            iconPath: 'assets/home/icons/coffee_02.svg',
            title: 'ATMOSPHERE',
            subtitle: 'Coffee Shop • Al-Malik Fahd, Riyadh',
            timeText: 'Last Check-in • Today 5:38 PM',
            onTap: () {
              _searchController.text = 'ATMOSPHERE';
              _onSearchChanged('ATMOSPHERE');
            },
          ),
          const SizedBox(height: 12),
          // Item 2: Location
          _buildSuggestedItem(
            iconPath: 'assets/home/icons/location_01.svg',
            title: 'Muhafazat al Fayyūm, Egypt',
            onTap: () {
              _searchController.text = 'Muhafazat al Fayyūm, Egypt';
              _onSearchChanged('Muhafazat al Fayyūm, Egypt');
            },
          ),
          const SizedBox(height: 12),
          // Item 3: Category
          _buildSuggestedItem(
            iconPath: 'assets/home/icons/record.svg',
            title: 'Travel and Transportation',
            onTap: () {
              _searchController.text = 'Travel and Transportation';
              _onSearchChanged('Travel and Transportation');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedItem({
    required String iconPath,
    required String title,
    String? subtitle,
    String? timeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon Container
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF2EEFC),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7C57FC),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF303030),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  if (timeText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: const Color(0xFF3B3C4F).withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No results found for "$_searchQuery"',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: const Color(0xFF82858C),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TimelinePostCard(
            post: post,
            onLike: () {
              widget.onLikeToggle(post.id);
              setState(() {
                post.isLiked = !post.isLiked;
                post.likesCount += post.isLiked ? 1 : -1;
              });
            },
            onBookmark: () => _handleBookmarkTap(post),
            onEdit: () => _editPost(post),
            onDelete: () => _confirmDeletePost(post),
            isLastInSection: index == _searchResults.length - 1,
          ),
        );
      },
    );
  }
}
