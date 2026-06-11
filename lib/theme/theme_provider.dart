import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Define your 5 new themes
enum MitraTheme {
  midnightSlate,
  deepForest,
  twilightPurple,
  warmCharcoal,
  abyssalBlue,
}

// 2. The Riverpod state (defaults to Midnight Slate)
final themeProvider =
    StateProvider<MitraTheme>((ref) => MitraTheme.midnightSlate);

// 3. The Helper class to fetch colors anywhere in the app
class ThemeHelper {
  static List<Color> getBackgroundGradient(MitraTheme theme) {
    switch (theme) {
      case MitraTheme.midnightSlate:
        return [
          const Color(0xFF1E293B),
          const Color(0xFF0F172A)
        ]; // Slate & Indigo
      case MitraTheme.deepForest:
        return [const Color(0xFF064E3B), const Color(0xFF022C22)]; // Dark Pine
      case MitraTheme.twilightPurple:
        return [
          const Color(0xFF312E81),
          const Color(0xFF1E1B4B)
        ]; // Muted Purple
      case MitraTheme.warmCharcoal:
        return [
          const Color(0xFF292524),
          const Color(0xFF1C1917)
        ]; // Warm Gray/Amber
      case MitraTheme.abyssalBlue:
        return [const Color(0xFF1E3A8A), const Color(0xFF172554)]; // Deep Navy
    }
  }

  static Color getActiveHighlight(MitraTheme theme) {
    switch (theme) {
      case MitraTheme.midnightSlate:
        return const Color(0xFF22D3EE); // Cyan
      case MitraTheme.deepForest:
        return const Color(0xFF34D399); // Mint
      case MitraTheme.twilightPurple:
        return const Color(0xFFFBBF24); // Saffron
      case MitraTheme.warmCharcoal:
        return const Color(0xFFFCD34D); // Soft Gold
      case MitraTheme.abyssalBlue:
        return const Color(0xFFFB923C); // Vibrant Coral
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
}
