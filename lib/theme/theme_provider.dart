import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. The Hard Drive Link (Allows main.dart to pass the memory in)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialized in main.dart');
});

// 2. Define your 5 new themes
enum MitraTheme {
  midnightSlate,
  deepForest,
  twilightPurple,
  warmCharcoal,
  abyssalBlue,
}

// 3. ✨ NEW: The Smart Theme Notifier (Replaces StateProvider)
class ThemeNotifier extends StateNotifier<MitraTheme> {
  final SharedPreferences _prefs;
  static const _themeKey = 'mitra_custom_theme_saved';

  // When the app boots, instantly load the saved theme
  ThemeNotifier(this._prefs) : super(_loadSavedTheme(_prefs));

  static MitraTheme _loadSavedTheme(SharedPreferences prefs) {
    final savedThemeName = prefs.getString(_themeKey);
    if (savedThemeName != null) {
      // Find the saved theme from the enum list
      return MitraTheme.values.firstWhere(
        (theme) => theme.name == savedThemeName,
        orElse: () => MitraTheme.midnightSlate,
      );
    }
    return MitraTheme.midnightSlate; // Default if nothing is saved
  }

  // ✨ NEW: The method that updates the UI AND saves to the hard drive!
  void setTheme(MitraTheme theme) {
    state = theme;
    _prefs.setString(_themeKey, theme.name);
  }
}

// 4. ✨ NEW: The upgraded Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, MitraTheme>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

// 5. The Helper class (Untouched - your beautiful colors remain intact!)
class ThemeHelper {
  static List<Color> getBackgroundGradient(MitraTheme theme) {
    switch (theme) {
      case MitraTheme.midnightSlate:
        return [const Color(0xFF1E293B), const Color(0xFF0F172A)];
      case MitraTheme.deepForest:
        return [const Color(0xFF064E3B), const Color(0xFF022C22)];
      case MitraTheme.twilightPurple:
        return [const Color(0xFF312E81), const Color(0xFF1E1B4B)];
      case MitraTheme.warmCharcoal:
        return [const Color(0xFF292524), const Color(0xFF1C1917)];
      case MitraTheme.abyssalBlue:
        return [const Color(0xFF1E3A8A), const Color(0xFF172554)];
    }
  }

  static Color getActiveHighlight(MitraTheme theme) {
    switch (theme) {
      case MitraTheme.midnightSlate:
        return const Color(0xFF22D3EE);
      case MitraTheme.deepForest:
        return const Color(0xFF34D399);
      case MitraTheme.twilightPurple:
        return const Color(0xFFFBBF24);
      case MitraTheme.warmCharcoal:
        return const Color(0xFFFCD34D);
      case MitraTheme.abyssalBlue:
        return const Color(0xFFFB923C);
    }
  }

  static String getThemeName(MitraTheme theme) {
    switch (theme) {
      case MitraTheme.midnightSlate:
        return "Midnight Slate";
      case MitraTheme.deepForest:
        return "Deep Forest";
      case MitraTheme.twilightPurple:
        return "Twilight Purple";
      case MitraTheme.warmCharcoal:
        return "Warm Charcoal";
      case MitraTheme.abyssalBlue:
        return "Abyssal Blue";
    }
  }

  static ThemeData getThemeData(MitraTheme theme) {
    final highlight = getActiveHighlight(theme);
    final bgColors = getBackgroundGradient(theme);
    final baseColor = bgColors.last;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: baseColor,
      primaryColor: highlight,
      colorScheme: ColorScheme.dark(
        primary: highlight,
        surface: baseColor,
      ),
      fontFamily: 'Mukta',
    );
  }
}
