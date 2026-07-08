// Student Shell — bottom tab navigation
// Back button handled via PopScope to prevent accidental app kills
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚨 REQUIRED FOR SystemNavigator.pop()
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart'; // 🚨 REQUIRED FOR DIALOG COLORS
import '../../widgets/mitra_scaffold_backup.dart';
import '../../widgets/language_alphabet_background.dart';
import '../../widgets/sync_status_banner.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  static const _tabs = [
    _Tab(label: 'Home', emoji: '🏠', route: '/student/home'),
    _Tab(label: 'Learn', emoji: '📚', route: '/student/learn'),
    _Tab(label: 'AR', emoji: '🥽', route: '/student/ar'),
    _Tab(label: 'Ranks', emoji: '🏆', route: '/student/ranks'),
    _Tab(label: 'Profile', emoji: '👤', route: '/student/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return _tabs
        .indexWhere((t) => loc.startsWith(t.route))
        .clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final loc = GoRouterState.of(context).uri.path;
    final isHome = loc == '/student/home';

    // ✨ THE FIX: PopScope intercepts the hardware back button
    return PopScope(
      canPop: false, // Prevents Android from instantly killing the app
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (!isHome) {
          // 1. If on any tab other than Home, navigate to Home
          context.go('/student/home');
        } else {
          // 2. If already on Home, show exit confirmation dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: MitraColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Text(
                'Exit App?',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              content: const Text(
                'Are you sure you want to close MITRA?',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      color: MitraColors.sky,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MitraColors.crimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );

          // 3. If user clicked Exit, close the app natively
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: MitraScaffold(
        useSafeArea: false,
        body: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(
              child: Stack(
                children: [
                  // Background animation - visible on ALL screens
                  const Positioned.fill(
                    child: LanguageAlphabetBackground(),
                  ),
                  // Screen content
                  child,
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final focused = i == idx;
              return GestureDetector(
                onTap: () => context.go(_tabs[i].route),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_tabs[i].emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text(
                        _tabs[i].label,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: focused ? Colors.white : Colors.white60,
                        ),
                      ),
                      if (focused)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final String emoji;
  final String route;
  const _Tab({required this.label, required this.emoji, required this.route});
}
