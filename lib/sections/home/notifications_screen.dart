import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showBackButton;
  const NotificationsScreen({super.key, this.showBackButton = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final results = await Future.wait<dynamic>([
        client
            .from('follows')
            .select('following_id')
            .eq('follower_id', currentUser.id),
        client
            .from('notifications')
            .select('*, sender:profiles!notifications_sender_id_fkey(id, username, first_name, last_name, avatar_url)')
            .eq('receiver_id', currentUser.id)
            .order('created_at', ascending: false),
      ]);

      final followsResponse = results[0];
      final response = results[1] as List<dynamic>;

      final followingIds = List<Map<String, dynamic>>.from(followsResponse as List)
          .map((f) => f['following_id'] as String)
          .toSet();

      final List<Map<String, dynamic>> activities = [];
      for (var row in response) {
        final sender = row['sender'];
        if (sender == null) continue;

        final senderId = sender['id'] as String;
        final senderUsername = sender['username'] as String? ?? 'unknown';
        final senderAvatar = sender['avatar_url'] as String?;
        final type = row['type'] as String;
        final createdAt = DateTime.parse(row['created_at'] as String);

        String text = '';
        if (type == 'follow') {
          text = 'started following you.';
        } else if (type == 'like') {
          text = 'liked your check-in.';
        } else if (type == 'comment') {
          final commentText = row['metadata']?['comment'] as String? ?? '';
          text = 'commented on your check-in: "$commentText"';
        }

        // Relative time formatting
        final timeDiff = DateTime.now().difference(createdAt.toLocal());
        String timeStr = 'now';
        if (timeDiff.inDays > 0) {
          timeStr = '${timeDiff.inDays}d';
        } else if (timeDiff.inHours > 0) {
          timeStr = '${timeDiff.inHours}h';
        } else if (timeDiff.inMinutes > 0) {
          timeStr = '${timeDiff.inMinutes}m';
        }

        activities.add({
          'id': row['id'],
          'sender_id': senderId,
          'username': senderUsername,
          'avatar_url': senderAvatar,
          'text': text,
          'type': type,
          'time': timeStr,
          'isFollowing': followingIds.contains(senderId),
        });
      }

      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollowBack(Map<String, dynamic> act) async {
    final senderId = act['sender_id'] as String;
    final isFollowing = act['isFollowing'] as bool;
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      act['isFollowing'] = !isFollowing;
    });

    try {
      if (!isFollowing) {
        // Follow
        await client.from('follows').upsert({
          'follower_id': currentUser.id,
          'following_id': senderId,
        });

        // Insert notification for them
        await client.from('notifications').insert({
          'sender_id': currentUser.id,
          'receiver_id': senderId,
          'type': 'follow',
        });
      } else {
        // Unfollow
        await client
            .from('follows')
            .delete()
            .eq('follower_id', currentUser.id)
            .eq('following_id', senderId);
      }
    } catch (e) {
      debugPrint("Error toggling follow back: $e");
      setState(() {
        act['isFollowing'] = isFollowing; // rollback
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: SvgPicture.asset(
                    'assets/home/icons/arrow_left_01.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              )
            : null,
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C57FC),
                    ),
                  )
                : (_activities.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _activities.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return _buildActivityItem(activity, index);
                        },
                      )),
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
              'assets/home/icons/notificationlg_02.svg',
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
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: act['avatar_url'] != null && (act['avatar_url'] as String).isNotEmpty
              ? NetworkImage(act['avatar_url'] as String) as ImageProvider
              : const AssetImage(
                  'assets/home/images/element.png',
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
              onPressed: () => _toggleFollowBack(act),
              child: Text(
                act['isFollowing'] ? 'Following' : 'Follow back',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: act['isFollowing'] ? const Color(0xFF82858C) : Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
