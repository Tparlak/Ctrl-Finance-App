import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_item.dart';

/// V6 AI OCR Pipeline — dual-mode: Fuel Receipt vs Market/Grocery Receipt.
class OcrResult {
  final String rawText;
  final double? amount;
  final DateTime? date;
  final TimeOfDay? time;
  final String? merchantName;
  final String? accountHint;
  final String? categoryHint;
  final List<ReceiptItem> items;

  const OcrResult({
    required this.rawText,
    this.amount,
    this.date,
    this.time,
    this.merchantName,
    this.accountHint,
    this.categoryHint,
    this.items = const [],
  });
}

/// Receipt type returned by the detection step.
enum _ReceiptType { fuel, market }

class OcrService {
  static TextRecognizer? _recognizer;

  static Future<OcrResult> scanImage(String imagePath) async {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer!.processImage(inputImage);
    final text = recognized.text;

    final type = _detectReceiptType(text);

    if (type == _ReceiptType.fuel) {
      return _parseFuelReceipt(text);
    } else {
      return _parseMarketReceipt(text);
    }
  }

  // ── DETECTION ──────────────────────────────────────────────────────────────

  static _ReceiptType _detectReceiptType(String text) {
    final upper = text.toUpperCase();
    const fuelKeywords = [
      'LITRE', 'LT ', 'MOTORIN', 'BENZIN', 'DİZEL', 'DIZEL',
      'YAKIT', 'YAKIT FİŞİ', 'PETROL', 'LPG', 'FUEL', 'POMPA',
      // Fuel station brands
      'OPET', 'SHELL', 'BP ', ' BP', 'TOTAL', 'PETROL OFİSİ', 'PETROL OFİS',
      'ALPET', 'LUKOIL', 'TP ', 'TÜPRAŞ', 'TUPRAS',
    ];
    for (final kw in fuelKeywords) {
      if (upper.contains(kw)) return _ReceiptType.fuel;
    }
    // Market chain brands
    const marketKeywords = [
      'BİM', 'A101', 'S0K', 'SOK', 'MIGROS', 'CARREFOUR',
      'ŞOK', 'IMECE', 'HAKMAR', 'METRO', 'MACRO', 'TEKNOSA',
      'URUN', 'ÜRÜN', 'ADET', 'KG ',
    ];
    for (final kw in marketKeywords) {
      if (upper.contains(kw)) return _ReceiptType.market;
    }
    return _ReceiptType.market;
  }

  // ── FUEL RECEIPT PARSER ────────────────────────────────────────────────────

  static OcrResult _parseFuelReceipt(String text) {
    final upper = text.toUpperCase();

    // Detect fuel type
    String fuelType = 'Yakıt';
    if (upper.contains('MOTORIN') || upper.contains('DİZEL') || upper.contains('DIZEL')) {
      fuelType = 'Motorin';
    } else if (upper.contains('BENZIN') || upper.contains('BENZİN')) {
      fuelType = 'Benzin';
    } else if (upper.contains('LPG')) {
      fuelType = 'LPG';
    }

    // Extract liters: look for patterns like "32.50 LT" or "LITRE 32,50"
    double? liters;
    final literRegex = RegExp(
      r'(\d{1,4}[.,]\d{1,3})\s*(?:LT|LITRE|LİTRE)',
      caseSensitive: false,
    );
    final literMatch = literRegex.firstMatch(text);
    if (literMatch != null) {
      liters = _parseAmount(literMatch.group(1)!);
    }

    // Extract unit price: price per liter
    double? unitPrice;
    final unitPriceRegex = RegExp(
      r'(?:BİRİM\s*FİYAT|LITRE\s*FİYAT|FİYAT)[^\d]*(\d{1,3}[.,]\d{2,4})',
      caseSensitive: false,
    );
    final upMatch = unitPriceRegex.firstMatch(text);
    if (upMatch != null) {
      unitPrice = _parseAmount(upMatch.group(1)!);
    }

    // Extract total
    final total = _extractTotal(text);

    // Build auto description
    String description;
    if (liters != null) {
      description = '$fuelType: ${liters.toStringAsFixed(2).replaceAll('.', ',')}L';
      if (unitPrice != null) {
        description += ' @ ${unitPrice.toStringAsFixed(4).replaceAll('.', ',')} ₺/L';
      }
    } else {
      description = fuelType;
    }

    return OcrResult(
      rawText: text,
      amount: total,
      date: _extractDate(text),
      time: _extractTime(text),
      merchantName: description,
      accountHint: _extractAccountHint(text),
      categoryHint: 'Yakıt',
      items: [], // Fuel receipts don't need line items
    );
  }

  // ── MARKET RECEIPT PARSER ─────────────────────────────────────────────────

  static OcrResult _parseMarketReceipt(String text) {
    return OcrResult(
      rawText: text,
      amount: _extractTotal(text),
      date: _extractDate(text),
      time: _extractTime(text),
      merchantName: _extractMerchant(text),
      accountHint: _extractAccountHint(text),
      categoryHint: 'Market',
      items: _extractMarketLineItems(text),
    );
  }

  // ── TOTAL ─────────────────────────────────────────────────────────────────

  static double? _extractTotal(String text) {
    // Primary: search every TOPLAM *price occurrence — first valid one wins.
    // This avoids confusing the KDV tax block at the bottom of Turkish receipts.
    final toplam = RegExp(
      r'TOPLAM\s*[*]?\s*(\d{1,6}[.,]\d{2})',
      caseSensitive: false,
    );
    for (final m in toplam.allMatches(text)) {
      final val = _parseAmount(m.group(1)!);
      if (val != null && val > 0) return val;
    }

    // Second chance: broader TUTAR / GENEL TOP label
    final broader = RegExp(
      r'(?:TUTAR|GENEL\s*TOP|TOP\.)[^\d]*(\d{1,6}[.,]\d{2})',
      caseSensitive: false,
    );
    final m2 = broader.firstMatch(text);
    if (m2 != null) {
      final val = _parseAmount(m2.group(1)!);
      if (val != null && val > 0) return val;
    }

    // Last resort: largest number in receipt
    final all = RegExp(r'\b\d{1,6}[.,]\d{2}\b')
        .allMatches(text)
        .map((m) => _parseAmount(m.group(0)!) ?? 0.0)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return all.isNotEmpty ? all.first : null;
  }

  // ── DATE ──────────────────────────────────────────────────────────────────

  static DateTime? _extractDate(String text) {
    final r = RegExp(
      r'(?:TARIH|TARİH|DATE)?[^\w\d]*(\d{2})[./-](\d{2})[./-](\d{2,4})',
      caseSensitive: false,
    );
    for (final m in r.allMatches(text)) {
      try {
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        int year = int.parse(m.group(3)!);
        if (year < 100) year += 2000;
        if (day > 0 && day <= 31 && month > 0 && month <= 12) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }
    return null;
  }

  // ── TIME ──────────────────────────────────────────────────────────────────

  static TimeOfDay? _extractTime(String text) {
    final r = RegExp(r'(?:SAAT|TIME)?[^\w\d]*(\d{2})[:](\d{2})', caseSensitive: false);
    for (final m in r.allMatches(text)) {
      final h = int.tryParse(m.group(1)!);
      final min = int.tryParse(m.group(2)!);
      if (h != null && min != null && h <= 23 && min <= 59) {
        return TimeOfDay(hour: h, minute: min);
      }
    }
    return null;
  }

  // ── MERCHANT ─────────────────────────────────────────────────────────────

  static String _extractMerchant(String text) {
    // Skip common receipt noise on the first lines of Turkish receipts:
    // "*TEŞEKKÜR EDERİZ*", website URLs, and lines starting with *.
    final skipPattern = RegExp(
      r'TE[ŞS]EKK[ÜU]R|TESEKKUR|WWW\.|HTTP|^\*',
      caseSensitive: false,
    );
    final candidates = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3)
        .take(5);
    for (final line in candidates) {
      if (!skipPattern.hasMatch(line)) return line;
    }
    return 'Market Alışverişi';
  }

  // ── ACCOUNT HINT ─────────────────────────────────────────────────────────

  static String? _extractAccountHint(String text) {
    const banks = [
      'AKBANK', 'GARANTİ', 'GARANTI', 'ZİRAAT', 'ZIRAAT',
      'HALKBANK', 'VAKIFBANK', 'İŞBANKASI', 'ISBANKASI',
      'YAPI KREDİ', 'YAPI KREDI', 'QNB', 'NAKIT', 'NAKİT',
    ];
    final upper = text.toUpperCase();
    return banks.firstWhere((b) => upper.contains(b), orElse: () => '');
  }

  // ── MARKET LINE ITEMS ─────────────────────────────────────────────────────

  /// Strict noise filter for market receipts.
  static final _noiseRegex = RegExp(
    r'KDV|FIS\s*NO|FİŞ\s*NO|Z\s*NO|MERSIS|MERSİS|TOPLAM|TUTAR|KASA|'
    r'KASIYER|TEŞEKKÜR|TESEKKUR|PARA|TAKSİT|TAKSIT|VERGİ|'
    r'FATURA|TEL:|GSM:|TARİH|TARIH|SAAT|MAKBUZ|EFT|POS|'
    r'BANKA|KART|IADE|VERGİ\s*NO|VN:',
    caseSensitive: false,
  );

  static List<ReceiptItem> _extractMarketLineItems(String text) {
    final items = <ReceiptItem>[];
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    for (final line in lines) {
      if (_noiseRegex.hasMatch(line)) continue;
      if (line.length < 5) continue;

      // ── Pattern 1 (Turkish grocery format): "NAME %TaxRate *Price"
      // e.g. "KENT SWITCH %00 *105,00"  or  "DURU BAK. BULGUR 1 %01 *64,95"
      final trPattern = RegExp(
        r'^([A-ZÇĞİÖŞÜa-zçğışöü0-9\s./%&\-]{2,45}?)\s+%\d{1,2}\s+[*](\d{1,6}[.,]\d{2})',
        caseSensitive: false,
      );
      final trm = trPattern.firstMatch(line);
      if (trm != null) {
        final name  = trm.group(1)!.trim();
        final price = _parseAmount(trm.group(2)!);
        if (price != null && price > 0 && name.length >= 2 && !_noiseRegex.hasMatch(name)) {
          items.add(ReceiptItem(name: name, price: price));
          continue;
        }
      }

      // ── Pattern 2: "Product Name  Qty x UnitPrice"
      // e.g. "SÜTTE ÖMER 2x 34,90  69,80"
      final qtyPattern = RegExp(
        r'^(.+?)\s+(\d{1,3})[xX]\s*(\d{1,5}[.,]\d{2})',
      );
      final qm = qtyPattern.firstMatch(line);
      if (qm != null) {
        final name  = qm.group(1)!.trim();
        final qty   = int.tryParse(qm.group(2)!) ?? 1;
        final unitP = _parseAmount(qm.group(3)!);
        if (unitP != null && unitP > 0 && name.length >= 3) {
          items.add(ReceiptItem(name: name, price: unitP * qty));
          continue;
        }
      }

      // ── Pattern 3 (plain fallback): "Product Name  34,90" or "… 102,27 TL"
      final plainPattern = RegExp(
        r'^([A-ZÇĞİÖŞÜa-zçğışöü0-9\s./%&-]{2,40}?)\s+[*]?(\d{1,6}[.,]\d{2})(?:\s*TL|\s*₺|\s|%|$)',
        caseSensitive: false,
      );
      final pm = plainPattern.firstMatch(line);
      if (pm != null) {
        final name  = pm.group(1)!.trim();
        final price = _parseAmount(pm.group(2)!);
        if (price != null && price > 0 && name.length >= 2 && !_noiseRegex.hasMatch(name)) {
          items.add(ReceiptItem(name: name, price: price));
        }
      }
    }

    return items;
  }

  static double? _parseAmount(String s) =>
      double.tryParse(s.replaceAll(',', '.'));

  static void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
