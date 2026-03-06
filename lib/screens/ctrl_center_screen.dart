import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/hive_boxes.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/theme_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/fixed_expense_provider.dart';
import '../providers/logo_settings_provider.dart';
import '../data/services/logo_fetcher.dart';
import '../data/services/ocr_service.dart';
import 'category_manager_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bounce_tap.dart';

class CtrlCenterScreen extends ConsumerStatefulWidget {
  const CtrlCenterScreen({super.key});

  @override
  ConsumerState<CtrlCenterScreen> createState() => _CtrlCenterScreenState();
}

class _CtrlCenterScreenState extends ConsumerState<CtrlCenterScreen> {
  String _userName = 'VIP Kullanıcı';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? '';
    if (mounted && name.isNotEmpty) {
      setState(() => _userName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'C';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).inputDecorationTheme.fillColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                              ),
                              child: const Icon(Icons.menu_rounded, color: AppColors.gold, size: 22),
                            ),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar / badge
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VIP KULLANICI',
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _userName,
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.gold.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.gold, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'VIP',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'CTRL CENTER',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // ── 4-tile Grid ──────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    children: [
                      _CtrlTile(
                        icon: Icons.security_rounded,
                        title: 'GÜVENLİK',
                        subtitle: 'Uygulama açılış şifresi',
                        accent: AppColors.blue,
                        onTap: () => _showSecurityDialog(context),
                      ),
                      _CtrlTile(
                        icon: Icons.file_download_rounded,
                        title: 'DIŞA AKTAR',
                        subtitle: 'İşlemleri CSV olarak indir',
                        accent: AppColors.green,
                        onTap: () => _exportToCSV(context),
                      ),
                      _CtrlTile(
                        icon: Icons.palette_rounded,
                        title: 'GÖRÜNÜM',
                        subtitle: 'Renk ve Tema Seçimi',
                        accent: themeState.variant.accent,
                        onTap: () => _showThemeDialog(context, ref),
                      ),
                      _CtrlTile(
                        icon: Icons.category_rounded,
                        title: 'KATEGORİLER',
                        subtitle: 'Gelir/Gider kategorileri',
                        accent: AppColors.gold,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              extendBodyBehindAppBar: true,
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              appBar: AppBar(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                leading: IconButton(
                                  icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              body: const CategoryManagerScreen(),
                            ),
                          ),
                        ),
                      ),
                      _CtrlTile(
                        icon: Icons.storage_rounded,
                        title: 'VERİ YÖNETİMİ',
                        subtitle: 'Yedekle & Sıfırla',
                        accent: AppColors.red,
                        onTap: () => _showResetDialog(context, ref),
                      ),
                    ],
                  ),
                ),
                // ── Logo Engine Section ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _LogoEngineSection(),
                ),
                // ── Footer ───────────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                              child: Text(
                                'CTRL',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const VersionFooter(),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('https://github.com/Tparlak/Ctrl-Finance-App');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.code_rounded, color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'github.com/Tparlak/Ctrl-Finance-App',
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature yakında geliyor!'), backgroundColor: Theme.of(context).colorScheme.surface),
    );
  }

  Future<void> _showSecurityDialog(BuildContext context) async {
    final curPin = HiveBoxes.settings.get('appLockPin') as String?;
    final ctrl = TextEditingController(text: curPin ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Güvenlik Kilidi', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, letterSpacing: 8),
          decoration: const InputDecoration(labelText: '4 Haneli PIN (Kapatmak için boş bırakın)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İPTAL', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) {
                await HiveBoxes.settings.delete('appLockPin');
              } else if (ctrl.text.length == 4) {
                await HiveBoxes.settings.put('appLockPin', ctrl.text);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.black),
            child: Text('KAYDET', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final path = '${dir.path}/Ctrl_Export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);

      final buffer = StringBuffer();
      buffer.writeln('ID,Tarih,Tutar,Aciklama,Kategori');
      
      final txs = HiveBoxes.transactions.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final fmt = DateFormat('yyyy-MM-dd HH:mm');

      for (var tx in txs) {
        final d = fmt.format(tx.date);
        buffer.writeln('${tx.id},$d,${tx.amount},"${tx.description}",${tx.categoryId}');
      }

      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV oluşturuldu:\n$path'),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) _showComingSoon(context, 'Dışa Aktarma Başarısız');
    }
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final currentState = ref.read(themeProvider);
    ThemeMode curMode = currentState.themeMode;
    AppThemeVariant curVariant = currentState.variant;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Görünüm Seç', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
        content: StatefulBuilder(builder: (ctx, setS) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tema Arka Planı', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistem', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: ThemeMode.light, label: Text('Açık', style: TextStyle(fontSize: 12))),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Koyu', style: TextStyle(fontSize: 12))),
                  ],
                  selected: {curMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) async {
                    curMode = newSelection.first;
                    await ref.read(themeProvider.notifier).setMode(curMode);
                    setS(() {});
                  },
                ),
                const SizedBox(height: 24),
                Text('Vurgu Rengi', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...AppThemeVariant.values.map((theme) {
                  final selected = curVariant == theme;
                  final themeBg = Theme.of(context).inputDecorationTheme.fillColor ?? Colors.transparent;
                  final themeBorder = Theme.of(context).dividerTheme.color ?? Colors.transparent;

                  return GestureDetector(
                    onTap: () async {
                      curVariant = theme;
                      await ref.read(themeProvider.notifier).setVariant(curVariant);
                      setS(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? theme.accent.withOpacity(0.15) : themeBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? theme.accent : themeBorder,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: theme.gradient,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(theme.label,
                                style: GoogleFonts.poppins(
                                  color: selected ? theme.accent : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                )),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded, color: theme.accent, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('KAPAT', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tüm Verileri Sıfırla',
          style: GoogleFonts.poppins(color: AppColors.red, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tüm işlem, hesap, kategori ve sabit gider verileri kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('VAZGEÇ',
                style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // ── Tüm Hive box'larını temizle ───────────────────────────
              await HiveBoxes.accounts.clear();
              await HiveBoxes.transactions.clear();
              await HiveBoxes.categories.clear();
              await HiveBoxes.fixedExpenses.clear();
              // ── Seeded flag'i sıfırla (bir dahaki açılışta seed tekrar çalışmasın) ─
              await HiveBoxes.settings.delete('isSeeded');
              // ── Providers'ı yenile ─────────────────────────────────────
              ref.invalidate(accountProvider);
              ref.invalidate(transactionProvider);
              ref.invalidate(categoryProvider);
              ref.invalidate(fixedExpenseProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tüm veriler sıfırlandı ✓',
                        style: GoogleFonts.poppins(color: Colors.white)),
                    backgroundColor: AppColors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('SIFIRLA',
                style: GoogleFonts.poppins(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _CtrlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _CtrlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.1),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VersionFooter extends StatelessWidget {
  const VersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (ctx, snap) {
        final version = snap.data?.version ?? '7.1.1';
        final build = snap.data?.buildNumber ?? '72';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Center(
            child: GestureDetector(
              onLongPress: () => _showOcrDebugDialog(context),
              child: Text(
                'Ctrl Finance v$version ($build)',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOcrDebugDialog(BuildContext context) {
    final rawText = OcrService.lastRawText ?? 'Henüz fiş taranmadı.';
    final normalizedText = OcrService.lastNormalizedText ?? 'Henüz fiş taranmadı.';

    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text(
            '🔍 OCR Debug Modu',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Ham ML Kit'),
                    Tab(text: 'Normalleştirilmiş'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDebugText(rawText, ctx),
                      _buildDebugText(normalizedText, ctx),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugText(String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black26 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ── Logo Engine Settings Section ──────────────────────────────────────────────

class _LogoEngineSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LogoEngineSection> createState() => _LogoEngineSectionState();
}

class _LogoEngineSectionState extends ConsumerState<_LogoEngineSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(logoSettingsProvider).logoApiKey;
    _controller = TextEditingController(text: currentKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(logoSettingsProvider);
    final isEnabled = settings.logoEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏷️ LOGO MOTORU',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isEnabled ? AppColors.green : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: isEnabled
                          ? [BoxShadow(color: AppColors.green.withOpacity(0.5), blurRadius: 6)]
                          : [],
                    ),
                  ),
                  Text(
                    isEnabled
                        ? 'Aktif — İşlem logoları çekiliyor'
                        : 'Pasif — API key girilmedi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isEnabled ? AppColors.green : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'logo.dev Publishable Key',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                  hintText: 'pk_...',
                  helperText: 'logo.dev → ücretsiz kayıt → Dashboard → API Keys',
                  helperStyle: GoogleFonts.poppins(fontSize: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _controller.clear();
                            ref.read(logoSettingsProvider.notifier).setLogoApiKey('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (v) {
                  ref.read(logoSettingsProvider.notifier).setLogoApiKey(v);
                  setState(() {});
                },
              ),
              if (isEnabled) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: const Icon(Icons.preview_rounded, size: 16),
                  label: Text('Önizle — Migros', style: GoogleFonts.poppins(fontSize: 12)),
                  onPressed: () {
                    final url = LogoFetcher.getLogoUrl(
                      description: 'migros',
                      apiKey: settings.logoApiKey,
                    );
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Logo Testi', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface)),
                        content: url != null
                            ? CachedNetworkImage(
                                imageUrl: url,
                                width: 80, height: 80,
                                errorWidget: (_, __, ___) => const Text('Logo yüklenemedi'),
                              )
                            : const Text('URL oluşturulamadı.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

