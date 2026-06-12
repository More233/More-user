import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notifications list
  final List<Map<String, dynamic>> _activities = [
    {
      'type': 'like',
      'username': 'karennne',
      'avatar': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
      'text': 'liked your photo.',
      'time': '1h',
      'photo': 'assets/Timeline/Personal Timeline  Default State/image/sa.png',
    },
    {
      'type': 'like_multiple',
      'username': 'kiero_d, zackjohn',
      'avatar': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
      'text': 'and 26 others liked your photo.',
      'time': '3h',
      'photo': 'assets/Timeline/Personal Timeline  Default State/image/sa.png',
    },
    {
      'type': 'mention',
      'username': 'craig_love',
      'avatar': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
      'text': 'mentioned you in a comment: @jacob_w exactly.. 💫',
      'time': '2d',
      'photo': 'assets/Timeline/Personal Timeline  Default State/image/sa.png',
    },
    {
      'type': 'follow',
      'username': 'martini_rond',
      'avatar': 'assets/Timeline/Personal Timeline  Default State/image/Element.png',
      'text': 'started following you.',
      'time': '3d',
      'isFollowing': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          'Activity',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return _buildActivityItem(activity, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> act, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // User Avatar
        const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(
            'assets/Timeline/Personal Timeline  Default State/image/Element.png',
          ),
        ),
        const SizedBox(width: 12),
        // Content Text
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: act['username'],
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: act['text'],
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF3B3C4F),
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: act['time'],
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: const Color(0xFF82858C),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Action: Either Photo Preview or Follow button
        if (act['type'] == 'follow')
          SizedBox(
            height: 32,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: act['isFollowing'] ? Colors.white : const Color(0xFF7C57FC),
                side: BorderSide(
                  color: act['isFollowing'] ? const Color(0xFFC8C8C8) : const Color(0xFF7C57FC),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () {
                setState(() {
                  act['isFollowing'] = !act['isFollowing'];
                });
              },
              child: Text(
                act['isFollowing'] ? 'Following' : 'Follow back',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: act['isFollowing'] ? const Color(0xFF82858C) : Colors.white,
                ),
              ),
            ),
          )
        else if (act['photo'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              act['photo'],
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }
}
