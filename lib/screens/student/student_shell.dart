import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    return MitraScaffold(
      useSafeArea: false,
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: LanguageAlphabetBackground()),
                child,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 72 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
                    Text(_tabs[i].emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 2),
                    Text(_tabs[i].label,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: focused ? Colors.white : Colors.white60,
                        )),
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
    );
  }
}

class _Tab {
  final String label, emoji, route;
  const _Tab({required this.label, required this.emoji, required this.route});
}
