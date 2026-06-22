// ═══════════════════════════════════════════════════════
// MITRA Flutter App — Entry Point
// Back button handled via WidgetsBindingObserver.didPopRoute
// This OS-level hook fires BEFORE any navigator/PopScope logic,
// the only reliable approach with ShellRoute + nested navigators.
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/background_dictionary_loader.dart';
import 'services/word_bank_service.dart';
import 'services/quotes_service.dart';

import 'theme/theme_provider.dart';
import 'constants/colors.dart';
import 'router.dart';
import 'services/api_service.dart';
import 'firebase_options.dart';

// ── Background FCM handler ─────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background FCM: ${message.messageId}');
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  debugPrint("🚦 Loading .env...");
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint("⚠️ .env issue: $e");
  }

  debugPrint("🔥 Initializing Firebase...");
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("⚠️ Firebase skipped: $e");
  }

  debugPrint("🌐 Initializing API...");
  try {
    ApiService.instance.init();
  } catch (e) {
    debugPrint("⚠️ API issue: $e");
  }

  debugPrint("💾 Loading local storage...");
  final prefs = await SharedPreferences.getInstance();

  debugPrint("🗄️ Initializing Hive...");
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint("⚠️ Hive initialization issue: $e");
  }

  debugPrint("📚 Initializing word bank...");
  await WordBankService().init();

  debugPrint("📜 Initializing quotes service...");
  await QuotesService.instance.init();

  debugPrint("📥 Starting silent dictionary download...");
  BackgroundDictionaryLoader().downloadInBackground().then((_) {
    WordBankService().reload();
  });

  debugPrint("✅ ALL SYSTEMS GO! Launching UI...");
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MitraApp(),
    ),
  );
}

class MitraApp extends ConsumerStatefulWidget {
  const MitraApp({super.key});

  @override
  ConsumerState<MitraApp> createState() => _MitraAppState();
}

class _MitraAppState extends ConsumerState<MitraApp>
    with WidgetsBindingObserver {
  bool _isShowingExitDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // Android Back Button Hook — fires at OS level BEFORE any
  // navigator/PopScope. Return true to consume the back press.
  // ═══════════════════════════════════════════════════════
  @override
  Future<bool> didPopRoute() async {
    final router = ref.read(routerProvider);
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    final ctx = rootNavigatorKey.currentContext;

    debugPrint('🔙 Back pressed at: $loc');

    if (ctx == null) return false;

    // ── Student section ─────────────────────────────
    if (loc.startsWith('/student/')) {
      if (loc == '/student/home') {
        if (_isShowingExitDialog) return true;
        _isShowingExitDialog = true;
        final shouldExit = await _showExitDialog(ctx);
        _isShowingExitDialog = false;
        if (shouldExit) {
          SystemNavigator.pop();
        }
        return true;
      } else {
        router.go('/student/home');
        return true;
      }
    }

    // ── Teacher section ─────────────────────────────
    if (loc.startsWith('/teacher/')) {
      if (loc == '/teacher/home') {
        if (_isShowingExitDialog) return true;
        _isShowingExitDialog = true;
        final shouldExit = await _showExitDialog(ctx);
        _isShowingExitDialog = false;
        if (shouldExit) {
          SystemNavigator.pop();
        }
        return true;
      } else {
        router.go('/teacher/home');
        return true;
      }
    }

    // ── Modals (Quiz, AR Viewer) — pop back to previous ─
    if (loc.startsWith('/quiz/') || loc.startsWith('/ar/')) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/student/home');
      }
      return true;
    }

    // For splash/login/onboarding, default behavior
    return false;
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1232).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
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
              backgroundColor: const Color(0xFFFF3B55),
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final activeTheme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'MITRA',
      debugShowCheckedModeBanner: false,
      color: MitraColors.saffron,
      theme: ThemeHelper.getThemeData(activeTheme),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('as'),
        Locale('bn'),
        Locale('brx'),
        Locale('doi'),
        Locale('gu'),
        Locale('hi'),
        Locale('kn'),
        Locale('ks'),
        Locale('kok'),
        Locale('mai'),
        Locale('ml'),
        Locale('mni'),
        Locale('mr'),
        Locale('ne'),
        Locale('or'),
        Locale('pa'),
        Locale('sa'),
        Locale('sat'),
        Locale('sd'),
        Locale('ta'),
        Locale('te'),
        Locale('ur'),
        Locale('en'),
      ],
    );
  }
}
