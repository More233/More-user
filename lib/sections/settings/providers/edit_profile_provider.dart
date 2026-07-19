import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileState {
  final String? gender;
  final String? avatarUrl;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final bool success;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final String hometown;

  EditProfileState({
    this.gender,
    this.avatarUrl,
    this.loading = true,
    this.saving = false,
    this.errorMessage,
    this.success = false,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.phone = '',
    this.hometown = '',
  });

  EditProfileState copyWith({
    String? Function()? gender,
    String? Function()? avatarUrl,
    bool? loading,
    bool? saving,
    String? Function()? errorMessage,
    bool? success,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? hometown,
  }) {
    return EditProfileState(
      gender: gender != null ? gender() : this.gender,
      avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      success: success ?? this.success,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      hometown: hometown ?? this.hometown,
    );
  }
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final SupabaseClient _client = Supabase.instance.client;

  EditProfileNotifier() : super(EditProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(loading: true, errorMessage: () => null);
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        state = state.copyWith(
          loading: false,
          gender: () => data['gender'] as String?,
          avatarUrl: () => data['avatar_url'] as String?,
          firstName: data['first_name'] as String? ?? '',
          lastName: data['last_name'] as String? ?? '',
          username: data['username'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          hometown: data['city'] as String? ?? '',
        );
      } else {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      state = state.copyWith(
        loading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void setGender(String? newGender) {
    state = state.copyWith(gender: () => newGender);
  }

  void resetSuccess() {
    state = state.copyWith(success: false);
  }

  Future<void> uploadAvatar(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(saving: true, errorMessage: () => null);
      final fileName = 'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _client.storage.from('post-images').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '31536000', upsert: true),
      );

      final publicUrl = _client.storage.from('post-images').getPublicUrl(fileName);

      await _client.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', user.id);

      state = state.copyWith(
        saving: false,
        avatarUrl: () => publicUrl,
      );
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      state = state.copyWith(
        saving: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> saveChanges({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phone,
    required String hometown,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(saving: true, errorMessage: () => null, success: false);

      final Map<String, dynamic> updates = {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'phone': phone,
        'city': hometown,
      };

      try {
        updates['gender'] = state.gender;
      } catch (_) {}

      await _client.from('profiles').update(updates).eq('id', user.id);

      state = state.copyWith(saving: false, success: true);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      state = state.copyWith(
        saving: false,
        errorMessage: () => e.toString(),
      );
    }
  }
}

final editProfileProvider = StateNotifierProvider.autoDispose<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier();
});
