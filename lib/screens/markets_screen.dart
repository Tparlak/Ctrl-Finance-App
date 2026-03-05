import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/market_provider.dart';
import '../models/market_data.dart';
import '../theme/app_colors.dart';

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});
  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(marketProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mp = ref.watch(marketProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Canlı Piyasalar', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: mp.isLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSurface))
                : Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.onSurface),
            onPressed: mp.isLoading ? null : () => ref.read(marketProvider.notifier).refresh(),
          ),
        ],
      ),
      body: mp.isLoading && mp.items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => ref.read(marketProvider.notifier).refresh(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 10, 16, 24),
                children: [
                  // Timestamp
                  if (mp.lastUpdated != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Son güncelleme: ${_fmtTime(mp.lastUpdated!)}',
                            style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11),
                          ),
                          if (mp.hasError)
                            Row(children: [
                              const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('Veriler eski olabilir', style: GoogleFonts.poppins(color: Colors.orange, fontSize: 11)),
                            ]),
                        ],
                      ),
                    ),

                  if (mp.doviz.isNotEmpty) ...[
                    _MarketCard(title: 'DÖVİZ', emoji: '💱', items: mp.doviz),
                    const SizedBox(height: 12),
                  ],
                  if (mp.madenler.isNotEmpty) ...[
                    _MarketCard(title: 'KIYMETLİ MADEN', emoji: '🥇', items: mp.madenler),
                    const SizedBox(height: 12),
                  ],
                  if (mp.kripto.isNotEmpty) ...[
                    _MarketCard(title: 'KRİPTO', emoji: '🔗', items: mp.kripto),
                    const SizedBox(height: 12),
                  ],

                  if (mp.items.isEmpty && !mp.isLoading)
                    Center(child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Column(children: [
                        Icon(Icons.wifi_off_rounded, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(height: 12),
                        Text('Veri alınamadı', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14)),
                        Text('İnternet bağlantınızı kontrol edin', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                      ]),
                    )),

                  const SizedBox(height: 16),
                  Center(child: Text(
                    'Kur verileri: fawazahmed0/exchange-api & CoinGecko',
                    style: GoogleFonts.poppins(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withOpacity(0.5), fontSize: 10),
                    textAlign: TextAlign.center,
                  )),
                ],
              ),
            ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
}

class _MarketCard extends StatelessWidget {
  final String title;
  final String emoji;
  final List<MarketItem> items;
  const _MarketCard({required this.title, required this.emoji, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
          ),
          Divider(color: Theme.of(context).dividerTheme.color, height: 1),
          ...items.map((item) => _MarketRow(item: item)),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  final MarketItem item;
  const _MarketRow({required this.item});

  static const _emoji = {'USD':'🇺🇸','EUR':'🇪🇺','XAU':'🥇','XAG':'🥈','BTC':'₿','ETH':'Ξ'};

  String _formatRate() {
    if (item.rateInTRY == 0) return '—';
    switch (item.code) {
      case 'BTC':
      case 'ETH':
        final s = item.rateInTRY.toStringAsFixed(0);
        return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
      case 'XAU':
      case 'XAG':
        return item.rateInTRY.toStringAsFixed(2);
      default:
        return item.rateInTRY.toStringAsFixed(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(_emoji[item.code] ?? '💰', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.code, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
              Text(item.nameTR, style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11)),
            ],
          )),
          Text('${_formatRate()} ₺', style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

