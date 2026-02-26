import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../data/hive_boxes.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class CtrlCenterScreen extends StatelessWidget {
  const CtrlCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
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
                              color: AppColors.gold.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'T',
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
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Taner',
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
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
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4)),
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
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── 4-tile Grid ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
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
                  subtitle: 'Renk ve Tema Ayarları',
                  accent: AppColors.gold,
                  onTap: () => _showThemeDialog(context),
                ),
                _CtrlTile(
                  icon: Icons.storage_rounded,
                  title: 'VERİ YÖNETİMİ',
                  subtitle: 'Yedekle & Sıfırla',
                  accent: AppColors.red,
                  onTap: () => _showResetDialog(context),
                ),
              ]),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.goldGradient.createShader(b),
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
                    Text(
                      'Versiyon 1.1.0',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(
                            text:
                                'https://github.com/Tparlak/Ctrl-Finance-App'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GitHub linki kopyalandı!')),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.code_rounded,
                              color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'github.com/Tparlak/Ctrl-Finance-App',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature yakında geliyor!'), backgroundColor: AppColors.surface),
    );
  }

  Future<void> _showSecurityDialog(BuildContext context) async {
    final curPin = HiveBoxes.settings.get('appLockPin') as String?;
    final ctrl = TextEditingController(text: curPin ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Güvenlik Kilidi', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: GoogleFonts.poppins(color: AppColors.textPrimary, letterSpacing: 8),
          decoration: const InputDecoration(labelText: '4 Haneli PIN (Kapatmak için boş bırakın)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İPTAL', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
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
      final docs = await getApplicationDocumentsDirectory();
      final path = '${docs.path}/Ctrl_Export_${DateTime.now().millisecondsSinceEpoch}.csv';
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

  Future<void> _showThemeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tema Aktarımı', style: GoogleFonts.poppins(color: AppColors.gold)),
        content: Text('VIP Teman varsayılan olarak "Koyu Zemin & Altın"dır. İlerleyen güncellemelerde "Gece Mavisi" ve "Safir" eklenecek!', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('TAMAM', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tüm Verileri Sıfırla',
          style:
              GoogleFonts.poppins(color: AppColors.red, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tüm işlem, hesap ve kategori verileri kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          style:
              GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('VAZGEÇ',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('SIFIRLA',
                style: GoogleFonts.poppins(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Tile Widget ──────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.1),
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
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
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
