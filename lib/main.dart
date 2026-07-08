import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';

import 'services/quotes_service.dart';
import 'services/brain_spark_service.dart';
import 'theme/theme_provider.dart';
import 'constants/colors.dart';
import 'router.dart';
import 'services/api_service.dart';
import 'services/quiz_offline_service.dart';
import 'services/telemetry_batch_buffer.dart';
import 'back_button_dispatcher.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background FCM: ${message.messageId}');
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env: $e');
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase: $e');
  }

  try {
    ApiService.instance.init();
  } catch (e) {
    debugPrint('⚠️ API: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('⚠️ Hive: $e');
  }

  try {
    TelemetryBatchBuffer.instance.startScheduler();
  } catch (e) {
    debugPrint('⚠️ Telemetry: $e');
  }

  await QuotesService.instance.init();
  await BrainSparkService.instance.init();

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MitraApp(),
  ));
}

class MitraApp extends ConsumerStatefulWidget {
  const MitraApp({super.key});
  @override
  ConsumerState<MitraApp> createState() => _MitraAppState();
}

class _MitraAppState extends ConsumerState<MitraApp> {
  MitraBackButtonHandler? _backHandler;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register handler after router is available via ref
    if (_backHandler == null) {
      final router = ref.read(routerProvider);
      _backHandler = MitraBackButtonHandler(
        router: router,
        ref: ref,
        rootNavKey: rootNavigatorKey,
      );
      _backHandler!.register();
    }
  }

  @override
  void dispose() {
    _backHandler?.unregister();
    super.dispose();
  }

  void _setupFCM() {
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('🔔 FCM foreground: ${msg.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleDeepLink);
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _handleDeepLink(msg);
    });
  }

  void _handleDeepLink(RemoteMessage msg) {
    final type = msg.data['deep_link_type'] as String?;
    final id = msg.data['deep_link_id'] as String?;
    if (type == null || id == null || id.isEmpty) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    if (type == 'quiz') GoRouter.of(ctx).go('/quiz/$id');
    if (type == 'ar_topic') GoRouter.of(ctx).go('/ar/$id');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final activeTheme = ref.watch(themeProvider);
    ref.watch(quizSyncProvider);

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
