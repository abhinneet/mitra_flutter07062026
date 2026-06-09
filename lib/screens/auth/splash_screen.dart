// ═══════════════════════════════════════════════════════
// SCREEN S-01: Splash — Pure Full-Screen Lottie
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../services/api_service.dart';
import '../../stores/auth_store.dart';
import '../../models/user.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print("🚨 SPLASH: Timer Started");

    // ⏱️ Reduced to 3 seconds for debugging
    await Future.delayed(const Duration(seconds: 3));

    print("🚨 SPLASH: Timer Finished. Checking secure storage...");

    if (!mounted) return;

    try {
      // 🐛 NOTE: If the app freezes, it is almost always on this exact line!
      final token = await _storage.read(key: 'mitra_access_token');

      print("🚨 SPLASH: Storage read successful. Token is: $token");

      if (token == null) {
        print("🚨 SPLASH: No token found. Navigating to Onboarding...");
        ref.read(authProvider.notifier).setLoading(false);

        // 🚨 BUG FIX: Give the engine a split-second to stabilize before pushing the route
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) context.go('/onboarding');
        });
        return;
      }

      print("🚨 SPLASH: Token found. Contacting backend...");
      final res = await AuthAPI.me();
      final data = res.data;
      final user = MitraUser.fromJson(data['user'] ?? data);

      ref.read(authProvider.notifier).setUser(user);

      print("🚨 SPLASH: User loaded. Navigating to Home...");
      if (!mounted) return;
      if (user.isTeacher) {
        context.go('/teacher/home');
      } else {
        context.go('/student/home');
      }
    } catch (e) {
      print("🚨 SPLASH ERROR: Something crashed! Error details: $e");
      ref.read(authProvider.notifier).setLoading(false);
      if (mounted) context.go('/login');
    }
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
          fit: BoxFit.cover,
          repeat:
              false, // 🚨 Tells the animation to play ONCE and hold on the final frame!
        ),
      ),
    );
  }
}
