import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_flow_page.dart';
import '../home/home_screen.dart';
import '../explore/services/explore_data_service.dart';
import 'widgets/svg_path_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Path> _logoPaths = [];

  // Exact path strings parsed from assets/Splash/logo.svg
  static const List<String> _pathStrings = [
    "M166.614 34.5781C142.698 34.5781 123.215 54.0605 123.215 77.9771V97.6009C123.215 107.649 115.054 115.81 105.007 115.81C94.9587 115.81 86.7978 107.649 86.7978 97.6009V77.9771C86.7978 54.0605 67.3627 34.5781 43.3989 34.5781C19.4352 34.5781 0 54.0605 0 77.9771V128.405C0 135.339 5.61353 141 12.5951 141C19.5767 141 25.1902 135.386 25.1902 128.405V77.9771C25.1902 67.9293 33.3511 59.7684 43.3989 59.7684C53.4467 59.7684 61.6076 67.9293 61.6076 77.9771V97.6009C61.6076 121.517 81.0899 141 105.007 141C128.923 141 148.405 121.517 148.405 97.6009V77.9771C148.405 67.9293 156.566 59.7684 166.614 59.7684C176.662 59.7684 184.823 67.9293 184.823 77.9771V128.405C184.823 135.339 190.436 141 197.418 141C204.399 141 210.013 135.386 210.013 128.405V77.9771C210.013 54.0605 190.531 34.5781 166.614 34.5781Z",
    "M126.943 34.5776C124.914 34.5776 122.839 33.87 121.187 32.4077L105.007 18.303L88.827 32.4077C85.1947 35.5682 79.6283 35.1909 76.4677 31.5586C73.3072 27.9263 73.6845 22.3599 77.3168 19.1993L95.1481 3.67947C100.762 -1.22649 109.253 -1.22649 114.866 3.67947L132.698 19.1993C136.33 22.3599 136.754 27.9263 133.547 31.5586C131.801 33.5398 129.396 34.5776 126.943 34.5776Z"
  ];

  @override
  void initState() {
    super.initState();
    // Parse paths synchronously on init
    for (final pathString in _pathStrings) {
      _logoPaths.add(parseSvgPathData(pathString));
    }

    // Run one-time startup background API places fetcher to seed SQLite cache
    ExploreDataService.seedRealGlobalPlacesFromApi();

    // Pre-cache common SVG icons asynchronously on launch
    _precacheSvgs();

    // Creative drawing path animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.forward().then((_) async {
      // Pause briefly for high premium feel, then navigate to Permissions page
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          final userId = session.user.id;
          final profile = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (!mounted) return;
          if (profile != null && profile['username'] != null) {
            // Logged in with completed profile
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            return;
          } else {
            // Logged in but profile incomplete -> sign out so they see the login screen
            await Supabase.instance.client.auth.signOut();
          }
        } catch (_) {
          // Fallback to default
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthFlowPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C57FC), // Figma matching background color
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double scale = 0.94 + (0.06 * _controller.value);
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 135,
                height: 90,
                child: CustomPaint(
                  painter: SvgPathPainter(
                    paths: _logoPaths,
                    progress: _controller.value,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _precacheSvgs() async {
    final assets = [
      'assets/home/icons/home.svg',
      'assets/home/icons/search_01.svg',
      'assets/home/icons/like_icon.svg',
      'assets/home/icons/comment_icon.svg',
      'assets/home/icons/share_icon_1.svg',
      'assets/home/icons/bookmark_icon.svg',
      'assets/home/icons/post_options.svg',
      'assets/explore/sent.svg',
      'assets/explore/earth.svg',
    ];
    for (final asset in assets) {
      try {
        final loader = SvgAssetLoader(asset);
        await loader.loadBytes(null);
      } catch (e) {
        debugPrint("Error precaching SVG $asset: $e");
      }
    }
  }
}


