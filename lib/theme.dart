import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Konsept 2 · Orman Sade renk paleti
class GL {
  static const ink = Color(0xFF17301F);
  static const forest = Color(0xFF1F4D36);
  static const forestMid = Color(0xFF2C6346);
  static const leaf = Color(0xFF5FAE7B);
  static const leafDark = Color(0xFF3F8B5C);
  static const leafLight = Color(0xFF78BE8F);
  static const mint = Color(0xFFCFE6D4);
  static const mintSoft = Color(0xFFE1EEE4);
  static const mintPale = Color(0xFFE9F4EC);
  static const bg = Color(0xFFF1F7F2);
  static const canvas = Color(0xFFDDEDE0);
  static const muted = Color(0xFF4A5F51);
  static const water = Color(0xFF2E8B6A);
  static const sun = Color(0xFFC47A1C);
  static const temp = Color(0xFF2E6FB0);
  static const warn = Color(0xFF8A4B12);
  static const warnDot = Color(0xFFE08A3C);
  static const line = Color(0xFFC5D9CB);
  static const pot = Color(0xFFF2F3EF);
  static const potShade = Color(0xFFE4E8E1);

  static const radius = 24.0;

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: ink.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -8,
    ),
  ];

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        primary: forest,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
          .apply(bodyColor: ink, displayColor: ink),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: forest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? forest : const Color(0xFF9DB3A3),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

/// Ekranlar arası yumuşak geçiş: hafif yukarı kayma + solma.
Route<T> glRoute<T>(Widget page, {bool fullscreen = false}) {
  return PageRouteBuilder<T>(
    fullscreenDialog: fullscreen,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
