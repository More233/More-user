import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../permissions/permissions_page.dart';
import '../timeline/timeline_screen.dart';

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
    "M48.8367 29.3994C40.7143 38.0839 36.8328 52.0402 35.6919 63.931C35.4125 66.8314 33.2739 69.143 30.8192 69.7617C27.8323 70.5134 24.749 69.4424 23.2523 66.6817C22.5804 65.4411 22.4673 63.5585 22.637 62.0884L24.902 42.3646C25.4342 37.718 25.1216 28.7143 22.3775 27.1011C19.6535 25.5013 14.3716 30.2276 12.6188 35.6159C11.571 38.8422 9.23278 41.2603 5.65389 40.9876C2.52736 40.7514 -0.506051 37.8477 0.0660388 34.2556C0.55165 31.1955 2.35107 28.5247 3.96091 25.9104C6.92446 21.1008 10.9291 17.0496 16.2242 15.0806C24.8887 11.8576 32.8481 16.8501 35.6819 25.8139L40.2254 20.3957C46.0561 13.4408 57.6109 8.93726 65.7167 14.9542C69.1492 17.4986 70.9619 21.2804 72.0928 25.4979L76.3702 20.7649C83.651 12.7057 96.3002 8.17891 103.205 16.5973C105.76 19.7105 106.811 23.5887 107.147 27.6C107.985 37.5684 103.88 53.211 106.984 55.9351C109.272 57.9474 113.423 55.2366 115.931 51.7509C120.152 45.8869 122.467 39.0651 123.022 31.8342C123.311 28.049 125.703 25.0655 129.744 24.8427C130.276 20.3524 132.631 16.5008 136.22 13.5173C144.126 6.9416 155.255 6.27971 164.173 11.5349C171.224 15.6892 175.771 22.6674 177.404 30.9095C184.834 28.7076 190.056 23.1497 189.657 15.1305C189.574 13.4541 189.225 11.7911 188.526 10.3409C186.87 6.89836 188.254 3.0933 191.553 1.59988C194.726 0.163003 198.671 1.49012 200.174 5.02244C203.091 6.09677 206.125 6.37616 209.275 6.67884L218.401 7.56358C221.754 7.88954 225.04 9.54926 227.086 12.3332C232.078 19.1218 227.096 28.5247 223.251 35.7656C220.826 40.3323 215.464 50.6233 217.676 53.3208C220.387 56.6269 231.52 52.0702 236.492 49.1598C230.296 33.0149 237.633 14.4819 251.539 4.84948C257.989 0.382525 265.652 -1.13085 273.132 0.874789C277.15 1.95245 280.583 4.06452 283.044 7.4771C286.969 12.9219 286.976 20.0564 284.059 26.1631C278.84 37.096 264.697 45.5876 254.27 52.925C262.798 57.7711 273.545 57.2023 281.717 51.7542C283.813 50.3572 285.815 48.3017 286.676 45.99C287.98 42.4877 291.226 40.3989 294.872 41.5963C298.188 42.6839 299.977 46.7451 298.441 50.161C293.764 60.565 283.829 66.3524 272.75 68.1785C262.259 69.908 250.724 67.2339 243.081 59.524C234.862 64.1938 225.429 68.0554 215.983 66.3292C211.753 65.5542 208.017 63.1294 206.314 59.2046C203.098 51.7941 206.055 43.1529 209.687 36.0051L215.471 24.6232C216.19 23.2096 216.535 21.8093 216.755 20.1695C215.524 19.7704 214.49 19.471 213.422 19.3879L201.498 18.4466C200.347 32.3497 190.602 40.2292 177.816 44.0044C176.998 52.0236 173.655 59.2812 167.299 64.43C155.119 74.2985 134.57 72.6887 126.498 57.7778C124.768 59.9929 123.185 62.1516 121.073 64.0075C116.573 67.9556 110.549 69.7517 104.742 68.4213C100.631 67.48 97.5408 65.032 95.7979 61.2003C94.0983 57.4684 93.443 53.2542 93.8455 49.0434L94.983 37.126C95.3655 33.108 95.5817 26.4525 93.6293 25.1686C91.2977 23.6353 86.3584 27.8794 83.671 31.0958C77.1152 38.942 72.4952 51.5014 71.6072 61.7391C71.361 64.5863 70.2734 66.7749 67.6624 68.0355C65.3608 69.1464 62.9959 69.0166 60.9005 67.6164C58.9248 66.2959 58.0034 63.931 58.3493 61.32L59.9691 49.09C60.9736 41.5098 62.8296 22.5177 55.1729 25.0356C52.7515 25.8305 50.6195 27.4869 48.83 29.3994H48.8367",
    "M273.242 19.6207C274.323 16.3644 272.457 13.6537 269.321 12.912C263.147 11.4518 256.991 15.1138 252.98 20.0298C247.771 26.406 245.303 34.4917 247.126 42.8801C255.132 37.0129 270.455 28.0291 273.242 19.624V19.6207",
    "M165.719 33.72C164.954 30.4505 163.707 27.5169 161.492 24.9624C157.184 19.9999 149.641 18.9056 144.273 22.6342C142.932 23.5655 141.984 25.1952 141.997 26.5124C142.067 33.893 157.986 34.8709 165.723 33.72H165.719",
    "M165.19 46.3692C153.712 46.9812 142.267 46.2162 134.457 38.4431C133.513 44.8958 135.794 52.4194 140.847 55.6923C145.427 58.6558 150.965 59.1481 156.39 56.8631C160.364 55.19 164.016 51.1588 165.19 46.3692"
  ];

  @override
  void initState() {
    super.initState();
    // Parse paths synchronously on init
    for (final pathString in _pathStrings) {
      _logoPaths.add(parseSvgPathData(pathString));
    }

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
              MaterialPageRoute(builder: (context) => const TimelineScreen()),
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
          MaterialPageRoute(builder: (context) => const PermissionsPage()),
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
                width: 250, // Increased size matching Figma premium view
                height: 60,
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
}

class SvgPathPainter extends CustomPainter {
  final List<Path> paths;
  final double progress;
  final Color color;

  SvgPathPainter({
    required this.paths,
    required this.progress,
    required this.color,
  });

  // Exact centerline points that follow the cursive handwriting path of "More"
  // scaled to the SVG viewBox 299x71
  static const List<Offset> _centerlinePoints = [
    // M
    Offset(12, 35), Offset(3, 33), Offset(16, 15), Offset(22.6, 62),
    Offset(48, 30), Offset(65.7, 14.9), Offset(35.7, 63.9),
    Offset(71.6, 61.7), Offset(103, 16.6), Offset(107, 56), Offset(123, 31.8),
    
    // o (circle loops counter-clockwise)
    Offset(140, 20), Offset(136, 30), Offset(145, 54), Offset(165, 54), Offset(170, 30), Offset(160, 16),
    Offset(140, 20), // close circle
    Offset(165, 12), Offset(185, 29), Offset(189, 15), // transition to r (with bottom loop)
    
    // r
    Offset(191.5, 2), Offset(200, 5), Offset(209, 7), Offset(217, 53), Offset(223, 35), Offset(236, 49),
    
    // e (loop counter-clockwise, through top-right first)
    Offset(283, 7.5), Offset(273, 1), Offset(251, 5), Offset(245, 30), Offset(254, 53), Offset(272, 60), Offset(281, 52), Offset(298, 50)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty) return;

    // Exact viewBox in SVG is 299x71
    final double scaleX = size.width / 299.0;
    final double scaleY = size.height / 71.0;
    final Matrix4 scaleMatrix = Matrix4.diagonal3Values(scaleX, scaleY, 1.0);

    // Save a layer to isolate blending
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Draw the actual filled logo paths first (destination)
    final combinedLogoPath = Path()..fillType = PathFillType.evenOdd;
    for (var originalPath in paths) {
      combinedLogoPath.addPath(originalPath.transform(scaleMatrix.storage), Offset.zero);
    }

    final logoPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(combinedLogoPath, logoPaint);

    // 2. Draw the animated centerline path as a thick mask stroke on top using BlendMode.dstIn (source)
    final centerlinePath = Path();
    if (_centerlinePoints.isNotEmpty) {
      centerlinePath.moveTo(_centerlinePoints[0].dx, _centerlinePoints[0].dy);
      for (int i = 1; i < _centerlinePoints.length; i++) {
        centerlinePath.lineTo(_centerlinePoints[i].dx, _centerlinePoints[i].dy);
      }
    }

    // Scale the centerline path
    final scaledCenterline = centerlinePath.transform(scaleMatrix.storage);

    // Calculate subpath based on progress
    final animatedPath = Path();
    final pathMetrics = scaledCenterline.computeMetrics().toList();
    double totalLength = 0.0;
    for (final metric in pathMetrics) {
      totalLength += metric.length;
    }

    final targetLength = totalLength * progress;
    double currentLength = 0.0;
    for (final metric in pathMetrics) {
      if (currentLength + metric.length <= targetLength) {
        animatedPath.addPath(metric.extractPath(0, metric.length), Offset.zero);
        currentLength += metric.length;
      } else {
        final remainingLength = targetLength - currentLength;
        animatedPath.addPath(metric.extractPath(0, remainingLength), Offset.zero);
        break;
      }
    }

    // Draw the mask stroke using BlendMode.dstIn
    final maskPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 38.0 * scaleX
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.dstIn; // Keep what was already drawn (the logo) where the stroke overlaps

    canvas.drawPath(animatedPath, maskPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SvgPathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
