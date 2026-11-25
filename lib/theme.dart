import 'package:flutter/material.dart';

/// Buzlu Cam (3. referans) renkleri ve tipografisi.
class GL {
  static const ink = Color(0xFF1C2B22); // ana yazı
  static const muted = Color(0xFF3B5144); // ikincil yazı (cam üstünde 4.5:1+)
  static const green = Color(0xFF43805A); // ana düğme
  static const greenDark = Color(0xFF2F6A45); // vurgu yazı
  static const mint = Color(0xFFDCE9DE); // zemin
  static const warn = Color(0xFF8A4B12);
  static const warnDot = Color(0xFFE08A3C);
  static const water = Color(0xFF2F6A45);
  static const danger = Color(0xFFB3261E);

  static const glassFill = Color(0x70FFFFFF); // %44 beyaz
  static const glassStrong = Color(0xA6FFFFFF); // %65 beyaz
  static const glassBorder = Color(0xBFFFFFFF); // %75 beyaz

  static const font = 'Inter';

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: font,
      colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green, surface: Colors.white),
      scaffoldBackgroundColor: mint,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink, fontFamily: font),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? green : const Color(0x80FFFFFF),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
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
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
