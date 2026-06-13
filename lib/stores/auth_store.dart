// ═══════════════════════════════════════════════════════
// MITRA Auth State — Riverpod Provider
// ═══════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

// ── Auth State class ───────────────────────────────────
class AuthState {
  final MitraUser? user;
  final bool isLoggedIn;
  final bool isLoading;

  const AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = true,
  });

  AuthState copyWith({
    MitraUser? user,
    bool? isLoggedIn,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth Notifier ──────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  // ✨ The listener starts the exact moment the app boots
  AuthNotifier() : super(const AuthState()) {
    _listenToFirebaseAuth();
  }

  void _listenToFirebaseAuth() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          // ✨ Fetch the real profile data from Firestore automatically
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();

          if (doc.exists) {
            final data = doc.data()!;

            final realUser = MitraUser(
              id: firebaseUser.uid,
              fullName: data['full_name'] ?? data['name'] ?? 'Student',
              phone: data['phone'] ?? '',
              role: data['role'] ?? 'student',
            ).copyWith(
              classGrade: data['class_grade'],
              assignedState: data['assigned_state'],
              avatarEmoji: data['avatar_emoji'] ?? '⚡',
              languagePreference: data['language_preference'] ?? 'en',
            );

            setUser(realUser);
          }
        } catch (e) {
          debugPrint("🚨 BACKGROUND FETCH ERROR: $e");
        }
      } else {
        // User logged out
        state = const AuthState(isLoggedIn: false, isLoading: false);
      }
    });
  }

  void setUser(MitraUser user) {
    state = state.copyWith(user: user, isLoggedIn: true, isLoading: false);
  }

  void updateUser(MitraUser updated) {
    state = state.copyWith(user: updated);
  }

  void addXP(int amount) {
    final current = state.user;
    if (current != null) {
      state = state.copyWith(
        user: current.copyWith(totalXp: (current.totalXp ?? 0) + amount),
      );
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = const AuthState(isLoggedIn: false, isLoading: false);
  }
}

// ── Provider ───────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// Convenience providers
final currentUserProvider = Provider<MitraUser?>((ref) {
  return ref.watch(authProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});
