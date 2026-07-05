import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'widgets/feature_row.dart';
import 'widgets/custom_switch.dart';
import 'widgets/permission_step_layout.dart';
import '../auth/auth_flow_page.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthFlowPage()),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await ph.Permission.notification.request();
    } catch (e) {
      debugPrint("Error requesting notification permission: $e");
    }
    _nextPage();
  }

  Future<void> _requestContactsPermission() async {
    try {
      await ph.Permission.contacts.request();
    } catch (e) {
      debugPrint("Error requesting contacts permission: $e");
    }
    _nextPage();
  }

  Future<void> _requestLocationAlwaysPermission() async {
    try {
      // Prompt whenInUse first, then request always (iOS/Android best practice)
      final status = await ph.Permission.locationWhenInUse.request();
      if (status.isGranted) {
        await ph.Permission.locationAlways.request();
      }
    } catch (e) {
      debugPrint("Error requesting location always permission: $e");
    }
    _nextPage();
  }

  Future<void> _requestLocationWhenInUsePermission() async {
    try {
      await ph.Permission.locationWhenInUse.request();
    } catch (e) {
      debugPrint("Error requesting location whenInUse permission: $e");
    }
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Require button interactions
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              // Step 0: Notifications Permission
              PermissionStepLayout(
                imagePath: 'assets/Permissions Section/images/onborading_1.png',
                title: 'Turn on notifications',
                description:
                    'Get updates for bookings, orders, nearby places, and friends’ activity. You can manage this anytime.',
                featureRows: const [
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/notification_02.svg',
                    title: 'Booking reminders',
                    subtitle: 'Never miss a reservation or important update',
                  ),
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/package.svg',
                    title: 'Order status',
                    subtitle: 'Track your orders from confirmed to delivered',
                  ),
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/user_group.svg',
                    title: 'Nearby activity',
                    subtitle: 'See when friends check in around you',
                  ),
                ],
                primaryButtonText: 'Continue',
                onPrimaryPressed: _requestNotificationPermission,
                secondaryButtonText: 'Not now',
                onSecondaryPressed: _nextPage,
              ),

              // Step 1: Contact Permission
              PermissionStepLayout(
                imagePath: 'assets/Permissions Section/images/onborading_2.png',
                title: 'More is better with friends',
                description:
                    'Find friends already on More, share places, and discover trusted activity around you.',
                featureRows: const [
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/user_group.svg',
                    title: 'Find friends already on More',
                    subtitle: 'See which of your contacts use More.',
                  ),
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/sent_02.svg',
                    title: 'Share lists and check-ins',
                    subtitle: 'Send places, lists, and recommendations.',
                  ),
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/location.svg',
                    title: 'See nearby activity',
                    subtitle: 'Discover who checked in around you.',
                  ),
                ],
                primaryButtonText: 'Continue',
                onPrimaryPressed: _requestContactsPermission,
                secondaryButtonText: 'Skip for now',
                onSecondaryPressed: _nextPage,
              ),

              // Step 2: Privacy Permission
              _buildPrivacyStep(),

              // Step 3: Location Permission
              PermissionStepLayout(
                imagePath: 'assets/Permissions Section/images/onborading_4.png',
                title: 'Enable always-on location',
                description:
                    'Allow More to suggest check-ins, send arrival reminders, and improve your visit map.',
                featureRows: const [
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/location.svg',
                    title: 'Passive check-ins',
                    subtitle: 'We detect visits in the background.',
                  ),
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/notification_02.svg',
                    title: 'Smart reminders',
                    subtitle: 'Get alerts right when you arrive or need to leave.',
                  ),
                  FeatureRow(
                    iconPath: 'assets/Permissions Section/icons/artificial_intelligence_08.svg',
                    title: 'Better recommendations',
                    subtitle: 'We learn your patterns to suggest what\'s best.',
                  ),
                ],
                primaryButtonText: 'Continue',
                onPrimaryPressed: _requestLocationAlwaysPermission,
                secondaryButtonText: 'Only while using',
                onSecondaryPressed: _requestLocationWhenInUsePermission,
              ),
            ],
          ),


        ],
      ),
    );
  }

  // The Privacy step uses CustomSwitch and Arrow icons, requiring a separate layout definition
  Widget _buildPrivacyStep() {
    return Container(
      color: const Color(0xFFFCFCFC),
      child: SafeArea(
        child: Column(
          children: [
            // Top Illustration (smaller 320 height to fit 4 rows easily)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/Permissions Section/images/onborading_3.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Body Content
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading (No description block is present in step 2 design)
                    Text(
                      'Your privacy, your control',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Feature Rows List (4 items)
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const FeatureRow(
                            iconPath: 'assets/Permissions Section/icons/star.svg',
                            title: 'Personalized suggestions',
                            subtitle: 'Improve recommendations.',
                            trailing: CustomSwitch(initialValue: true),
                          ),
                          const SizedBox(height: 16),
                          const FeatureRow(
                            iconPath: 'assets/Permissions Section/icons/chart_01.svg',
                            title: 'Usage insights',
                            subtitle: 'Share anonymous usage data.',
                            trailing: CustomSwitch(initialValue: true),
                          ),
                          const SizedBox(height: 16),
                          const FeatureRow(
                            iconPath: 'assets/Permissions Section/icons/tag_01.svg',
                            title: 'Relevant offers',
                            subtitle: 'Get offers you may like.',
                            trailing: CustomSwitch(initialValue: true),
                          ),
                          const SizedBox(height: 16),
                          FeatureRow(
                            iconPath: 'assets/Permissions Section/icons/square_lock_01.svg',
                            title: 'Your data is secure and never sold.',
                            subtitle: 'Update your preferences anytime in Settings.',
                            backgroundColor: const Color(0xFFF7F6FC),
                            hasShadow: false,
                            trailing: RotatedBox(
                              quarterTurns: 3,
                              child: SvgPicture.asset(
                                'assets/Permissions Section/icons/arrow_right_01.svg',
                                width: 12,
                                height: 12,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF9CA3AF),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C57FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Continue',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        height: 24,
                        alignment: Alignment.center,
                        child: Text(
                          'Not now',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C57FC),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
