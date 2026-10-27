import 'package:flutter/material.dart';

/// App theme spec complying with AGENTS.md:
/// - Light: warm paper background, dark ink FAB
/// - Dark: deep navy background, gold FAB
/// - WCAG AA compliant contrast
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF1B2028), // dark ink
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFFD4AF37), // warm brass gold accent
      onSecondary: const Color(0xFF1B2028),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      surface: const Color(0xFFF9F6F0), // warm paper background
      onSurface: const Color(0xFF1C1B1F),
      surfaceContainerHighest: const Color(0xFFEBE6DC),
      outline: const Color(0xFF79747E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFFE5C158), // radiant gold FAB
      onPrimary: const Color(0xFF141923),
      secondary: const Color(0xFFC5C6D0), // silver cool accent
      onSecondary: const Color(0xFF141923),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      surface: const Color(0xFF0F141C), // deep navy background
      onSurface: const Color(0xFFE2E2E6),
      surfaceContainerHighest: const Color(0xFF1B2230),
      outline: const Color(0xFF8E9099),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
