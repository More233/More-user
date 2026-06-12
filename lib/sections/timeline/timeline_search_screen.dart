import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/timeline_post.dart';
import 'widgets/timeline_post_card.dart';

class TimelineSearchScreen extends StatefulWidget {
  final List<TimelinePost> posts;
  final Function(String) onLikeToggle;
  final Function(String) onBookmarkToggle;

  const TimelineSearchScreen({
    super.key,
    required this.posts,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
  });

  @override
  State<TimelineSearchScreen> createState() => _TimelineSearchScreenState();
}

class _TimelineSearchScreenState extends State<TimelineSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TimelinePost> _searchResults = [];
  String _searchQuery = '';
  final List<String> _searchHistory = [
    'Atmosphere',
    'Croi Bake House',
    'Riyadh Coffee',
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = [];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
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
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            // Search Input Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF82858C), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search by name or username',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            color: const Color(0xFF82858C),
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
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Search Results or History
          Expanded(
            child: _searchQuery.isEmpty ? _buildHistory() : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchHistory.clear();
                  });
                },
                child: Text(
                  'Clear All',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7C57FC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_searchHistory.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No recent searches.',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    color: const Color(0xFF82858C),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchHistory.length,
                itemBuilder: (context, index) {
                  final text = _searchHistory[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, color: Color(0xFF82858C)),
                    title: Text(
                      text,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchHistory.removeAt(index);
                        });
                      },
                      child: const Icon(Icons.close, color: Color(0xFF82858C), size: 16),
                    ),
                    onTap: () {
                      _searchController.text = text;
                      _onSearchChanged(text);
                    },
                  );
                },
              ),
            ),
        ],
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
              // reload result in search feed
              setState(() {
                post.isLiked = !post.isLiked;
                post.likesCount += post.isLiked ? 1 : -1;
              });
            },
            onBookmark: () {
              widget.onBookmarkToggle(post.id);
              setState(() {
                post.isBookmarked = !post.isBookmarked;
              });
            },
            isLastInSection: index == _searchResults.length - 1,
          ),
        );
      },
    );
  }
}
