import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notifications list
  final List<Map<String, dynamic>> _activities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: SvgPicture.asset(
              'assets/Timeline/Notifications/icon/arrow-left-01.svg',
              width: 24,
              height: 24,
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          Expanded(
            child: _activities.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x335D5D5D), // rgba(93, 93, 93, 0.2)
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/Timeline/Notifications/icon/notificationlg-02.svg',
              width: 64,
              height: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
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
