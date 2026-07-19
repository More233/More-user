import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'steps/splash_step.dart';
import 'steps/login_step.dart';
import 'steps/otp_step.dart';
import 'steps/basic_info_step.dart';
import 'steps/birthday_step.dart';
import 'steps/interests_step.dart';
import 'steps/add_friends_step.dart';
import '../home/home_screen.dart';

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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
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
            // User already has a completed profile -> go directly to TimelineScreen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            return;
          }
        } catch (_) {
          // Fallback to onboarding flow if query fails
        }

        // Pre-populate fields from Google meta data if available
        final user = session.user;
        final metadata = user.userMetadata;
        if (metadata != null && mounted) {
          setState(() {
            final fullName = metadata['full_name'] as String? ?? metadata['name'] as String? ?? '';
            if (fullName.isNotEmpty && (_firstName == null || _firstName!.isEmpty)) {
              final parts = fullName.split(' ');
              _firstName = parts.first;
              if (parts.length > 1) {
                _lastName = parts.sublist(1).join(' ');
              }
            }
            final email = user.email;
            if (email != null && (_username == null || _username!.isEmpty)) {
              _username = email.split('@').first;
            }
            _googleAvatarUrl = metadata['avatar_url'] as String? ?? metadata['picture'] as String?;
          });
        }

        if (_pageController.hasClients) {
          final currentPage = _pageController.page?.round() ?? 0;
          if (currentPage <= AuthStep.login.index) {
            _navigateToStep(AuthStep.basicInfo);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Onboarding profile data state
  String? _firstName;
  String? _lastName;
  String? _username;
  String? _city;
  DateTime? _birthday;
  List<String> _interests = [];
  bool _isSavingProfile = false;
  String? _googleAvatarUrl;

  void _navigateToStep(AuthStep step) {
    _pageController.animateToPage(
      step.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
        'avatar_url': _googleAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1219) : Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
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
                    initialFirstName: _firstName,
                    initialLastName: _lastName,
                    initialUsername: _username,
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
                  child: Center(
                    child: CupertinoActivityIndicator(
                      color: Color(0xFF7C57FC),
                      radius: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
