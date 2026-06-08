// ═══════════════════════════════════════════════════════
// SCREEN S-01: Splash — Auth check + animated intro
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart'; // 🚨 NEW LOTTIE IMPORT

import '../../constants/colors.dart';
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
    // Start the authentication check the second the screen loads
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // ⏳ Allow the Lottie animation to play for at least 2.5 seconds
    // before whisking the user away to the next screen.
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    try {
      final token = await _storage.read(key: 'mitra_access_token');
      if (token == null) {
        ref.read(authProvider.notifier).setLoading(false);
        if (mounted) context.go('/onboarding');
        return;
      }
      final res = await AuthAPI.me();
      final data = res.data;
      final user = MitraUser.fromJson(data['user'] ?? data);

      ref.read(authProvider.notifier).setUser(user);

      if (!mounted) return;
      if (user.isTeacher) {
        context.go('/teacher/home');
      } else {
        context.go('/student/home');
      }
    } catch (_) {
      ref.read(authProvider.notifier).setLoading(false);
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: MitraColors.gradientHero,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric background rings (Kept from your original design!)
            for (final size in [200.0, 280.0, 360.0])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: MitraColors.saffron.withOpacity(0.12)),
                ),
              ),

            // Main Content Column
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🚨 YOUR NEW LOTTIE ANIMATION
                Lottie.asset(
                  'assets/animations/splash_animation.json',
                  width: 200, // Adjust this if it looks too big or small
                  height: 200,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                // App name (MITRA)
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: MitraColors.textPrimary,
                        letterSpacing: -0.5),
                    children: [
                      TextSpan(text: 'MI'),
                      TextSpan(
                          text: 'TRA',
                          style: TextStyle(color: MitraColors.saffron)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Tagline
                const Text(
                  'AR LEARNING PLATFORM',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 14,
                    color: MitraColors.textMuted,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            // Bottom Govt Tag (Replaced the bouncing dots)
            const Positioned(
              bottom: 40,
              child: Text(
                'Ministry of Education, Govt. of India',
                style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: 12,
                    color: MitraColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
