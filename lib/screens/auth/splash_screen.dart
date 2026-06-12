// ═══════════════════════════════════════════════════════
// SCREEN S-01: Splash — Pure Full-Screen Lottie
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../services/api_service.dart';
import '../../stores/auth_store.dart';
import '../../models/user.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

// 🚨 Added TickerProviderStateMixin to drive the custom Lottie controller
class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  final _storage = const FlutterSecureStorage();

  String? _nextRoute; // Holds the destination route once backend replies
  bool _animationDone =
      false; // Tracks if the animation reached its final frame

  @override
  void initState() {
    super.initState();
    // Initialize the controller that will manage the Lottie playback speeds
    _lottieController = AnimationController(vsync: this);

    // Kick off the background authentication verification instantly
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print("🚨 SPLASH: Background Auth Check Started...");

    try {
      final token = await _storage.read(key: 'mitra_access_token');
      print("🚨 SPLASH: Storage read successful. Token is: $token");

      if (token == null) {
        print("🚨 SPLASH: No token found. Checking onboarding status...");
        ref.read(authProvider.notifier).setLoading(false);

        // ✨ THE FIX: Check the phone's memory to see if they've been here before
        final prefs = await SharedPreferences.getInstance();
        final bool hasCompletedOnboarding =
            prefs.getBool('onboardingComplete') ?? false;

        if (hasCompletedOnboarding) {
          // They already did onboarding but aren't logged in. Send to Login.
          _nextRoute = '/login';
        } else {
          // Very first time opening the app. Send to Onboarding.
          _nextRoute = '/onboarding';
        }
      } else {
        print("🚨 SPLASH: Token found. Contacting backend...");
        final res = await AuthAPI.me();
        final data = res.data;
        final user = MitraUser.fromJson(data['user'] ?? data);

        ref.read(authProvider.notifier).setUser(user);
        print("🚨 SPLASH: User loaded successfully.");

        _nextRoute = user.isTeacher ? '/teacher/home' : '/student/home';
      }
    } catch (e) {
      print("🚨 SPLASH ERROR: Authentication check crashed: $e");
      ref.read(authProvider.notifier).setLoading(false);
      _nextRoute = '/login';
    }

    // Attempt to navigate if the animation beat the network request
    _attemptNavigation();
  }

  /// Evaluates if both conditions are met before switching screens
  void _attemptNavigation() {
    if (_animationDone && _nextRoute != null) {
      print(
          "🚨 SPLASH: Animation complete & route ready. Navigating to $_nextRoute");
      if (mounted) {
        context.go(_nextRoute!);
      }
    }
  }

  @override
  void dispose() {
    _lottieController
        .dispose(); // Always clean up controllers to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181335),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Lottie.asset(
          'assets/animations/splash_animation.json',
          controller: _lottieController,
          fit: BoxFit.cover,
          onLoaded: (composition) {
            // ✨ THE MAGIC FIX: Remove the native splash screen right NOW!
            // The Lottie file is loaded in memory, so there will be zero blank flash.
            FlutterNativeSplash.remove();

            // 1. Set the controller's duration to match the JSON file perfectly
            _lottieController.duration = composition.duration;

            // 2. Play the animation forward exactly once
            _lottieController.forward().then((_) {
              setState(() => _animationDone = true);
              // 3. Trigger navigation now that the final frame has been reached
              _attemptNavigation();
            });
          },
        ),
      ),
    );
  }
}
