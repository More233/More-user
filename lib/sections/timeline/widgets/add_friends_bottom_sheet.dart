import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddFriendsBottomSheet extends StatefulWidget {
  final List<String> previouslySelected;

  const AddFriendsBottomSheet({super.key, this.previouslySelected = const []});

  @override
  State<AddFriendsBottomSheet> createState() => _AddFriendsBottomSheetState();
}

class _AddFriendsBottomSheetState extends State<AddFriendsBottomSheet> {
  final List<String> _friendsList = [
    'Sally Samer',
    'Craig Love',
    'Zack John',
    'Kieron D',
    'Martini Rond',
    'Jacob West',
  ];

  final List<String> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    _selectedFriends.addAll(widget.previouslySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
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
            'Check-in with Friends',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Scrollable List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _friendsList.length,
              itemBuilder: (context, index) {
                final friend = _friendsList[index];
                final isSelected = _selectedFriends.contains(friend);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(
                      'assets/Timeline Phase need to rename/Timeline Section  Personal Timeline  Default State/image/Element.png',
                    ),
                  ),
                  title: Text(
                    friend,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
                          _selectedFriends.add(friend);
                        } else {
                          _selectedFriends.remove(friend);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          // Confirm Button
          Padding(
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
                onPressed: () {
                  Navigator.pop(context, _selectedFriends);
                },
                child: Text(
                  'Add Friends (${_selectedFriends.length})',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
