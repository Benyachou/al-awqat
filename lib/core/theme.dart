import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0A1929);
  static const Color surface = Color(0xFF132F4C);
  static const Color accent = Color(0xFF66B2FF);
  static const Color highlight = Color(0xFFFFB74D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color divider = Color(0xFF1E4976);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: highlight,
          surface: surface,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(color: textPrimary),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
      );
}
