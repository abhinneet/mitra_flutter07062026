import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. The Gateway to the phone's hard drive
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// 2. The Notifier that remembers your theme choice
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'mitra_saved_theme';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'dark') return ThemeMode.dark;
    if (savedTheme == 'light') return ThemeMode.light;

    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
  }
}

// 3. The Provider you will watch in your UI
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
