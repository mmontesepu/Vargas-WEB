import 'package:flutter/material.dart';

const Color gold = Color(0xFFD5A253);
const Color ink = Color(0xFF101214);
const Color panel = Color(0xFF1B1D1F);

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        surface: panel,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
