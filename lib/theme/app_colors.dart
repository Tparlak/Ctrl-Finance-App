import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Global currency formatter: 55.000 ₺ format
final currencyFmt = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0C10);
  static const Color surface = Color(0xFF1A1B22);
  static const Color gold = Color(0xFFE5A93C);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color green = Color(0xFF2ECC71);
  static const Color blue = Color(0xFF00E5FF);
  static const Color red = Color(0xFFFF4B4B);
  static const Color textPrimary = Color(0xFFECECEC);
  static const Color textSecondary = Color(0xFF8A8A9B);

  /// Glassmorphism background — white at 5% opacity
  static const Color glassBg = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5A93C), Color(0xFFFFD700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFCC2B2B), Color(0xFFFF4B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
