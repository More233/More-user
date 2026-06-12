import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'steps/splash_step.dart';
import 'steps/login_step.dart';
import 'steps/otp_step.dart';
import 'steps/basic_info_step.dart';
import 'steps/birthday_step.dart';
import 'steps/interests_step.dart';
import 'steps/add_friends_step.dart';
import '../timeline/timeline_screen.dart';

enum AuthStep {
  splash,
  login,
  basicInfo,
  birthday,
  interests,
  addFriends,
}

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key});

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  final PageController _pageController = PageController();

  // Onboarding profile data state
  String? _firstName;
  String? _lastName;
  String? _username;
  String? _city;
  DateTime? _birthday;
  List<String> _interests = [];
  bool _isSavingProfile = false;

  void _navigateToStep(AuthStep step) {
    _pageController.animateToPage(
      step.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showOnboardingSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Onboarding Complete!',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Congratulations! You have completed the premium onboarding flow and registration process successfully.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const TimelineScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C57FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Restart',
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtpBottomSheet(BuildContext context, String address) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return OtpBottomSheet(
          targetAddress: address,
          onVerified: () {
            Navigator.pop(context); // Close sheet
            _navigateToStep(AuthStep.basicInfo);
          },
          onChangeNumber: () {
            Navigator.pop(context); // Close sheet (returns to login screen)
          },
        );
      },
    );
  }

  Future<void> _saveProfileAndComplete() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No authenticated user found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      _navigateToStep(AuthStep.login);
      return;
    }

    setState(() {
      _isSavingProfile = true;
    });

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'first_name': _firstName,
        'last_name': _lastName,
        'username': _username,
        'city': _city,
        'birthday': _birthday?.toIso8601String().split('T').first,
        'interests': _interests,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _showOnboardingSuccess();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Require programmatic steps
              children: [
                // Step 0: Splash
                SplashStep(
                  onGetStarted: () => _navigateToStep(AuthStep.login),
                  onLoginPressed: () => _navigateToStep(AuthStep.login),
                ),
                // Step 1: Login
                LoginStep(
                  onContinue: (address) {
                    _showOtpBottomSheet(context, address);
                  },
                  onSignUpPressed: () {
                    _navigateToStep(AuthStep.basicInfo);
                  },
                ),
                // Step 2: Sign Up Basic Info
                BasicInfoStep(
                  onBack: () => _navigateToStep(AuthStep.login),
                  onCompleted: (firstName, lastName, username, city) {
                    setState(() {
                      _firstName = firstName;
                      _lastName = lastName;
                      _username = username;
                      _city = city;
                    });
                    _navigateToStep(AuthStep.birthday);
                  },
                ),
                // Step 3: Birthday Step
                BirthdayStep(
                  onBack: () => _navigateToStep(AuthStep.basicInfo),
                  onCompleted: (birthday) {
                    setState(() {
                      _birthday = birthday;
                    });
                    _navigateToStep(AuthStep.interests);
                  },
                ),
                // Step 4: Interests Selection
                InterestsStep(
                  onCompleted: (interests) {
                    setState(() {
                      _interests = interests;
                    });
                    _navigateToStep(AuthStep.addFriends);
                  },
                  onSkip: (interests) {
                    setState(() {
                      _interests = interests;
                    });
                    _navigateToStep(AuthStep.addFriends);
                  },
                ),
                // Step 5: Add Friends
                AddFriendsStep(
                  onDone: _saveProfileAndComplete,
                ),
              ],
            ),
            if (_isSavingProfile)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7C57FC),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
