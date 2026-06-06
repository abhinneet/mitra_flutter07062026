// ═══════════════════════════════════════════════════════
// Student Shell — Bottom Tab Navigator
// Mirrors app/student/_layout.tsx from Expo project
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  static const _tabs = [
    _Tab(label: 'Home',    emoji: '🏠', route: '/student/home'),
    _Tab(label: 'Learn',   emoji: '📚', route: '/student/learn'),
    _Tab(label: 'AR',      emoji: '🥽', route: '/student/ar'),
    _Tab(label: 'Ranks',   emoji: '🏆', route: '/student/ranks'),
    _Tab(label: 'Profile', emoji: '👤', route: '/student/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return _tabs.indexWhere((t) => loc.startsWith(t.route)).clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: MitraColors.bgCard,
          border: Border(top: BorderSide(color: MitraColors.border)),
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
                    Text(_tabs[i].emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(
                      _tabs[i].label,
                      style: TextStyle(
                        fontFamily: 'Mukta', fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: focused ? MitraColors.saffron : MitraColors.textMuted,
                      ),
                    ),
                    if (focused)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(color: MitraColors.saffron, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            );
          }),
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
