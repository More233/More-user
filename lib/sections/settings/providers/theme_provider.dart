import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme == 'light') {
        state = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (e) {
      debugPrint("Error loading theme from SharedPreferences: $e");
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeValue = 'system';
      if (mode == ThemeMode.light) {
        themeValue = 'light';
      } else if (mode == ThemeMode.dark) {
        themeValue = 'dark';
      }
      await prefs.setString(_themeKey, themeValue);
    } catch (e) {
      debugPrint("Error saving theme to SharedPreferences: $e");
    }
  }
}
