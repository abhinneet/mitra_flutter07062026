import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import '../../constants/colors.dart';
import '../../widgets/mitra_scaffold.dart'; // ✨ Added
import 'package:flutter/services.dart';

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

    // ✨ FIX: Wrapped the MitraScaffold in a PopScope to intercept the back button
    return PopScope(
      canPop: false, // Prevents the default exit behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Trigger the dialog and wait for the user's choice
        final bool shouldExit = await _showExitDialog(context) ?? false;

        if (shouldExit) {
          SystemNavigator.pop(); // Kills the app if they clicked 'Yes'
        }
      },
      child: MitraScaffold(
        useSafeArea: false, // Let the child screens handle safe areas
        body: child,
        bottomNavigationBar: Container(
          height: 72 +
              MediaQuery.of(context).padding.bottom, // Account for iPhone notch
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3), // ✨ Glass bottom nav
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
                          fontFamily: 'Mukta', fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: focused
                              ? Colors.white
                              : Colors.white60, // ✨ Updated text colors
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

  // ✨ The Glass Exit Dialog (Added inside the StudentShell class)
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1232)
            .withValues(alpha: 0.95), // Matches your dark aesthetic
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.2)), // Glass border
        ),
        title: const Text(
          'Exit App?',
          style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to close the application?',
          style: TextStyle(
              fontFamily: 'Mukta', fontSize: 16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No',
                style: TextStyle(
                    fontFamily: 'Baloo2', fontSize: 16, color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                  0xFFFF3B55), // Crimson red for destructive actions
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes',
                style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }
} // <-- End of StudentShell class

class _Tab {
  final String label;
  final String emoji;
  final String route;
  const _Tab({required this.label, required this.emoji, required this.route});
}
