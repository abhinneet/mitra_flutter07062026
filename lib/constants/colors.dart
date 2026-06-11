// ═══════════════════════════════════════════════════════
// MITRA Brand Colors & Design System — Flutter Port
// Mirrors constants/Colors.ts from Expo project
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class MitraColors {
  // Private constructor — use static members only
  MitraColors._();

  // ── Primary brand ──────────────────────────────────
  static const Color saffron = Color(0xFFFF6B35);
  static const Color saffronLight = Color(0xFFFF8C5A);
  static const Color saffronDark = Color(0xFFE85520);

  // ── Secondary ──────────────────────────────────────
  static const Color indigo = Color(0xFF2D1B69);
  static const Color indigoMid = Color(0xFF4A2F9C);
  static const Color indigoLight = Color(0xFF7C5CDD);

  // ── Accents ────────────────────────────────────────
  static const Color emerald = Color(0xFF00C389);
  static const Color emeraldDark = Color(0xFF009E6D);
  static const Color gold = Color(0xFFFFB800);
  static const Color goldDark = Color(0xFFE5A600);
  static const Color crimson = Color(0xFFFF3B55);
  static const Color sky = Color(0xFF0EA5E9);

  // ── Backgrounds (dark theme) ───────────────────────
  static const Color bgDeep = Color(0xFF0A0612);
  static const Color bgCard = Color(0xFF120C24);
  static const Color bgSurface = Color(0xFF1C1232);

  // ── Borders ────────────────────────────────────────
  static const Color border = Color(0x337C5CDD); // rgba(124,92,221,0.2)
  static const Color borderLight = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // ── Text ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F0FF);
  static const Color textSecondary = Color(0xA6F5F0FF); // 65%
  static const Color textMuted = Color(0x59F5F0FF); // 35%

  // ── Gradient pairs ─────────────────────────────────
  static const List<Color> gradientSaffron = [saffron, gold];
  static const List<Color> gradientIndigo = [indigo, indigoLight];
  static const List<Color> gradientEmerald = [emerald, sky];
  static const List<Color> gradientHero = [
    Color(0xFF1a0a3e),
    Color(0xFF2D1B69),
    Color(0xFF0f2a1a)
  ];
  static const List<Color> gradientTeacher = [
    Color(0xFF0a1f0a),
    Color(0xFF0f2d1f)
  ];
}

// ── Spacing Scale ──────────────────────────────────────
class MitraSpacing {
  MitraSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 40;
}

// ── Border Radius ──────────────────────────────────────
class MitraRadius {
  MitraRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double pill = 999;
}

// ── Font Families ──────────────────────────────────────
class MitraFonts {
  MitraFonts._();
  static const String displayBold = 'Baloo2';
  static const String body = 'Mukta';
  static const String mono = 'SpaceMono';
}

// ── Global Theme ───────────────────────────────────────
ThemeData mitraTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: MitraColors.saffron,
      secondary: MitraColors.emerald,
      surface: MitraColors.bgCard,
      onPrimary: Colors.white,
      onSurface: MitraColors.textPrimary,
    ),
    fontFamily: MitraFonts.body,
    appBarTheme: const AppBarTheme(
      backgroundColor: MitraColors.bgCard,
      foregroundColor: MitraColors.textPrimary,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MitraColors.bgCard,
      selectedItemColor: MitraColors.saffron,
      unselectedItemColor: MitraColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: MitraFonts.displayBold,
        fontWeight: FontWeight.w800,
        color: MitraColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: MitraFonts.body,
        color: MitraColors.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MitraColors.bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MitraRadius.sm),
        borderSide: const BorderSide(color: MitraColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MitraRadius.sm),
        borderSide: const BorderSide(color: MitraColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MitraRadius.sm),
        borderSide: const BorderSide(color: MitraColors.saffron, width: 1.5),
      ),
      labelStyle: const TextStyle(color: MitraColors.textMuted),
      hintStyle: const TextStyle(color: MitraColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MitraColors.saffron,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MitraRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: MitraFonts.displayBold,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
  );
}
