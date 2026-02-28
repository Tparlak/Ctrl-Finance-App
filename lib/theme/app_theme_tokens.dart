import 'package:flutter/material.dart';

class AppThemeTokens {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color glassBg;
  final Color glassBorder;
  final Brightness brightness;

  const AppThemeTokens({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.glassBg,
    required this.glassBorder,
    required this.brightness,
  });

  // Dark Theme Tokens (Current Ctrl Colors)
  static const dark = AppThemeTokens(
    background: Color(0xFF0B0C10),
    surface: Color(0xFF1A1B22),
    textPrimary: Color(0xFFECECEC),
    textSecondary: Color(0xFF8A8A9B),
    glassBg: Color(0x0DFFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    brightness: Brightness.dark,
  );

  // Light Theme Tokens (New for v3.0)
  static const light = AppThemeTokens(
    background: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E1E2C),
    textSecondary: Color(0xFF6B6E80),
    glassBg: Color(0x0D000000), // very light dark shade for glass in light mode
    glassBorder: Color(0x1A000000),
    brightness: Brightness.light,
  );
}
