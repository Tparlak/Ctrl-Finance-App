import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/logo_fetcher.dart';

class LogoSettingsState {
  final String logoApiKey;
  // Built-in key — works out of the box, no user input needed
  static const String _builtInKey = 'pk_Vg10ihZDT0qocIwBk-FY8A';

  const LogoSettingsState({this.logoApiKey = _builtInKey});
  bool get logoEnabled => logoApiKey.trim().isNotEmpty;

  LogoSettingsState copyWith({String? logoApiKey}) =>
      LogoSettingsState(logoApiKey: logoApiKey ?? this.logoApiKey);
}

class LogoSettingsNotifier extends StateNotifier<LogoSettingsState> {
  static const _logoKeyPref = 'logo_dev_api_key';

  LogoSettingsNotifier() : super(const LogoSettingsState());

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Use saved key if exists, otherwise fall back to built-in key
    final savedKey = prefs.getString(_logoKeyPref);
    state = state.copyWith(
      logoApiKey: (savedKey != null && savedKey.isNotEmpty)
          ? savedKey
          : LogoSettingsState._builtInKey,
    );
  }

  Future<void> setLogoApiKey(String key) async {
    final trimmed = key.trim();
    state = state.copyWith(logoApiKey: trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_logoKeyPref, trimmed);
    LogoFetcher.clearCache(); // clear cache on key change
  }
}

final logoSettingsProvider =
    StateNotifierProvider<LogoSettingsNotifier, LogoSettingsState>(
  (ref) => LogoSettingsNotifier(),
);
