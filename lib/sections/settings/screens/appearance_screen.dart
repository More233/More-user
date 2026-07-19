import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final isAr = settings.preferredLanguage == 'ar';

    final bool isSystem = themeMode == ThemeMode.system;
    
    // Resolve active selection for the visual cards
    final bool isLightSelected = themeMode == ThemeMode.light || (isSystem && Theme.of(context).brightness == Brightness.light);
    final bool isDarkSelected = themeMode == ThemeMode.dark || (isSystem && Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Theme.of(context).iconTheme.color ?? Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isAr ? 'المظهر' : 'Appearance',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System toggle card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFF9F9F9)
                      : const Color(0xFF181C26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFFEDEDED)
                        : const Color(0xFF282D3D),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'استخدام إعدادات الجهاز' : 'Use device settings',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? 'يضبط مظهر التطبيق تلقائياً بناءً على إعدادات نظام جهازك.'
                                : 'Automatically adjusts to your device\'s Appearance settings.',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF7E8494)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    CupertinoSwitch(
                      value: isSystem,
                      activeTrackColor: const Color(0xFF7C57FC),
                      onChanged: (value) {
                        if (value) {
                          ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
                        } else {
                          // Default to current platform brightness if system toggle is disabled
                          final brightness = MediaQuery.of(context).platformBrightness;
                          ref.read(themeProvider.notifier).setThemeMode(
                                brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Light/Dark Theme Cards Grid
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSystem ? 0.5 : 1.0,
                  child: IgnorePointer(
                    ignoring: isSystem,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Light Mode Card
                        _buildThemeCard(
                          context: context,
                          title: isAr ? 'فاتح' : 'Light',
                          isSelected: isLightSelected,
                          isDarkTheme: false,
                          onTap: () {
                            ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
                          },
                        ),
                        
                        // Dark Mode Card
                        _buildThemeCard(
                          context: context,
                          title: isAr ? 'داكن' : 'Dark',
                          isSelected: isDarkSelected,
                          isDarkTheme: true,
                          onTap: () {
                            ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required bool isDarkTheme,
    required VoidCallback onTap,
  }) {
    final themeColor = const Color(0xFF7C57FC);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simulated App Screen Mockup
          Container(
            width: 110,
            height: 150,
            decoration: BoxDecoration(
              color: isDarkTheme ? const Color(0xFF0F1219) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? themeColor : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Simulated elements inside the card
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simulated app header
                      Container(
                        width: 45,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDarkTheme ? const Color(0xFF282D3D) : const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Simulated list item 1
                      Container(
                        width: 70,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDarkTheme ? const Color(0xFF1E2433) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Simulated list item 2
                      Container(
                        width: 55,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDarkTheme ? const Color(0xFF1E2433) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Simulated list item 3
                      Container(
                        width: 65,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDarkTheme ? const Color(0xFF1E2433) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Simulated Floating Action Button (FAB) at bottom-right
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          // Custom Selection Circle (Radio button)
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? themeColor : const Color(0xFFD1D5DB),
                width: isSelected ? 6.5 : 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
