import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/market_data.dart';

class MarketApiService {
  static const _primaryBase  = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';
  static const _fallbackBase = 'https://latest.currency-api.pages.dev/v1/currencies';
  static const _cryptoUrl    = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=try';

  static Future<List<MarketItem>> fetchAll() async {
    final now = DateTime.now();
    final items = <MarketItem>[];

    // ── FIAT + METALS ─────────────────────────────────────────────────────
    Map<String, dynamic>? usdData;
    for (final base in [_primaryBase, _fallbackBase]) {
      try {
        final r = await http
            .get(Uri.parse('$base/usd.min.json'), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          usdData = (jsonDecode(r.body) as Map<String, dynamic>)['usd'] as Map<String, dynamic>;
          break;
        }
      } catch (_) { continue; }
    }

    if (usdData != null) {
      final tryPerUsd = (usdData['try'] as num).toDouble();
      final eurPerUsd = (usdData['eur'] as num?)?.toDouble();
      final xauPerUsd = (usdData['xau'] as num?)?.toDouble();
      final xagPerUsd = (usdData['xag'] as num?)?.toDouble();

      items.add(MarketItem(code: 'USD', nameTR: 'Amerikan Doları', rateInTRY: tryPerUsd, fetchedAt: now));

      if (eurPerUsd != null && eurPerUsd > 0) {
        items.add(MarketItem(code: 'EUR', nameTR: 'Euro',
            rateInTRY: tryPerUsd / eurPerUsd, fetchedAt: now));
      }

      if (xauPerUsd != null && xauPerUsd > 0) {
        items.add(MarketItem(code: 'XAU', nameTR: 'Altın (gram)',
            rateInTRY: (tryPerUsd / xauPerUsd) / 31.1035, fetchedAt: now));
      }

      if (xagPerUsd != null && xagPerUsd > 0) {
        items.add(MarketItem(code: 'XAG', nameTR: 'Gümüş (gram)',
            rateInTRY: (tryPerUsd / xagPerUsd) / 31.1035, fetchedAt: now));
      }
    }

    // ── CRYPTO ────────────────────────────────────────────────────────────
    try {
      final r = await http.get(Uri.parse(_cryptoUrl)).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        final btc = (j['bitcoin']?['try'] as num?)?.toDouble() ?? 0;
        final eth = (j['ethereum']?['try'] as num?)?.toDouble() ?? 0;
        if (btc > 0) items.add(MarketItem(code: 'BTC', nameTR: 'Bitcoin',  rateInTRY: btc, fetchedAt: now));
        if (eth > 0) items.add(MarketItem(code: 'ETH', nameTR: 'Ethereum', rateInTRY: eth, fetchedAt: now));
      }
    } catch (_) {}

    return items;
  }
}
