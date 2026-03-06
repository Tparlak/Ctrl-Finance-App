import 'package:flutter/material.dart';
import '../models/receipt_item.dart';

/// Detects the type of Turkish fiscal receipt and routes to the correct parser.
enum ReceiptType { market, fuel, restaurant, utility, unknown }

class TurkishReceiptParser {

  /// Main entry point. Returns a fully parsed result from raw OCR text.
  static ParsedReceipt parse(String rawText) {
    final lines = _cleanLines(rawText);
    final type = _detectType(lines);

    return switch (type) {
      ReceiptType.fuel       => _parseFuel(lines, rawText),
      ReceiptType.market     => _parseMarket(lines, rawText),
      ReceiptType.restaurant => _parseRestaurant(lines, rawText),
      ReceiptType.utility    => _parseUtility(lines, rawText),
      ReceiptType.unknown    => _parseGeneric(lines, rawText),
    };
  }

  // ── LINE CLEANING ──────────────────────────────────────────────────────────
  static List<String> _cleanLines(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  // ── RECEIPT TYPE DETECTION ────────────────────────────────────────────────
  static ReceiptType _detectType(List<String> lines) {
    final joined = lines.join(' ').toUpperCase();

    // Fuel indicators
    if (_containsAny(joined, [
      'AKARYAKIT', 'PETROL', 'MOTORIN', 'BENZİN', 'BENZIN',
      'YAKIT', 'LT)', 'LİTRE', 'BİRİM FİYAT', 'BIRIM FIYAT',
      'MİKTAR(LT', 'MIKTAR(LT', 'OPET', 'SHELL', 'BP ', 'PETROL OFİSİ',
      'TOTAL OİL', 'LUKOIL', 'HAYALOİL',
    ])) return ReceiptType.fuel;

    // Restaurant / cafe indicators
    if (_containsAny(joined, [
      'RESTORAN', 'CAFE', 'KAHVE', 'PIZZA', 'BURGER',
      'YEMEK', 'MASA NO', 'GARSON', 'KİŞİ SAYISI',
    ])) return ReceiptType.restaurant;

    // Utility bill indicators
    if (_containsAny(joined, [
      'FATURA NO', 'ABONE NO', 'SAYAÇ NO', 'TÜKETİM',
      'ELEKTRIK', 'DOĞALGAZ', 'SU FATURASI',
    ])) return ReceiptType.utility;

    // Market (most common — default for anything with items)
    if (_containsAny(joined, [
      'TOPLAM', 'KDV', 'FİŞ NO', 'FIS NO', 'EKÜ', 'Z NO',
      'MARKET', 'A.Ş', 'TAŞ.',
    ])) return ReceiptType.market;

    return ReceiptType.unknown;
  }

  // ── MARKET RECEIPT PARSER ─────────────────────────────────────────────────
  // Handles: ŞOK, BİM, A101, Migros, CarrefourSA, Hakmar, File, Onur, etc.
  static ParsedReceipt _parseMarket(List<String> lines, String raw) {
    return ParsedReceipt(
      receiptType: ReceiptType.market,
      merchantName: _extractMerchantName(lines),
      total:        _extractMarketTotal(lines),
      date:         _extractDate(lines),
      time:         _extractTime(lines),
      accountHint:  _extractAccountHint(lines),
      items:        _extractMarketItems(lines),
      rawText:      raw,
    );
  }

  // ── FUEL RECEIPT PARSER ───────────────────────────────────────────────────
  // Handles: OPET, Shell, BP, Petrol Ofisi, Total, Lukoil, etc.
  static ParsedReceipt _parseFuel(List<String> lines, String raw) {
    final liters       = _extractFuelLiters(lines);
    final pricePerLt   = _extractPricePerLiter(lines);
    final total        = _extractFuelTotal(lines) ??
                         (liters != null && pricePerLt != null
                            ? double.parse((liters * pricePerLt).toStringAsFixed(2))
                            : null);
    final fuelType     = _extractFuelType(lines);
    final plate        = _extractVehiclePlate(lines);

    // Build a descriptive merchant string for the transaction
    final merchant = [
      _extractMerchantName(lines),
      if (fuelType != null) '($fuelType)',
      if (plate != null) '[$plate]',
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return ParsedReceipt(
      receiptType: ReceiptType.fuel,
      merchantName: merchant.isNotEmpty ? merchant : _extractMerchantName(lines),
      total:       total,
      date:        _extractDate(lines),
      time:        _extractTime(lines),
      accountHint: _extractAccountHint(lines),
      items:       liters != null ? [
        ReceiptItem(
          name: fuelType ?? 'Yakıt',
          price: total ?? 0,
          quantity: null,
        ),
      ] : [],
      rawText: raw,
      // Fuel-specific extras
      fuelLiters:    liters,
      fuelType:      fuelType,
      vehiclePlate:  plate,
    );
  }

  // ── RESTAURANT PARSER ─────────────────────────────────────────────────────
  static ParsedReceipt _parseRestaurant(List<String> lines, String raw) {
    return ParsedReceipt(
      receiptType:  ReceiptType.restaurant,
      merchantName: _extractMerchantName(lines),
      total:        _extractMarketTotal(lines),
      date:         _extractDate(lines),
      time:         _extractTime(lines),
      accountHint:  _extractAccountHint(lines),
      items:        _extractMarketItems(lines),
      rawText:      raw,
    );
  }

  // ── UTILITY BILL PARSER ───────────────────────────────────────────────────
  static ParsedReceipt _parseUtility(List<String> lines, String raw) {
    return ParsedReceipt(
      receiptType:  ReceiptType.utility,
      merchantName: _extractMerchantName(lines),
      total:        _extractUtilityTotal(lines),
      date:         _extractDate(lines),
      time:         _extractTime(lines),
      accountHint:  _extractAccountHint(lines),
      items:        [],
      rawText:      raw,
    );
  }

  // ── GENERIC FALLBACK ──────────────────────────────────────────────────────
  static ParsedReceipt _parseGeneric(List<String> lines, String raw) {
    return ParsedReceipt(
      receiptType:  ReceiptType.unknown,
      merchantName: _extractMerchantName(lines),
      total:        _extractAmountFallback(raw),
      date:         _extractDate(lines),
      time:         _extractTime(lines),
      accountHint:  _extractAccountHint(lines),
      items:        _extractMarketItems(lines),
      rawText:      raw,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIELD EXTRACTORS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── MERCHANT NAME ──────────────────────────────────────────────────────────
  // Turkish receipts: company name is always in first 1-3 lines, ALL CAPS
  static String? _extractMerchantName(List<String> lines) {
    // Skip lines that are separators, dates, or too short
    final skipPatterns = RegExp(
      r'^[-=*_.]{3,}$|^\d{2}[./]\d{2}|^VKN|^Tel:|^www\.|^http',
      caseSensitive: false,
    );

    for (final line in lines.take(5)) {
      if (line.length < 3) continue;
      if (skipPatterns.hasMatch(line)) continue;
      // Prefer ALL CAPS lines in first 5 lines (Turkish company names)
      if (line == line.toUpperCase() && line.length > 4) return _cleanMerchantName(line);
    }

    // Fallback: first non-empty line that isn't a number
    for (final line in lines.take(3)) {
      if (line.length > 3 && !RegExp(r'^\d').hasMatch(line)) {
        return _cleanMerchantName(line);
      }
    }
    return null;
  }

  static String _cleanMerchantName(String raw) {
    // Remove common suffixes that clutter the description field
    return raw
        .replaceAll(RegExp(r'\s+(T\.A\.Ş\.|A\.Ş\.|LTD\.|ŞTİ\.?|TİC\.?)\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── MARKET TOTAL ──────────────────────────────────────────────────────────
  /// Priority order (most specific → least specific):
  /// 1. "TOPLAM" alone on line OR "TOPLAM" followed by amount
  /// 2. "GENEL TOPLAM" 
  /// 3. "ARA TOPLAM" (if no TOPLAM found)
  /// 4. Largest amount in receipt (last resort)
  /// 
  /// MUST NOT match: "TOPLAM KDV", "TOPKDV", "KDV TOPLAM"
  static double? _extractMarketTotal(List<String> lines) {
    // Pass 1: Look for "TOPLAM" line that is NOT followed by KDV/TAX
    // Pattern: line containing TOPLAM (but not KDV/TAX right after it)
    // and a currency amount
    final toplamRegex = RegExp(
      r'^(?!.*KDV)(?!.*TOPKDV).*\bTOPLAM\b.*?(\d{1,6}[,.]\d{2})',
      caseSensitive: false,
    );

    // Scan bottom-up (TOPLAM is usually near the bottom)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final m = toplamRegex.firstMatch(line);
      if (m != null) {
        final val = _parseAmount(m.group(1)!);
        // Sanity check: should be > 0 and < 100000
        if (val != null && val > 0 && val < 100000) return val;
      }
    }

    // Pass 2: "GENEL TOPLAM"
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toUpperCase();
      if (line.contains('GENEL TOPLAM')) {
        final val = _extractAmountFromLine(lines[i]);
        if (val != null && val > 0) return val;
      }
    }

    // Pass 3: "ARA TOPLAM" as last resort
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toUpperCase();
      if (line.contains('ARA TOPLAM')) {
        final val = _extractAmountFromLine(lines[i]);
        if (val != null && val > 0) return val;
      }
    }

    // Pass 4: Last resort fallback
    return _extractAmountFallback(lines.join('\n'));
  }

  // ── FUEL TOTAL ────────────────────────────────────────────────────────────
  /// Fuel receipts use "TUTAR" not "TOPLAM"
  static double? _extractFuelTotal(List<String> lines) {
    final tutarRegex = RegExp(
      r'\bTUTAR\b[:\s]*(\d{1,6}[,.]\d{2})',
      caseSensitive: false,
    );
    for (final line in lines.reversed) {
      final m = tutarRegex.firstMatch(line);
      if (m != null) {
        final val = _parseAmount(m.group(1)!);
        if (val != null && val > 0) return val;
      }
    }
    // Also try TOPLAM for fuel
    return _extractMarketTotal(lines);
  }

  // ── UTILITY TOTAL ─────────────────────────────────────────────────────────
  static double? _extractUtilityTotal(List<String> lines) {
    final patterns = [
      RegExp(r'(?:ÖDENECEK TUTAR|TAHAKKUK TUTARI|TOPLAM TUTAR)[:\s]*(\d{1,6}[,.]\d{2})', caseSensitive: false),
      RegExp(r'(?:TUTAR|TOPLAM)[:\s]*(\d{1,6}[,.]\d{2})', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      for (final line in lines.reversed) {
        final m = pattern.firstMatch(line);
        if (m != null) {
          final val = _parseAmount(m.group(1)!);
          if (val != null && val > 0) return val;
        }
      }
    }
    return _extractAmountFallback(lines.join('\n'));
  }

  // ── FUEL LITERS ────────────────────────────────────────────────────────────
  static double? _extractFuelLiters(List<String> lines) {
    final regex = RegExp(
      r'(?:MİKTAR|MIKTAR)\s*(?:\(LT\))?\s*[:\s]*(\d{1,5}[,.]\d{1,4})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = regex.firstMatch(line);
      if (m != null) return _parseAmount(m.group(1)!);
    }
    return null;
  }

  // ── PRICE PER LITER ───────────────────────────────────────────────────────
  static double? _extractPricePerLiter(List<String> lines) {
    final regex = RegExp(
      r'(?:BİRİM FİYAT|BIRIM FIYAT|LT FİYATI)[:\s]*(\d{1,4}[,.]\d{2,4})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = regex.firstMatch(line);
      if (m != null) return _parseAmount(m.group(1)!);
    }
    return null;
  }

  // ── FUEL TYPE ─────────────────────────────────────────────────────────────
  static String? _extractFuelType(List<String> lines) {
    const types = {
      'MOTORİN':      'Motorin',
      'MOTORIN':      'Motorin',
      'DİZEL':        'Motorin',
      'DIZEL':        'Motorin',
      'BENZİN 95':    'Benzin 95',
      'BENZIN 95':    'Benzin 95',
      'BENZİN 97':    'Benzin 97',
      'BENZIN 97':    'Benzin 97',
      'BENZİN 98':    'Benzin 98',
      'LPG':          'LPG',
      'AUTOGAS':      'LPG',
      'EURO DİZEL':   'Euro Dizel',
    };
    final joined = lines.join(' ').toUpperCase();
    for (final entry in types.entries) {
      if (joined.contains(entry.key)) return entry.value;
    }
    return null;
  }

  // ── VEHICLE PLATE ─────────────────────────────────────────────────────────
  static String? _extractVehiclePlate(List<String> lines) {
    // Turkish plate: 2 digits + 1-3 letters + 2-4 digits (e.g., 41 ABC 123)
    final plateRegex = RegExp(
      r'(?:ARAÇ PLAKA|PLAKA)[:\s]*(\d{2}\s*[A-ZÇĞİÖŞÜ]{1,3}\s*\d{2,4})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = plateRegex.firstMatch(line);
      if (m != null) return m.group(1)!.trim();
    }
    return null;
  }

  // ── DATE EXTRACTION ───────────────────────────────────────────────────────
  // Handles both: "TARİH: 02/03/2026" and "TARİH: 02/03/2026  14:38"
  // Also handles: "02.03.2026" or "2026-03-02" standalone
  static DateTime? _extractDate(List<String> lines) {
    // Pattern 1: TARİH label with date (most reliable)
    final labeledDate = RegExp(
      r'(?:TARİH|TARIH|DATE)[:\s]*(\d{2})[./\-](\d{2})[./\-](\d{4})',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = labeledDate.firstMatch(line);
      if (m != null) {
        return _buildDate(m.group(1)!, m.group(2)!, m.group(3)!);
      }
    }

    // Pattern 2: Standalone date anywhere in receipt
    final standaloneDMY = RegExp(r'\b(\d{2})[./](\d{2})[./](\d{4})\b');
    for (final line in lines) {
      final m = standaloneDMY.firstMatch(line);
      if (m != null) {
        final d = int.tryParse(m.group(1)!);
        final mo = int.tryParse(m.group(2)!);
        final y = int.tryParse(m.group(3)!);
        if (d != null && mo != null && y != null &&
            d >= 1 && d <= 31 && mo >= 1 && mo <= 12 && y > 2000) {
          return DateTime(y, mo, d);
        }
      }
    }
    return null;
  }

  // ── TIME EXTRACTION ───────────────────────────────────────────────────────
  static TimeOfDay? _extractTime(List<String> lines) {
    // Pattern: HH:MM (not HH:MM:SS — we drop seconds)
    final timeRegex = RegExp(r'\b(\d{2}):(\d{2})(?::\d{2})?\b');
    for (final line in lines) {
      final m = timeRegex.firstMatch(line);
      if (m != null) {
        final h = int.tryParse(m.group(1)!);
        final min = int.tryParse(m.group(2)!);
        if (h != null && min != null && h <= 23 && min <= 59) {
          return TimeOfDay(hour: h, minute: min);
        }
      }
    }
    return null;
  }

  // ── ACCOUNT / PAYMENT METHOD HINT ────────────────────────────────────────
  static String? _extractAccountHint(List<String> lines) {
    final joined = lines.join(' ').toUpperCase();

    // Check payment method first (more specific than bank name)
    if (joined.contains('NAKİT') || joined.contains('NAKIT')) return 'NAKİT';
    if (joined.contains('KREDİ KART') || joined.contains('KREDI KART')) {
      // Try to identify the bank
      const bankKeywords = {
        'AKBANK': 'Akbank', 'GARANTİ': 'Garanti', 'GARANTI': 'Garanti',
        'ZİRAAT': 'Ziraat', 'ZIRAAT': 'Ziraat', 'HALKBANK': 'Halkbank',
        'VAKIFBANK': 'Vakıfbank', 'YAPI KREDİ': 'Yapı Kredi',
        'YAPIKREDI': 'Yapı Kredi', 'QNB': 'QNB Finansbank',
        'FİNANSBANK': 'QNB Finansbank', 'DENİZBANK': 'Denizbank',
        'TEB': 'TEB', 'ING': 'ING Bank', 'ODEABANK': 'Odeabank',
      };
      for (final entry in bankKeywords.entries) {
        if (joined.contains(entry.key)) return entry.value;
      }
      return 'Kredi Kartı';
    }
    if (joined.contains('BANKA KARTI') || joined.contains('BANKKART')) return 'Banka Kartı';
    if (joined.contains('TEMASSIZ') || joined.contains('TEMAZSIZ')) return 'Temassız Ödeme';

    return null;
  }

  // ── MARKET ITEM EXTRACTION ────────────────────────────────────────────────
  /// Turkish market items use a 2-line format:
  ///   Line 1: "NORMAL EKMEK          *1"    (name + qty with * prefix)
  ///   Line 2: "      6,50  %1    0,06"       (price + KDV rate + KDV amount)
  ///
  /// Or single-line format:
  ///   "NORMAL EKMEK     1   6,50"
  static List<ReceiptItem> _extractMarketItems(List<String> lines) {
    final items = <ReceiptItem>[];

    // Boundaries — stop collecting items when we hit these
    final stopKeywords = RegExp(
      r'^\s*(?:TOPLAM|TUTAR|KDV|TOPKDV|NAKİT|NAKIT|PARA ÜSTÜ|PARA USTU|'
      r'EKÜ|Z NO|FİŞ NO|FIS NO|ONAY|TARİH|TARIH|SAAT|\*\s*\*)',
      caseSensitive: false,
    );

    // 2-line format: name line ends with *N (quantity)
    final qtyLineRegex = RegExp(r'(.+?)\s+\*(\d+)\s*$');
    // Price line: starts with spaces + amount
    final priceLineRegex = RegExp(r'^\s*(\d{1,6}[,.]\d{2})');
    // Single-line format: name + qty + price
    final singleLineRegex = RegExp(
      r'^([A-ZÇĞİÖŞÜa-zçğışöüñ0-9\s%./\-]{2,35}?)\s+(\d{1,4})\s+(\d{1,6}[,.]\d{2})\s*$',
    );

    bool inItemSection = false;
    String? pendingItemName;
    int? pendingQty;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Detect start of item section (first item-like line after merchant header)
      if (!inItemSection) {
        // We're in item section once we see something that looks like an item
        if (qtyLineRegex.hasMatch(line) || singleLineRegex.hasMatch(line)) {
          inItemSection = true;
        }
      }

      if (stopKeywords.hasMatch(line)) {
        inItemSection = false;
        pendingItemName = null;
        continue;
      }

      if (!inItemSection) continue;

      // Try 2-line format: "ITEM NAME   *2"
      final qtyMatch = qtyLineRegex.firstMatch(line);
      if (qtyMatch != null) {
        pendingItemName = qtyMatch.group(1)!.trim();
        pendingQty = int.tryParse(qtyMatch.group(2)!);
        continue;
      }

      // If we have a pending item name, next line should be the price
      if (pendingItemName != null) {
        final priceMatch = priceLineRegex.firstMatch(line);
        if (priceMatch != null) {
          final price = _parseAmount(priceMatch.group(1)!);
          if (price != null && price > 0 && price < 50000) {
            items.add(ReceiptItem(
              name: _cleanItemName(pendingItemName!),
              price: price,
              quantity: pendingQty,
            ));
          }
        }
        pendingItemName = null;
        pendingQty = null;
        continue;
      }

      // Try single-line format: "ITEM  1  6.50"
      final singleMatch = singleLineRegex.firstMatch(line);
      if (singleMatch != null) {
        final price = _parseAmount(singleMatch.group(3)!);
        if (price != null && price > 0 && price < 50000) {
          items.add(ReceiptItem(
            name: _cleanItemName(singleMatch.group(1)!.trim()),
            price: price,
            quantity: int.tryParse(singleMatch.group(2)!),
          ));
        }
      }
    }

    return items;
  }

  // ── AMOUNT FALLBACK ────────────────────────────────────────────────────────
  /// Last resort: find the largest currency number in the text,
  /// but skip numbers that look like dates, KDV-only amounts, or change amounts.
  static double? _extractAmountFallback(String text) {
    // Exclude KDV-related and date patterns
    final exclusionZones = RegExp(
      r'(?:KDV|TOPKDV|PARA ÜSTÜ|PARA USTU|VKN|FİŞ NO|EKÜ|Z NO)\s*[:\s]*\d+[,.]\d{2}',
      caseSensitive: false,
    );
    final cleaned = text.replaceAll(exclusionZones, '');

    final amounts = RegExp(r'\b(\d{1,6}[,.]\d{2})\b')
        .allMatches(cleaned)
        .map((m) => _parseAmount(m.group(1)!) ?? 0.0)
        .where((v) => v > 0.5 && v < 100000)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    return amounts.isNotEmpty ? amounts.first : null;
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static double? _extractAmountFromLine(String line) {
    final m = RegExp(r'(\d{1,6}[,.]\d{2})').firstMatch(line);
    return m != null ? _parseAmount(m.group(1)!) : null;
  }

  static double? _parseAmount(String s) {
    // Turkish format: 1.234,56 → handle both . and , as decimal
    String normalized = s;
    if (s.contains(',') && s.contains('.')) {
      // e.g., "1.234,56" → period is thousands sep, comma is decimal
      normalized = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Either "1234,56" or "1234.56"
      normalized = s.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }

  static DateTime? _buildDate(String d, String m, String y) {
    final day = int.tryParse(d);
    final month = int.tryParse(m);
    final year = int.tryParse(y);
    if (day == null || month == null || year == null) return null;
    if (day < 1 || day > 31 || month < 1 || month > 12) return null;
    return DateTime(year, month, day);
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  static String _cleanItemName(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[*]+$'), '')
        .trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT MODEL
// ═══════════════════════════════════════════════════════════════════════════

class ParsedReceipt {
  final ReceiptType receiptType;
  final String? merchantName;
  final double? total;
  final DateTime? date;
  final TimeOfDay? time;
  final String? accountHint;
  final List<ReceiptItem> items;
  final String rawText;

  // Fuel-specific
  final double? fuelLiters;
  final String? fuelType;
  final String? vehiclePlate;

  const ParsedReceipt({
    required this.receiptType,
    this.merchantName,
    this.total,
    this.date,
    this.time,
    this.accountHint,
    required this.items,
    required this.rawText,
    this.fuelLiters,
    this.fuelType,
    this.vehiclePlate,
  });

  bool get isFuel     => receiptType == ReceiptType.fuel;
  bool get isMarket   => receiptType == ReceiptType.market;
  bool get hasItems   => items.isNotEmpty;
  bool get hasTotal   => total != null && total! > 0;
}
