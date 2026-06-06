// ═══════════════════════════════════════════════════════
// SCREEN S-01: Splash — Auth check + animated intro
// Mirrors app/index.tsx from Expo project
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../stores/auth_store.dart';
import '../../models/user.dart';
import '../../widgets/gradient_button.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _dotsCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    // Logo entrance animation
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale   = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.8)),
    );

    // Bouncing dots
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _logoCtrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    try {
      final token = await _storage.read(key: 'mitra_access_token');
      if (token == null) {
        context.go('/onboarding');
        return;
      }
      final res  = await AuthAPI.me();
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
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dotColors = [MitraColors.saffron, MitraColors.gold, MitraColors.emerald];

    return Scaffold(
      body: Container(
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
            // Concentric rings
            for (final size in [200.0, 280.0, 360.0])
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MitraColors.saffron.withOpacity(0.12)),
                ),
              ),

            // Logo block
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (ctx, _) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon box
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: MitraColors.gradientSaffron),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: MitraColors.saffron.withOpacity(0.4),
                            blurRadius: 30, offset: const Offset(0, 16),
                          )],
                        ),
                        child: const Center(child: Text('🎓', style: TextStyle(fontSize: 40))),
                      ),
                      const SizedBox(height: 14),
                      // App name
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontFamily: 'Baloo2', fontSize: 32, fontWeight: FontWeight.w800, color: MitraColors.textPrimary, letterSpacing: -0.5),
                          children: [
                            TextSpan(text: 'MI'),
                            TextSpan(text: 'TRA', style: TextStyle(color: MitraColors.saffron)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AR LEARNING PLATFORM',
                        style: TextStyle(
                          fontFamily: 'Mukta', fontSize: 13,
                          color: MitraColors.textMuted, letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom loader
            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  // Animated dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final anim = Tween<double>(begin: 0, end: -8).animate(
                        CurvedAnimation(
                          parent: _dotsCtrl,
                          curve: Interval(i * 0.15, i * 0.15 + 0.7, curve: Curves.easeInOut),
                        ),
                      );
                      return AnimatedBuilder(
                        animation: _dotsCtrl,
                        builder: (ctx, _) => Transform.translate(
                          offset: Offset(0, anim.value),
                          child: Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: dotColors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ministry of Education, Govt. of India',
                    style: TextStyle(fontFamily: 'Mukta', fontSize: 10, color: MitraColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
