// ═══════════════════════════════════════════════════════
// MITRA Auth State — Riverpod Provider
// Mirrors store/useAuthStore.ts (Zustand) from Expo project
// ═══════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

const _storage = FlutterSecureStorage();

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
      user:       user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading:  isLoading ?? this.isLoading,
    );
  }
}

// ── Auth Notifier ──────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Set user after successful login/me check
  void setUser(MitraUser user) {
    state = state.copyWith(user: user, isLoggedIn: true, isLoading: false);
  }

  /// Partial update (e.g. after profile setup)
  void updateUser(MitraUser updated) {
    state = state.copyWith(user: updated);
  }

  /// Add XP (mirrors addXP action)
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

  /// Clear tokens + reset state on logout
  Future<void> logout() async {
    await _storage.delete(key: 'mitra_access_token');
    await _storage.delete(key: 'mitra_refresh_token');
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
