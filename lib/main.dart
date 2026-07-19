import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sections/splash/splash_screen.dart';
import 'services/notification_service.dart';

import 'sections/settings/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://ymljyjiiatrouzufcnpw.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltbGp5amlpYXRyb3V6dWZjbnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyODMxMzMsImV4cCI6MjA5Njg1OTEzM30.OZS7T7_MrJ1xBjxJejGQCa5jZ5fwqGCECI_UI-KVlJU',
  );

  // Initialize push notifications (fail-safe) asynchronously to avoid blocking app launch
  NotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'More Onboarding Flow',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        dividerColor: const Color(0xFFE8E8E8),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE8E8E8),
          thickness: 1.0,
        ),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF7C57FC),
          primary: const Color(0xFF7C57FC),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1219),
        dividerColor: const Color(0xFF1E2433),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E2433),
          thickness: 1.0,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF131722),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF131722),
          modalBackgroundColor: Color(0xFF131722),
        ),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF7C57FC),
          primary: const Color(0xFF7C57FC),
          surface: const Color(0xFF181C26),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            final FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: child,
        );
      },
      home: const SplashScreen(),
    );
  }
}
