import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/logo_fetcher.dart';

class LogoSettingsState {
  final String logoApiKey;
  const LogoSettingsState({this.logoApiKey = ''});
  bool get logoEnabled => logoApiKey.trim().isNotEmpty;

  LogoSettingsState copyWith({String? logoApiKey}) =>
      LogoSettingsState(logoApiKey: logoApiKey ?? this.logoApiKey);
}

class LogoSettingsNotifier extends StateNotifier<LogoSettingsState> {
  static const _logoKeyPref = 'logo_dev_api_key';

  LogoSettingsNotifier() : super(const LogoSettingsState());

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_logoKeyPref) ?? '';
    state = state.copyWith(logoApiKey: savedKey);
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
