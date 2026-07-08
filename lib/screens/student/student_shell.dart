import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✨ Riverpod
import 'package:go_router/go_router.dart';
import '../../widgets/mitra_scaffold.dart';
import '../../widgets/language_alphabet_background.dart';
import '../../widgets/sync_status_banner.dart';
import '../../providers/translation_provider.dart'; // ✨ Translation Engine

class StudentShell extends ConsumerWidget {
  // ✨ Upgraded to ConsumerWidget
  final Widget child;
  const StudentShell({super.key, required this.child});

  static const _tabs = [
    _Tab(label: 'Home', emoji: '匠', route: '/student/home'),
    _Tab(label: 'Learn', emoji: '答', route: '/student/learn'),
    // ✨ AR tab removed!
    _Tab(label: 'Ranks', emoji: '醇', route: '/student/ranks'),
    _Tab(label: 'Profile', emoji: '側', route: '/student/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    return _tabs
        .indexWhere((t) => loc.startsWith(t.route))
        .clamp(0, _tabs.length - 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✨ Added WidgetRef
    final idx = _currentIndex(context);

    // ✨ Listen to the translation state so the bottom bar rebuilds on language change
    ref.watch(translationProvider);
    final t = ref.read(translationProvider.notifier);

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
        height: 85 +
            MediaQuery.of(context)
                .padding
                .bottom, // ✨ Height increased to fit larger text
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
                width: 80, // ✨ Width increased to prevent text wrapping
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_tabs[i].emoji, style: const TextStyle(fontSize: 33)),
                    const SizedBox(height: 4),
                    // ✨ Apply the translator here! The warning will instantly disappear.
                    Text(
                        t.tr('tab_${_tabs[i].label.toLowerCase()}',
                            _tabs[i].label),
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
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
