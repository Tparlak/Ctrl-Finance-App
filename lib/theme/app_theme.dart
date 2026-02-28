import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_theme_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData _buildTheme(AppThemeTokens tokens, Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      scaffoldBackgroundColor: tokens.background,
      colorScheme: ColorScheme(
        brightness: tokens.brightness,
        primary: accentColor,
        onPrimary: tokens.background,
        secondary: accentColor,
        onSecondary: tokens.background,
        error: AppColors.red,
        onError: Colors.white,
        background: tokens.background,
        onBackground: tokens.textPrimary,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: tokens.textPrimary),
          displayMedium: TextStyle(color: tokens.textPrimary),
          displaySmall: TextStyle(color: tokens.textPrimary),
          headlineLarge: TextStyle(color: tokens.textPrimary),
          headlineMedium: TextStyle(color: tokens.textPrimary),
          headlineSmall: TextStyle(color: tokens.textPrimary),
          titleLarge: TextStyle(color: tokens.textPrimary),
          titleMedium: TextStyle(color: tokens.textPrimary),
          titleSmall: TextStyle(color: tokens.textPrimary),
          bodyLarge: TextStyle(color: tokens.textPrimary),
          bodyMedium: TextStyle(color: tokens.textSecondary),
          bodySmall: TextStyle(color: tokens.textSecondary),
          labelLarge: TextStyle(color: tokens.textPrimary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: tokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: tokens.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accentColor,
        unselectedItemColor: tokens.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: tokens.background,
      ),
      dividerTheme: DividerThemeData(
        color: tokens.glassBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.glassBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: tokens.textSecondary),
        hintStyle: TextStyle(color: tokens.textSecondary),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    return _buildTheme(AppThemeTokens.dark, accentColor);
  }

  static ThemeData lightTheme(Color accentColor) {
    return _buildTheme(AppThemeTokens.light, accentColor);
  }
}
