import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sections/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ymljyjiiatrouzufcnpw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltbGp5amlpYXRyb3V6dWZjbnB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyODMxMzMsImV4cCI6MjA5Njg1OTEzM30.OZS7T7_MrJ1xBjxJejGQCa5jZ5fwqGCECI_UI-KVlJU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'More Onboarding Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C57FC)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
