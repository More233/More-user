import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SupabaseClient _client = Supabase.instance.client;

  SettingsNotifier() : super(SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(loading: true);

      // 1. Fetch profile settings
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        // Parse push settings from JSONB
        final rawPush = profile['push_settings'];
        Map<String, bool> pushSettings = {
          "nearby_check_in_reminders": true,
          "friends_checked_in_nearby": true,
          "mentions_in_check_ins": true,
          "likes_comments_on_check_ins": true,
          "friend_requests": true,
          "messages": true,
          "shared_places_lists": true,
          "new_places_may_like": true,
          "offers_saved_places": true,
        };

        if (rawPush is Map) {
          rawPush.forEach((key, val) {
            if (val is bool) {
              pushSettings[key.toString()] = val;
            }
          });
        }

        state = SettingsState(
          loading: false,
          preferredLanguage: profile['preferred_language'] as String? ?? 'en',
          profileVisibility: profile['profile_visibility'] as String? ?? 'friends',
          friendRequestsVisibility: profile['friend_requests_visibility'] as String? ?? 'friends_of_friends',
          checkInVisibility: profile['check_in_visibility'] as String? ?? 'friends',
          showMeHereNow: profile['show_me_here_now'] as bool? ?? true,
          letFriendsCheckInWithMe: profile['let_friends_check_in_with_me'] as bool? ?? true,
          showStatsStreaks: profile['show_stats_streaks'] as String? ?? 'friends',
          showSavedPlacesProfile: profile['show_saved_places_profile'] as bool? ?? true,
          allowTagsMentions: profile['allow_tags_mentions'] as bool? ?? true,
          pushSettings: pushSettings,
          locationPermission: profile['location_permission'] as String? ?? 'while_using',
          preciseLocation: profile['precise_location'] as bool? ?? true,
          showNearbyPlaces: profile['show_nearby_places'] as bool? ?? true,
          nearbyCheckInPrompts: profile['nearby_check_in_prompts'] as bool? ?? true,
          showCheckInSuggestions: profile['show_check_in_suggestions'] as bool? ?? true,
          suggestPlacesWhenNearby: profile['suggest_places_when_nearby'] as bool? ?? true,
          suggestFromRecentVisits: profile['suggest_from_recent_visits'] as bool? ?? true,
          usePhotoTimeLocation: profile['use_photo_time_location'] as bool? ?? true,
          blockedUsers: state.blockedUsers, // Keep existing list for now, loaded next
        );
      }

      // 2. Fetch blocked users
      await loadBlockedUsers();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      state = state.copyWith(loading: false);
    }
  }

  Future<void> loadBlockedUsers() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final List<dynamic> response = await _client
          .from('blocked_users')
          .select('id, blocked_id, profiles!blocked_users_blocked_id_fkey(id, username, first_name, last_name, avatar_url)')
          .eq('blocker_id', user.id);

      final List<Map<String, dynamic>> blocked = [];
      for (var row in response) {
        final profile = row['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          blocked.add({
            'block_id': row['id'],
            'id': profile['id'],
            'username': profile['username'] ?? '',
            'first_name': profile['first_name'] ?? '',
            'last_name': profile['last_name'] ?? '',
            'avatar_url': profile['avatar_url'],
          });
        }
      }

      state = state.copyWith(blockedUsers: blocked);
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
  }

  Future<void> updateField(String key, dynamic value) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Optimistic UI updates
    _updateLocalState(key, value);

    try {
      await _client.from('profiles').update({key: value}).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating setting $key: $e');
      // Revert if error (reload settings)
      loadSettings();
    }
  }

  Future<void> updatePushSetting(String key, bool value) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final updatedPush = Map<String, bool>.from(state.pushSettings);
    updatedPush[key] = value;

    state = state.copyWith(pushSettings: updatedPush);

    try {
      await _client.from('profiles').update({'push_settings': updatedPush}).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating push setting $key: $e');
      loadSettings();
    }
  }

  void _updateLocalState(String key, dynamic value) {
    switch (key) {
      case 'preferred_language':
        state = state.copyWith(preferredLanguage: value as String);
        break;
      case 'profile_visibility':
        state = state.copyWith(profileVisibility: value as String);
        break;
      case 'friend_requests_visibility':
        state = state.copyWith(friendRequestsVisibility: value as String);
        break;
      case 'check_in_visibility':
        state = state.copyWith(checkInVisibility: value as String);
        break;
      case 'show_me_here_now':
        state = state.copyWith(showMeHereNow: value as bool);
        break;
      case 'let_friends_check_in_with_me':
        state = state.copyWith(letFriendsCheckInWithMe: value as bool);
        break;
      case 'show_stats_streaks':
        state = state.copyWith(showStatsStreaks: value as String);
        break;
      case 'show_saved_places_profile':
        state = state.copyWith(showSavedPlacesProfile: value as bool);
        break;
      case 'allow_tags_mentions':
        state = state.copyWith(allowTagsMentions: value as bool);
        break;
      case 'location_permission':
        state = state.copyWith(locationPermission: value as String);
        break;
      case 'precise_location':
        state = state.copyWith(preciseLocation: value as bool);
        break;
      case 'show_nearby_places':
        state = state.copyWith(showNearbyPlaces: value as bool);
        break;
      case 'nearby_check_in_prompts':
        state = state.copyWith(nearbyCheckInPrompts: value as bool);
        break;
      case 'show_check_in_suggestions':
        state = state.copyWith(showCheckInSuggestions: value as bool);
        break;
      case 'suggest_places_when_nearby':
        state = state.copyWith(suggestPlacesWhenNearby: value as bool);
        break;
      case 'suggest_from_recent_visits':
        state = state.copyWith(suggestFromRecentVisits: value as bool);
        break;
      case 'use_photo_time_location':
        state = state.copyWith(usePhotoTimeLocation: value as bool);
        break;
    }
  }

  Future<bool> blockUser(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      state = state.copyWith(blockingLoading: true);
      await _client.from('blocked_users').insert({
        'blocker_id': user.id,
        'blocked_id': targetUserId,
      });
      await loadBlockedUsers();
      state = state.copyWith(blockingLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      state = state.copyWith(blockingLoading: false);
      return false;
    }
  }

  Future<bool> unblockUser(String targetUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      state = state.copyWith(blockingLoading: true);
      await _client
          .from('blocked_users')
          .delete()
          .eq('blocker_id', user.id)
          .eq('blocked_id', targetUserId);
      await loadBlockedUsers();
      state = state.copyWith(blockingLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      state = state.copyWith(blockingLoading: false);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsersToBlock(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _client
          .from('profiles')
          .select('id, username, first_name, last_name, avatar_url')
          .or('username.ilike.%$query%,first_name.ilike.%$query%,last_name.ilike.%$query%')
          .limit(10);

      final List<Map<String, dynamic>> results = [];
      final currentUser = _client.auth.currentUser;

      for (var row in response as List<dynamic>) {
        if (currentUser != null && row['id'] == currentUser.id) continue;
        results.add(row as Map<String, dynamic>);
      }
      return results;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  Future<bool> submitFeedback({
    required String category,
    required String description,
    required int rating,
    required String? email,
    required String? screenshotUrl,
  }) async {
    final user = _client.auth.currentUser;
    try {
      await _client.from('feedbacks').insert({
        'user_id': user?.id,
        'category': category,
        'description': description,
        'rating': rating,
        'email': email,
        'screenshot_url': screenshotUrl,
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
