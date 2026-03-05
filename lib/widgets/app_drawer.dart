import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme_tokens.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  String _userName = '';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('userName') ?? '';
        _appVersion = 'Ctrl v${info.version}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final accent = themeState.variant.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = isDark ? AppThemeTokens.dark : AppThemeTokens.light;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.background.withOpacity(0.95),
            border: Border(
              right: BorderSide(color: tokens.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _DrawerHeader(accent: accent, userName: _userName),
                Divider(color: tokens.glassBorder, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _DrawerTile(
                        icon: Icons.dashboard_outlined,
                        label: 'Bütçem',
                        accent: accent,
                        onTap: () {
                          ref.read(navigationProvider.notifier).setIndex(0);
                          Navigator.pop(context);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Hesaplar',
                        accent: accent,
                        onTap: () {
                          ref.read(navigationProvider.notifier).setIndex(1);
                          Navigator.pop(context);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.schedule_outlined,
                        label: 'Yaklaşan İşlemler',
                        accent: accent,
                        onTap: () {
                          ref.read(navigationProvider.notifier).setIndex(2);
                          Navigator.pop(context);
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.directions_car_outlined,
                        label: 'Araç Yönetimi',
                        accent: accent,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/car-ledger');
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.alarm_outlined,
                        label: 'Hatırlatıcılar',
                        accent: accent,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/reminders');
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.sticky_note_2_outlined,
                        label: 'Notlarım',
                        accent: accent,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/notes');
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.candlestick_chart_outlined,
                        label: 'Canlı Piyasalar',
                        accent: accent,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/markets');
                        },
                      ),
                      _DrawerTile(
                        icon: Icons.settings_outlined,
                        label: 'Ayarlar',
                        accent: accent,
                        onTap: () {
                          ref.read(navigationProvider.notifier).setIndex(3);
                          Navigator.pop(context);
                        },
                      ),
                      Divider(color: tokens.glassBorder, height: 24),
                      _DrawerTile(
                        icon: Icons.code,
                        label: 'GitHub',
                        accent: accent,
                        onTap: () => _launchGitHub(context),
                      ),
                    ],
                  ),
                ),
                // ── Bottom: Dynamic version ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    _appVersion.isNotEmpty ? _appVersion : 'Ctrl Finance',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchGitHub(BuildContext context) async {
    final uri = Uri.parse('https://github.com/Tparlak/Ctrl-Finance-App');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bağlantı açılamadı')),
        );
      }
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  final Color accent;
  final String userName;
  const _DrawerHeader({required this.accent, required this.userName});

  @override
  Widget build(BuildContext context) {
    final displayName = userName.isNotEmpty ? userName : 'Kullanıcı';
    final initial = displayName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.3), AppColors.gold.withOpacity(0.15)],
              ),
              border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 8),
                    ],
                  ),
                  child: Text(
                    '✦ VIP',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Theme.of(context).textTheme.bodySmall?.color),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
