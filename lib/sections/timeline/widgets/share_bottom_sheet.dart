import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareBottomSheet extends StatefulWidget {
  const ShareBottomSheet({super.key});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final List<Map<String, String>> _allFriends = [
    {'name': 'Sally Samer', 'username': 'sally.samer.3'},
    {'name': 'Zack John', 'username': 'zackjohn'},
    {'name': 'Kieron D', 'username': 'kiero_d'},
    {'name': 'Craig Love', 'username': 'craig_love'},
    {'name': 'Martini Rond', 'username': 'martini_rond'},
    {'name': 'Jacob West', 'username': 'jacob_w'},
  ];

  List<Map<String, String>> _filteredFriends = [];
  final Set<String> _selectedUsernames = {};

  @override
  void initState() {
    super.initState();
    _filteredFriends = _allFriends;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend['name']!.toLowerCase().contains(query.toLowerCase()) ||
                friend['username']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFC8C8C8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            'Share with friends',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Friends List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = _filteredFriends[index];
                final isSelected = _selectedUsernames.contains(friend['username']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage(
                      'assets/Timeline/Personal Timeline  Default State/image/Element.png',
                    ),
                  ),
                  title: Text(
                    friend['name']!,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '@${friend['username']!}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: const Color(0xFF82858C),
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (bool? val) {
                      setState(() {
                        if (val == true) {
                          _selectedUsernames.add(friend['username']!);
                        } else {
                          _selectedUsernames.remove(friend['username']!);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C57FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _selectedUsernames.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Shared successfully with ${_selectedUsernames.length} friend(s)!',
                                style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
                              ),
                              backgroundColor: const Color(0xFF7C57FC),
                            ),
                          );
                        },
                  child: Text(
                    'Share (${_selectedUsernames.length})',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
