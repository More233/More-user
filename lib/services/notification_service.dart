import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Fail-safe initialization in case GoogleService-Info.plist is missing or invalid
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint("Firebase Messaging initialized successfully.");

      final messaging = FirebaseMessaging.instance;

      // Request user permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("User granted push notification permission.");

        // Get the initial token and sync to Supabase
        await updateTokenInSupabase();

        // Listen for token refreshes and sync them
        messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToSupabase(newToken);
        });
      }
    } catch (e) {
      debugPrint("Firebase Messaging initialization skipped (e.g. missing GoogleService-Info.plist): $e");
    }
  }

  Future<void> updateTokenInSupabase() async {
    if (!_isInitialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint("Error retrieving FCM Token: $e");
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('profiles').update({'fcm_token': token}).eq('id', user.id);
        debugPrint("Successfully saved FCM Token to Supabase profile.");
      }
    } catch (e) {
      debugPrint("Failed to sync FCM Token to Supabase profiles: $e");
    }
  }
}
