import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notifications_state.dart';

final notificationsViewModelProvider = StateNotifierProvider<NotificationsViewModel, NotificationsState>((ref) {
  return NotificationsViewModel();
});

class NotificationsViewModel extends StateNotifier<NotificationsState> {
  NotificationsViewModel() : super(NotificationsState.initial());

  RealtimeChannel? _notificationsSubscription;

  Future<void> init() async {
    await loadNotifications();
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;
    if (currentUser == null) return;

    _notificationsSubscription?.unsubscribe();
    _notificationsSubscription = client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            debugPrint("Realtime notification change received: $payload");
            final newRecord = payload.newRecord;
            if (newRecord['receiver_id'] == currentUser.id) {
              loadNotifications();
            }
          },
        );
    _notificationsSubscription?.subscribe();
  }

  @override
  void dispose() {
    _notificationsSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    try {
      state = state.copyWith(isLoading: true);
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

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
        } else if (type == 'comment_mention') {
          final commentText = row['metadata']?['comment'] as String? ?? '';
          text = 'mentioned you in a comment: "$commentText"';
        } else if (type == 'mention') {
          text = 'mentioned you in their story.';
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

      bool hasUnread = false;
      int unreadCount = 0;
      if (activities.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final lastSeenStr = prefs.getString('last_seen_notifications_time');
          if (lastSeenStr != null) {
            final lastSeen = DateTime.parse(lastSeenStr);
            for (var row in response) {
              final createdAt = DateTime.parse(row['created_at'] as String);
              if (createdAt.isAfter(lastSeen)) {
                unreadCount++;
              }
            }
          } else {
            unreadCount = activities.length;
          }
        } catch (e) {
          debugPrint("Error checking unread notifications: $e");
        }
      }
      hasUnread = unreadCount > 0;

      state = state.copyWith(
        activities: activities,
        isLoading: false,
        hasUnread: hasUnread,
        unreadCount: unreadCount,
      );
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead() async {
    state = state.copyWith(hasUnread: false, unreadCount: 0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_notifications_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint("Error saving last seen notifications time: $e");
    }
  }

  Future<void> toggleFollowBack(String senderId, bool isFollowing) async {
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      final updatedActivities = List<Map<String, dynamic>>.from(state.activities);
      final index = updatedActivities.indexWhere((a) => a['sender_id'] == senderId);
      if (index != -1) {
        updatedActivities[index] = {
          ...updatedActivities[index],
          'isFollowing': !isFollowing,
        };
        state = state.copyWith(activities: updatedActivities);
      }

      if (!isFollowing) {
        // Follow back
        await client.from('follows').insert({
          'follower_id': currentUser.id,
          'following_id': senderId,
        });

        // Insert follow notification so the other user gets notified
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
      // Rollback
      final updatedActivities = List<Map<String, dynamic>>.from(state.activities);
      final index = updatedActivities.indexWhere((a) => a['sender_id'] == senderId);
      if (index != -1) {
        updatedActivities[index] = {
          ...updatedActivities[index],
          'isFollowing': isFollowing,
        };
        state = state.copyWith(activities: updatedActivities);
      }
    }
  }
}
