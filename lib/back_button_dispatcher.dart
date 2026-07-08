// ═══════════════════════════════════════════════════════
// MitraBackButtonHandler
//
// Registered as a WidgetsBindingObserver in main.dart.
// Works reliably because AndroidManifest does NOT set
// enableOnBackInvokedCallback=true — so Android still
// sends back presses as key events that Flutter's
// WidgetsBindingObserver.didPopRoute() intercepts.
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/exit_app_dialog.dart';

class MitraBackButtonHandler with WidgetsBindingObserver {
  final GoRouter router;
  final WidgetRef ref;
  final GlobalKey<NavigatorState> rootNavKey;

  bool _isShowingExitDialog = false;

  MitraBackButtonHandler({
    required this.router,
    required this.ref,
    required this.rootNavKey,
  });

  void register() => WidgetsBinding.instance.addObserver(this);
  void unregister() => WidgetsBinding.instance.removeObserver(this);

  @override
  Future<bool> didPopRoute() async {
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    final ctx = rootNavKey.currentContext;
    debugPrint('🔙 Back: $loc');
    if (ctx == null) return false;

    // ── Student tabs ──────────────────────────────────
    if (loc.startsWith('/student/')) {
      if (loc == '/student/home') return _promptExit(ctx);
      router.go('/student/home');
      return true;
    }

    // ── Teacher tabs ──────────────────────────────────
    if (loc.startsWith('/teacher/')) {
      if (loc == '/teacher/home') return _promptExit(ctx);
      router.go('/teacher/home');
      return true;
    }

    // ── Quiz result → student home ────────────────────
    if (loc == '/quiz/result') {
      router.go('/student/home');
      return true;
    }

    // ── Quiz screen → learn tab ───────────────────────
    if (loc.startsWith('/quiz/')) {
      router.go('/student/learn');
      return true;
    }

    // ── AR viewer → AR tab ────────────────────────────
    if (loc.startsWith('/ar/')) {
      router.go('/student/ar');
      return true;
    }

    // ── Auth flow: pop if history exists, else exit ───
    if (router.canPop()) {
      router.pop();
      return true;
    }
    return _promptExit(ctx);
  }

  Future<bool> _promptExit(BuildContext ctx) async {
    if (_isShowingExitDialog) return true;
    _isShowingExitDialog = true;
    try {
      final shouldExit = await showExitAppDialog(ctx, ref);
      if (shouldExit) SystemNavigator.pop();
    } finally {
      _isShowingExitDialog = false;
    }
    return true;
  }
}
