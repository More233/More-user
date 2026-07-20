import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const MethodChannel _badgeChannel = MethodChannel('com.app.more/badge_utils');

  static Future<void> updateBadgeCount(int count) async {
    try {
      await _badgeChannel.invokeMethod('setBadgeCount', count);
      debugPrint("Successfully set native badge count to: $count");
    } catch (e) {
      debugPrint("Error setting native badge count: $e");
    }
  }

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

      // Set options to display notification even when app is in the foreground
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("User granted push notification permission.");

        // Get the initial token and sync to Supabase
        await updateTokenInSupabase();

        // Listen for token refreshes and sync them
        messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToSupabase(newToken);
        });

        // Handler for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Foreground notification received: ${message.notification?.title}");
          _showForegroundBanner(message);
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

  static void _showForegroundBanner(RemoteMessage message) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    final title = message.notification?.title ?? 'More';
    final body = message.notification?.body ?? '';
    final bannerKey = GlobalKey<_TopNotificationBannerState>();

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TopNotificationBanner(
              key: bannerKey,
              title: title,
              body: body,
              onTap: () {
                // Dismiss banner on tap
              },
              onDismiss: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
            ),
          ),
        );
      },
    );

    navigatorKey.currentState?.overlay?.insert(overlayEntry);

    // Auto dismiss after 4 seconds with slide up animation
    Future.delayed(const Duration(seconds: 4), () {
      if (bannerKey.currentState != null && bannerKey.currentState!.mounted) {
        bannerKey.currentState!.dismiss();
      }
    });
  }
}

class TopNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const TopNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  Future<void> dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          dismiss();
        },
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -5) {
            dismiss();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1E2433).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.9),
                  border: Border.all(
                    color: isDark 
                        ? const Color(0xFF3B404E).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C57FC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
