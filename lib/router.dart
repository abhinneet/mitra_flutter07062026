// ═══════════════════════════════════════════════════════
// MITRA App Router — GoRouter
// Mirrors expo-router file-based routing from Expo project
// Routes: splash → onboarding → login → setup →
//         student/* or teacher/*
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/setup_screen.dart';
import '../screens/student/student_shell.dart';
import '../screens/student/home_screen.dart';
import '../screens/student/learn_screen.dart';
import '../screens/student/ar_tab_screen.dart';
import '../screens/student/ranks_screen.dart';
import '../screens/student/student_profile_screen.dart';
import '../screens/teacher/teacher_shell.dart';
import '../screens/teacher/teacher_home_screen.dart';
import '../screens/teacher/students_screen.dart';
import '../screens/teacher/analytics_screen.dart';
import '../screens/teacher/assign_screen.dart';
import '../screens/teacher/teacher_profile_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/quiz/quiz_result_screen.dart';
import '../screens/ar/ar_viewer_screen.dart';
import '../stores/auth_store.dart';

// ── Shell navigator keys ───────────────────────────────
final _rootKey = GlobalKey<NavigatorState>();
final _studentKey = GlobalKey<NavigatorState>();
final _teacherKey = GlobalKey<NavigatorState>();

// ── Router provider ────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  // 🚨 BUG FIX: Removed ref.watch(). We create the router ONCE and never delete it.

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      // 🚨 Read the auth state dynamically "on the fly" instead!
      final authState = ref.read(authProvider);

      final loggedIn = authState.isLoggedIn;
      final user = authState.user;
      final path = state.uri.path;

      // Allow the Splash Screen to play
      if (path == '/') {
        return null;
      }

      // If not logged in, strictly lock them to onboarding/login
      if (!loggedIn && path != '/onboarding' && path != '/login') {
        return '/onboarding';
      }

      // If logged in but no class set (student first time), force setup
      if (loggedIn &&
          user?.isStudent == true &&
          user?.classGrade == null &&
          path != '/setup') {
        return '/setup';
      }

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ──────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Login ───────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Setup ───────────────────────────────────────
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),

      // ── Student shell (bottom tabs) ──────────────────
      ShellRoute(
        navigatorKey: _studentKey,
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(path: '/student/home', builder: (c, s) => const HomeScreen()),
          GoRoute(
              path: '/student/learn', builder: (c, s) => const LearnScreen()),
          GoRoute(path: '/student/ar', builder: (c, s) => const ArTabScreen()),
          GoRoute(
              path: '/student/ranks', builder: (c, s) => const RanksScreen()),
          GoRoute(
              path: '/student/profile',
              builder: (c, s) => const StudentProfileScreen()),
        ],
      ),

      // ── Teacher shell (bottom tabs) ──────────────────
      ShellRoute(
        navigatorKey: _teacherKey,
        builder: (context, state, child) => TeacherShell(child: child),
        routes: [
          GoRoute(
              path: '/teacher/home',
              builder: (c, s) => const TeacherHomeScreen()),
          GoRoute(
              path: '/teacher/students',
              builder: (c, s) => const StudentsScreen()),
          GoRoute(
              path: '/teacher/analytics',
              builder: (c, s) => const AnalyticsScreen()),
          GoRoute(
              path: '/teacher/assign', builder: (c, s) => const AssignScreen()),
          GoRoute(
              path: '/teacher/profile',
              builder: (c, s) => const TeacherProfileScreen()),
        ],
      ),

      // ── Quiz (full screen modal) ─────────────────────
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) => QuizScreen(
          quizId: state.pathParameters['quizId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/quiz/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QuizResultScreen(
            score: extra['score'] as int? ?? 0,
            total: extra['total'] as int? ?? 0,
            xpEarned: extra['xpEarned'] as int? ?? 0,
          );
        },
      ),

      // ── AR Viewer (full screen modal) ────────────────
      GoRoute(
        path: '/ar/:topicId',
        builder: (context, state) => ArViewerScreen(
          topicId: state.pathParameters['topicId'] ?? '',
        ),
      ),
    ],
  );
});
