import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsListState {
  final List<Map<String, String>> allFriends;
  final List<Map<String, String>> filteredFriends;
  final Set<String> selectedUsernames;
  final bool isLoading;

  FriendsListState({
    required this.allFriends,
    required this.filteredFriends,
    required this.selectedUsernames,
    required this.isLoading,
  });

  factory FriendsListState.initial() {
    return FriendsListState(
      allFriends: [],
      filteredFriends: [],
      selectedUsernames: {},
      isLoading: true,
    );
  }

  FriendsListState copyWith({
    List<Map<String, String>>? allFriends,
    List<Map<String, String>>? filteredFriends,
    Set<String>? selectedUsernames,
    bool? isLoading,
  }) {
    return FriendsListState(
      allFriends: allFriends ?? this.allFriends,
      filteredFriends: filteredFriends ?? this.filteredFriends,
      selectedUsernames: selectedUsernames ?? this.selectedUsernames,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FriendsListViewModel extends StateNotifier<FriendsListState> {
  FriendsListViewModel() : super(FriendsListState.initial()) {
    loadRealUsers();
  }

  Future<void> loadRealUsers() async {
    try {
      state = state.copyWith(isLoading: true);
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final followingResponse = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final followersResponse = await client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUserId);

      final List<String> userIds = [];
      for (var row in followingResponse) {
        final id = row['following_id'] as String?;
        if (id != null) userIds.add(id);
      }
      for (var row in followersResponse) {
        final id = row['follower_id'] as String?;
        if (id != null) userIds.add(id);
      }

      final Map<String, Map<String, String>> usersMap = {};

      void addProfile(dynamic row) {
        if (row == null) return;
        final id = row['id'] as String?;
        if (id == null || id == currentUserId) return;
        final username = row['username'] as String? ?? '';
        final firstName = row['first_name'] as String? ?? '';
        final lastName = row['last_name'] as String? ?? '';
        final avatarUrl = row['avatar_url'] as String? ?? '';
        final name = '$firstName $lastName'.trim();
        usersMap[id] = {
          'id': id,
          'name': name.isNotEmpty ? name : username,
          'username': username,
          'avatar': avatarUrl,
        };
      }

      if (userIds.isNotEmpty) {
        final profilesResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .inFilter('id', userIds);

        for (var row in profilesResponse) {
          addProfile(row);
        }
      }

      if (usersMap.length < 5) {
        final fallbackResponse = await client
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .neq('id', currentUserId)
            .limit(20);

        for (var row in fallbackResponse) {
          addProfile(row);
        }
      }

      final friendsList = usersMap.values.toList();
      state = state.copyWith(
        allFriends: friendsList,
        filteredFriends: friendsList,
        isLoading: false,
      );
    } catch (e) {
      debugPrint("Error loading real users: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void searchFriends(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(filteredFriends: state.allFriends);
    } else {
      final filtered = state.allFriends
          .where((friend) =>
              friend['name']!.toLowerCase().contains(query.toLowerCase()) ||
              friend['username']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      state = state.copyWith(filteredFriends: filtered);
    }
  }

  void toggleSelection(String username) {
    final updated = Set<String>.from(state.selectedUsernames);
    if (updated.contains(username)) {
      updated.remove(username);
    } else {
      updated.add(username);
    }
    state = state.copyWith(selectedUsernames: updated);
  }

  void clearSelection() {
    state = state.copyWith(selectedUsernames: {});
  }
}

// Separate providers for mention sheet and send sheet so their selections don't conflict!
final storyMentionFriendsProvider = StateNotifierProvider.autoDispose<FriendsListViewModel, FriendsListState>((ref) {
  return FriendsListViewModel();
});

final storySendFriendsProvider = StateNotifierProvider.autoDispose<FriendsListViewModel, FriendsListState>((ref) {
  return FriendsListViewModel();
});
