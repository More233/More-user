import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedAccount {
  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;
  final String username;
  final String fullName;
  final String? avatarUrl;

  SavedAccount({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.username,
    required this.fullName,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'username': username,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        userId: json['userId'] ?? '',
        email: json['email'] ?? '',
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        username: json['username'] ?? '',
        fullName: json['fullName'] ?? '',
        avatarUrl: json['avatarUrl'],
      );
}

class AccountManager {
  static const String _key = 'saved_accounts';

  // Get all saved accounts
  static Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    try {
      final list = json.decode(jsonStr) as List;
      return list.map((item) => SavedAccount.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error parsing saved accounts: $e");
      return [];
    }
  }

  // Save/Update current session to the list of saved accounts
  static Future<void> saveCurrentAccount() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) return;

    final userId = session.user.id;
    final email = session.user.email ?? '';
    final accessToken = session.accessToken;
    final refreshToken = session.refreshToken ?? '';

    try {
      final profile = await client.from('profiles').select().eq('id', userId).maybeSingle();
      if (profile != null) {
        final username = profile['username'] ?? '';
        final fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        final avatarUrl = profile['avatar_url'] as String?;

        final accounts = await getSavedAccounts();
        // Remove duplicate if already exists
        accounts.removeWhere((acc) => acc.userId == userId);

        accounts.add(SavedAccount(
          userId: userId,
          email: email,
          accessToken: accessToken,
          refreshToken: refreshToken,
          username: username,
          fullName: fullName.isNotEmpty ? fullName : username,
          avatarUrl: avatarUrl,
        ));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, json.encode(accounts.map((e) => e.toJson()).toList()));
      }
    } catch (e) {
      debugPrint("Error saving current account: $e");
    }
  }

  // Switch to a saved account
  static Future<bool> switchToAccount(String userId) async {
    final accounts = await getSavedAccounts();
    final index = accounts.indexWhere((acc) => acc.userId == userId);
    if (index == -1) return false;

    final target = accounts[index];
    
    // Save current session before switching to preserve it!
    await saveCurrentAccount();

    try {
      final response = await Supabase.instance.client.auth.setSession(target.refreshToken);
      return response.session != null;
    } catch (e) {
      debugPrint("Error switching account: $e");
      return false;
    }
  }

  // Logout/Remove an account from saved list
  static Future<void> removeAccount(String userId) async {
    final accounts = await getSavedAccounts();
    accounts.removeWhere((acc) => acc.userId == userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(accounts.map((e) => e.toJson()).toList()));
  }
}
