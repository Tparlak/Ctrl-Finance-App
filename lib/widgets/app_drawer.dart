import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/navigation_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final accent = themeState.variant.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B0C10).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            border: Border(
              right: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _DrawerHeader(accent: accent),
                Divider(color: AppColors.glassBorder, height: 1),
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
                          Navigator.pop(context); // close drawer
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
                      Divider(color: AppColors.glassBorder, height: 24),
                      _DrawerTile(
                        icon: Icons.code,
                        label: 'GitHub',
                        accent: accent,
                        onTap: () => _launchGitHub(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ctrl Finance v5.0',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
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
  const _DrawerHeader({required this.accent});

  @override
  Widget build(BuildContext context) {
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
                colors: [accent.withValues(alpha: 0.3), AppColors.gold.withValues(alpha: 0.15)],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Icon(Icons.person_rounded, color: accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kullanıcı',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
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
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 8),
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
      leading: Icon(icon, size: 22, color: AppColors.textSecondary),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
