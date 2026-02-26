import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hive_boxes.dart';

// ─── App Theme Enum ───────────────────────────────────────────────────────────
enum AppThemeVariant { gold, sapphire, emerald, platinum }

extension AppThemeVariantExt on AppThemeVariant {
  String get label {
    switch (this) {
      case AppThemeVariant.gold:
        return 'Gold';
      case AppThemeVariant.sapphire:
        return 'Sapphire Blue';
      case AppThemeVariant.emerald:
        return 'Emerald Green';
      case AppThemeVariant.platinum:
        return 'Platinum Silver';
    }
  }

  Color get accent {
    switch (this) {
      case AppThemeVariant.gold:
        return const Color(0xFFE5A93C);
      case AppThemeVariant.sapphire:
        return const Color(0xFF00B4FF);
      case AppThemeVariant.emerald:
        return const Color(0xFF00E676);
      case AppThemeVariant.platinum:
        return const Color(0xFFB0BEC5);
    }
  }

  Color get accentDark {
    switch (this) {
      case AppThemeVariant.gold:
        return const Color(0xFFB8860B);
      case AppThemeVariant.sapphire:
        return const Color(0xFF0077CC);
      case AppThemeVariant.emerald:
        return const Color(0xFF00A050);
      case AppThemeVariant.platinum:
        return const Color(0xFF78909C);
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case AppThemeVariant.gold:
        return const LinearGradient(
          colors: [Color(0xFFE5A93C), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeVariant.sapphire:
        return const LinearGradient(
          colors: [Color(0xFF0077CC), Color(0xFF00B4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeVariant.emerald:
        return const LinearGradient(
          colors: [Color(0xFF00A050), Color(0xFF00E676)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeVariant.platinum:
        return const LinearGradient(
          colors: [Color(0xFF78909C), Color(0xFFCFD8DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String get key => name; // store as string in Hive
}

// ─── Theme Notifier ───────────────────────────────────────────────────────────
class ThemeNotifier extends StateNotifier<AppThemeVariant> {
  ThemeNotifier()
      : super(() {
          final saved = HiveBoxes.settings.get('appTheme', defaultValue: 'gold') as String;
          return AppThemeVariant.values.firstWhere(
            (e) => e.name == saved,
            orElse: () => AppThemeVariant.gold,
          );
        }());

  Future<void> setTheme(AppThemeVariant theme) async {
    state = theme;
    await HiveBoxes.settings.put('appTheme', theme.key);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeVariant>(
  (ref) => ThemeNotifier(),
);
