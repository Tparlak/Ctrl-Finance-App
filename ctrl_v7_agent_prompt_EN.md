# CTRL FINANCE APP — v7.1 TURKISH RECEIPT OCR ENGINE
## For: Antigravity IDE Autonomous Agent
## Target Repo: https://github.com/Tparlak/Ctrl-Finance-App
## Builds on: v6.2 (Phases 1-18 assumed complete)
## Problem: OCR reads Turkish market/fuel receipts but extracts wrong/missing data
## Solution: Complete rewrite of OcrService with Turkish fiscal receipt intelligence
## v7.1 additions: Turkish character normalization, confidence filtering, manual correction UI, multi-receipt

---

## ⚠️ AGENT PRIME DIRECTIVES — PHASE 19

1. **Read `lib/data/services/ocr_service.dart` completely before touching it.**
2. **Read `lib/data/models/receipt_item.dart` and `lib/presentation/widgets/add_transaction_sheet.dart`.**
3. **This is a full replacement** of the existing OcrService logic — not a patch.
4. **No new Hive models** — ReceiptItem already exists from Phase 7.
5. **No new packages** — google_mlkit_text_recognition and image already in pubspec.
6. **Image preprocessing** is added using Flutter's `dart:ui` + `image` package.
   - Check if `image` package is already in pubspec. If not, add `image: ^4.2.0`.
7. **Zero regressions** — all existing fields (amount, date, time, merchant, accountHint) must still be populated.
8. `flutter analyze` must show zero errors after completion.

---

## ROOT CAUSE ANALYSIS — WHY CURRENT OCR FAILS ON TURKISH RECEIPTS

Before writing code, understand exactly what is broken and why:

### Problem 1 — Image Quality & Orientation
Turkish thermal receipts (80mm paper) are:
- Narrow and tall (aspect ratio ~1:8)
- Low contrast (grey text on white thermal paper)
- Often photographed at an angle
- ML Kit receives a raw camera JPEG with no preprocessing → recognition rate drops 40-60%

**Fix:** Preprocess the image before passing to ML Kit:
- Convert to grayscale
- Increase contrast (threshold binarization)
- Auto-rotate using EXIF metadata
- Crop to content area

### Problem 2 — Turkish Fiscal Receipt Structure Is NOT Generic
The existing regex assumes generic patterns. Real Turkish receipts have a **very specific layout**:

```
┌─────────────────────────────────┐
│  ŞOK MARKETLER T.A.Ş.           │  ← line 1: merchant name (CAPS)
│  GEBZE / KOCAELİ                │  ← line 2: city
│  VKN: 1234567890                │  ← VKN = tax number (always present)
│  ─────────────────────────────  │
│  NORMAL EKMEK          *1       │  ← item: name + qty (* prefix)
│       6,50  %1    0,06          │  ← price + KDV rate + KDV amount
│  SÜT 1LT               *2       │
│      37,80  %1    0,37          │
│  ─────────────────────────────  │
│  TOPLAM KDV            0,43     │  ← NOT the total — this is VAT only
│  ─────────────────────────────  │
│  TOPKDV        ****   0,43      │  ← alternate KDV format
│  ARA TOPLAM           44,30     │  ← subtotal (not always present)
│  TOPLAM               44,30     │  ← THE REAL TOTAL ← what we want
│  ─────────────────────────────  │
│  NAKİT                50,00     │  ← payment method + amount paid
│  PARA ÜSTÜ             5,70     │  ← change given
│  ─────────────────────────────  │
│  ONAY KODU:   123456            │  ← approval code (card payments)
│  TARİH: 02/03/2026  14:38       │  ← date + time on SAME LINE
│  FİŞ NO: 000123                 │
│  EKÜ NO: 000456                 │
│  Z NO: 0089                     │
│  ─────────────────────────────  │
│  * * * F İ Ş * * *             │  ← fiscal receipt marker
└─────────────────────────────────┘
```

### Problem 3 — Amount Extraction Picks Wrong Number
Current regex finds `TOPLAM KDV` (which is ONLY the VAT amount) instead of `TOPLAM` (the grand total).
- `TOPLAM KDV: 0,43` ← WRONG — this is VAT, not total
- `TOPLAM: 44,30` ← CORRECT — this is what we want
- `NAKİT: 50,00` ← WRONG — this is cash tendered
- `PARA ÜSTÜ: 5,70` ← WRONG — this is change

### Problem 4 — Date/Time on Same Line
Turkish receipts often print: `TARİH: 02/03/2026  14:38`
Current regex uses separate date and time patterns that miss this combined format.

### Problem 5 — Item Line Format
Turkish items use comma as decimal separator and asterisk for quantity:
```
NORMAL EKMEK           *1
      6,50  %1    0,06
```
The item name and price are on **different lines** — current single-line regex misses this completely.

### Problem 6 — Fuel Receipt Is Completely Different Format
```
┌─────────────────────────────────┐
│  OPET PETROLCÜLÜK A.Ş.          │
│  GEBZE OTO AKARYAKIT            │
│  ─────────────────────────────  │
│  ARAÇ PLAKA: 41 XX 000          │  ← vehicle plate
│  ─────────────────────────────  │
│  MOTORIN                        │  ← fuel type
│  MİKTAR(LT): 45,23              │  ← liters
│  BİRİM FİYAT: 42,89             │  ← price per liter
│  TUTAR: 1.940,78                │  ← TOTAL (TUTAR not TOPLAM)
│  ─────────────────────────────  │
│  KDV (%18): 295,88              │
│  ─────────────────────────────  │
│  ÖDEME: KREDİ KARTI             │
│  ONAY KODU: 789012              │
│  TARİH: 02.03.2026  09:15       │
└─────────────────────────────────┘
```

---

## PHASE 19 — COMPLETE OCR SERVICE REWRITE

### 19A. Add image package if not present

Check pubspec.yaml:
```bash
grep "^  image:" pubspec.yaml
```

If not found, add:
```yaml
dependencies:
  image: ^4.2.0   # Bitmap preprocessing for OCR accuracy
```

Run: `flutter pub get`

### 19B. Image Preprocessing Pipeline

Create `lib/data/services/receipt_preprocessor.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Preprocesses a receipt image before OCR to maximize text recognition accuracy.
/// Pipeline: EXIF rotation → grayscale → contrast enhancement → binarization
class ReceiptPreprocessor {

  /// Returns a preprocessed image file path suitable for ML Kit.
  /// If preprocessing fails for any reason, returns the original path (safe fallback).
  static Future<String> preprocess(String originalPath) async {
    try {
      return await compute(_preprocessInBackground, originalPath);
    } catch (e) {
      debugPrint('ReceiptPreprocessor: failed, using original. Error: $e');
      return originalPath; // safe fallback — never crash
    }
  }

  /// Runs in a background isolate via compute()
  static Future<String> _preprocessInBackground(String path) async {
    final bytes = File(path).readAsBytesSync();

    // 1. Decode image (handles JPEG, PNG, etc.)
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return path;

    // 2. Auto-rotate based on EXIF orientation metadata
    image = img.bakeOrientation(image);

    // 3. Resize if too large (ML Kit optimal: max 4096px long edge)
    final maxDim = image.width > image.height ? image.width : image.height;
    if (maxDim > 3000) {
      final scale = 3000 / maxDim;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    // 4. Convert to grayscale
    image = img.grayscale(image);

    // 5. Increase contrast — stretch histogram
    image = img.adjustColor(image, contrast: 1.4, brightness: 1.05);

    // 6. Adaptive threshold binarization
    // Makes thermal receipt text sharply black on white
    image = _adaptiveThreshold(image);

    // 7. Write preprocessed image to temp file
    final dir = File(path).parent.path;
    final preprocessedPath = '$dir/preprocessed_receipt.jpg';
    File(preprocessedPath).writeAsBytesSync(
      img.encodeJpg(image, quality: 95),
    );

    return preprocessedPath;
  }

  /// Simple adaptive threshold: pixels darker than mean-C are set to black
  static img.Image _adaptiveThreshold(img.Image src) {
    final result = img.Image(width: src.width, height: src.height);
    const blockSize = 25; // neighborhood size
    const C = 10;         // constant subtracted from mean

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        // Calculate local mean in blockSize x blockSize neighborhood
        int sum = 0;
        int count = 0;
        for (int dy = -blockSize ~/ 2; dy <= blockSize ~/ 2; dy++) {
          for (int dx = -blockSize ~/ 2; dx <= blockSize ~/ 2; dx++) {
            final nx = (x + dx).clamp(0, src.width - 1);
            final ny = (y + dy).clamp(0, src.height - 1);
            sum += img.getRed(src.getPixel(nx, ny));
            count++;
          }
        }
        final mean = sum ~/ count;
        final pixelVal = img.getRed(src.getPixel(x, y));
        // If darker than local mean - C → black text
        final out = pixelVal < (mean - C) ? 0 : 255;
        result.setPixelRgba(x, y, out, out, out, 255);
      }
    }
    return result;
  }
}
```

### 19C. Turkish Receipt Parser

Create `lib/data/services/turkish_receipt_parser.dart`:

```dart
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
```

### 19D. Rewrite OcrService to Use New Pipeline

Replace the body of `lib/data/services/ocr_service.dart` completely:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_preprocessor.dart';
import 'turkish_receipt_parser.dart';
import '../models/receipt_item.dart';

/// Main entry point for receipt scanning.
/// Pipeline: Preprocess image → ML Kit OCR → Turkish parser → ParsedReceipt
class OcrService {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Scans a receipt image and returns a fully parsed result.
  ///
  /// [imagePath] - path to the original image from camera/gallery
  ///
  /// Never throws — all errors are caught and a safe empty result is returned.
  static Future<ParsedReceipt> scanReceipt(String imagePath) async {
    try {
      // Step 1: Preprocess image (grayscale + contrast + binarization)
      // If preprocessing fails, falls back to original path automatically
      final processedPath = await ReceiptPreprocessor.preprocess(imagePath);

      // Step 2: Run ML Kit text recognition
      final inputImage = InputImage.fromFilePath(processedPath);
      final recognized = await _recognizer.processImage(inputImage);
      final rawText = recognized.text;

      if (rawText.trim().isEmpty) {
        return ParsedReceipt(
          receiptType: ReceiptType.unknown,
          items: [],
          rawText: '',
        );
      }

      // Step 3: Parse using Turkish fiscal receipt intelligence
      return TurkishReceiptParser.parse(rawText);

    } catch (e, stack) {
      debugPrint('OcrService error: $e\n$stack');
      // Return empty result — never crash
      return ParsedReceipt(
        receiptType: ReceiptType.unknown,
        items: [],
        rawText: '',
      );
    }
  }

  static void dispose() => _recognizer.close();
}
```

### 19E. Update AddTransactionSheet to Handle New ParsedReceipt

Find the existing scan receipt handler in `add_transaction_sheet.dart`. Update it:

```dart
// In _scanReceipt() or equivalent method, replace the OcrResult handling:

Future<void> _performScan(ImageSource source) async {
  final photo = await ImagePicker().pickImage(
    source: source,
    imageQuality: 92,      // Higher quality for better OCR
    preferredCameraDevice: CameraDevice.rear,
  );
  if (photo == null) return;

  setState(() => _isScanning = true);

  try {
    final result = await OcrService.scanReceipt(photo.path);

    setState(() {
      _receiptImagePath = photo.path;
      _receiptItems = result.items;

      // Amount
      if (result.hasTotal) {
        _amountController.text = result.total!.toStringAsFixed(2);
      }

      // Date
      if (result.date != null) {
        _selectedDate = result.date!;
      }

      // Time
      if (result.time != null) {
        _selectedTime = result.time!;
      }

      // Description — prefer merchant name
      if (result.merchantName != null && result.merchantName!.isNotEmpty
          && _descController.text.isEmpty) {
        _descController.text = result.merchantName!;
      }

      // Account hint — try to match against existing accounts
      if (result.accountHint != null) {
        _tryAutoSelectAccount(result.accountHint!);
      }

      // Category suggestion based on receipt type
      _suggestCategoryFromReceiptType(result.receiptType);
    });

    // Show scan summary
    if (mounted) {
      _showScanResultSummary(result);
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fiş okunamadı: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  } finally {
    setState(() => _isScanning = false);
  }
}

/// Auto-suggest category based on detected receipt type
void _suggestCategoryFromReceiptType(ReceiptType type) {
  switch (type) {
    case ReceiptType.fuel:
      // Try to set category to YAKIT or ULAŞIM GİDERİ
      _trySuggestCategory('YAKIT');
      break;
    case ReceiptType.market:
      _trySuggestCategory('YEMEK / MARKET');
      break;
    case ReceiptType.restaurant:
      _trySuggestCategory('GIDA');
      break;
    case ReceiptType.utility:
      _trySuggestCategory('FATURA');
      break;
    case ReceiptType.unknown:
      break;
  }
}

void _trySuggestCategory(String categoryName) {
  // Find the category in existing categories list and set it
  // Implementation depends on how _selectedCategory is managed in the sheet
  // Look for a setState call that sets _selectedCategory
  final categories = context.read<CategoryProvider>().categories;
  final match = categories.firstWhere(
    (c) => c.name.toUpperCase() == categoryName.toUpperCase(),
    orElse: () => categories.first,
  );
  // Only auto-suggest, don't override user's selection if already set
  if (_selectedCategory == null || _selectedCategory!.isEmpty) {
    setState(() => _selectedCategory = match.name);
  }
}

/// Shows a brief non-intrusive result snackbar
void _showScanResultSummary(ParsedReceipt result) {
  final parts = <String>[];

  if (result.hasTotal) parts.add('${result.total!.toStringAsFixed(2)} ₺');
  if (result.hasItems) parts.add('${result.items.length} ürün');
  if (result.isFuel && result.fuelLiters != null) {
    parts.add('${result.fuelLiters!.toStringAsFixed(2)} lt');
  }

  final summary = parts.isEmpty ? 'Fiş okundu' : parts.join(' · ');
  final icon = result.isFuel ? '⛽' : '🧾';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$icon $summary'),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

### 19F. Update Mini Receipt Preview for Fuel Receipts

In the mini receipt display section of AddTransactionSheet, add fuel-specific display:

```dart
// In the receipt items section widget:
if (_receiptItems.isNotEmpty) ...[
  // existing items list widget — no change needed
] else if (_receiptImagePath != null && result?.isFuel == true) ...[
  // Fuel receipt: show summary instead of item list
  Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Text('⛽', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result?.fuelType != null)
                Text(result!.fuelType!, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (result?.fuelLiters != null)
                Text('${result!.fuelLiters!.toStringAsFixed(2)} lt',
                    style: const TextStyle(fontSize: 12)),
              if (result?.vehiclePlate != null)
                Text(result!.vehiclePlate!, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  ),
],
```

### 19G. Update Transaction Expanded View for Fuel Items

In the transaction history item (wherever `receiptItems` are displayed), add type-aware rendering:

```dart
// When displaying a transaction's receipt items:
if (transaction.receiptItems?.isNotEmpty == true)
  ExpansionTile(
    leading: Icon(
      _isFuelTransaction(transaction) ? Icons.local_gas_station : Icons.receipt_long,
      size: 18,
    ),
    title: Text(
      _isFuelTransaction(transaction)
        ? 'Yakıt Detayı'
        : 'Ürün Listesi (${transaction.receiptItems!.length})',
      style: const TextStyle(fontSize: 13),
    ),
    children: transaction.receiptItems!.map((item) => ListTile(
      dense: true,
      title: Text(item.name, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        '${item.price.toStringAsFixed(2)} ₺',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      subtitle: item.quantity != null && item.quantity! > 1
          ? Text('${item.quantity}x', style: const TextStyle(fontSize: 11))
          : null,
    )).toList(),
  ),
```

---

## PHASE 20 — IMAGE QUALITY GUIDE UI

Add a non-intrusive quality guide to the camera/gallery picker BottomSheet so users know how to take better photos:

```dart
// In _showScanOptions() BottomSheet, add after the two option tiles:

const Padding(
  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
  child: Text(
    '📸 İpucu: Fişi düz bir zemine koy, iyi aydınlık ortamda çek.',
    style: TextStyle(fontSize: 11, color: Colors.grey),
    textAlign: TextAlign.center,
  ),
),
const Padding(
  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
  child: Text(
    'Fiş mümkün olduğunca kamerayı dolduracak şekilde çerçevele.',
    style: TextStyle(fontSize: 11, color: Colors.grey),
    textAlign: TextAlign.center,
  ),
),
```

---

## PHASE 21 — OCR ACCURACY DEBUG MODE (Developer Only)

Add a hidden debug mode accessible from Ctrl Center (long press on version number):

```dart
// In ctrl_center_screen.dart — wrap version text:
GestureDetector(
  onLongPress: () => _showOcrDebugDialog(context),
  child: Text('Ctrl Finance v$version'),
),

void _showOcrDebugDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('🔬 OCR Debug'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Son fiş OCR çıktısı:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Consumer<OcrDebugProvider>(
            builder: (ctx, debug, _) => Container(
              height: 300,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  debug.lastRawOcrText ?? 'Henüz fiş taranmadı.',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
    ),
  );
}
```

Create a minimal `OcrDebugProvider`:

```dart
class OcrDebugProvider extends ChangeNotifier {
  String? _lastRawOcrText;
  String? get lastRawOcrText => _lastRawOcrText;

  void updateLastScan(String text) {
    _lastRawOcrText = text;
    notifyListeners();
  }
}
```

In `OcrService.scanReceipt()`, after getting `rawText`, call:
```dart
// In OcrService, inject provider via getter or pass as parameter:
// Simple approach: use a global static for debug only
OcrService._debugText = rawText; // store last scan text
```

Register `OcrDebugProvider` in MultiProvider.

---


---

## PHASE 22 — TURKISH CHARACTER OCR NORMALIZATION (CRITICAL MISSING FIX)

### Why This Is The #1 Root Cause of Wrong Data Extraction

Google ML Kit Latin script recognizer was trained primarily on Western European text. When it encounters Turkish thermal receipt text, it systematically misreads Turkish-specific characters:

```
ACTUAL RECEIPT TEXT    →    ML KIT OUTPUT (wrong)    →    EFFECT
─────────────────────────────────────────────────────────────────
TOPLAM       44,30     →    T0PLAM       44,30        →  regex fails (0 not O)
TARİH        14:38     →    TAR|H        14:38        →  date extraction fails
PARA ÜSTÜ     5,70     →    PARA USTU     5,70        →  exclusion regex misses it
NAKİT        50,00     →    NAK|T        50,00        →  payment method not detected
ŞOK MARKETLER         →    SOK MARKETLER             →  merchant name mangled
MOTORIN               →    M0T0RIN                   →  fuel type not detected
MİKTAR(LT): 45,23     →    M|KTAR(LT): 45,23         →  fuel liters not extracted
```

The fix is a **two-pass OCR normalization** applied to the raw ML Kit output text BEFORE it reaches the parser.

### 22A. Add `OcrTextNormalizer` to `ocr_service.dart`

Add this static class inside `lib/data/services/ocr_service.dart`:

```dart
/// Corrects systematic ML Kit misreadings of Turkish thermal receipt text.
/// Must be applied to rawText BEFORE passing to TurkishReceiptParser.
class OcrTextNormalizer {

  /// Full normalization pipeline. Call on raw ML Kit output.
  static String normalize(String raw) {
    String text = raw;
    text = _fixCommonOcrErrors(text);
    text = _fixTurkishSpecificPatterns(text);
    text = _fixNumberAmbiguities(text);
    text = _normalizeDecimalSeparators(text);
    text = _fixLineBreaks(text);
    return text;
  }

  // ── PASS 1: Common OCR character confusions ─────────────────────────────
  // These happen universally across all thermal receipt scanners
  static String _fixCommonOcrErrors(String text) {
    // The single most impactful fix: '0' (zero) confused with 'O' (letter)
    // Strategy: in ALL-CAPS context (Turkish receipts are all-caps),
    // zeros inside words are almost certainly the letter O
    // We fix known keywords explicitly rather than globally to avoid
    // breaking actual number values
    const keywordFixes = {
      // Amount-related keywords
      r'T0PLAM':      'TOPLAM',
      r'T0PL4M':      'TOPLAM',
      r'TOPKDV':      'TOPKDV',  // already correct — keep
      r'T0PKDV':      'TOPKDV',
      r'ARA\s*T0PLAM':'ARA TOPLAM',
      r'G[EE]NEL\s*T0PLAM': 'GENEL TOPLAM',
      r'TUT4R':       'TUTAR',
      r'T[U|Ü]TAR':   'TUTAR',

      // Date/time keywords
      r'TAR[|İI]H':   'TARİH',
      r'TAR1H':       'TARİH',
      r'SAAT':        'SAAT',

      // Payment keywords
      r'NAK[|İI]T':   'NAKİT',
      r'NAK1T':       'NAKİT',
      r'PARA\s*[ÜU]ST[ÜU]': 'PARA ÜSTÜ',
      r'PARA\s*UST[UÜ]': 'PARA ÜSTÜ',
      r'KRED[|İI]\s*KART': 'KREDİ KART',
      r'BANKA\s*KART': 'BANKA KARTI',
      r'0NAY':        'ONAY',
      r'ONAY\s*K0DU': 'ONAY KODU',

      // Receipt metadata keywords
      r'F[|İI][SŞ]\s*N0': 'FİŞ NO',
      r'EK[ÜU]\s*N0':     'EKÜ NO',
      r'Z\s*N0':           'Z NO',
      r'VKN\s*[;:]':       'VKN:',

      // Fuel keywords
      r'M[|İI]KTAR':       'MİKTAR',
      r'M0T0R[|İI]N':      'MOTORİN',
      r'MOTORIN':           'MOTORİN',  // missing İ
      r'B[|İI]R[|İI]M\s*F[|İI]YAT': 'BİRİM FİYAT',
      r'ARAC\s*PLAKA':     'ARAÇ PLAKA',
      r'YAKLIT':            'YAKIT',    // OCR sometimes adds extra L

      // Market-specific
      r'[*]\s*\*\s*\*\s*F\s*[|İI]\s*[SŞ]': '* * * FİŞ',
    };

    for (final entry in keywordFixes.entries) {
      text = text.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }
    return text;
  }

  // ── PASS 2: Turkish-specific character pattern fixes ────────────────────
  static String _fixTurkishSpecificPatterns(String text) {
    // Fix pipe character misread as İ or I (very common in Turkish)
    // "|" → "İ" only inside known Turkish word patterns
    text = text.replaceAll(RegExp(r'\bTAR\|H\b'), 'TARİH');
    text = text.replaceAll(RegExp(r'\bNAK\|T\b'), 'NAKİT');
    text = text.replaceAll(RegExp(r'\bM\|KTAR\b'), 'MİKTAR');
    text = text.replaceAll(RegExp(r'\bKRED\|\s*KART\b'), 'KREDİ KART');
    text = text.replaceAll(RegExp(r'\bB\|R\|M\b'), 'BİRİM');
    text = text.replaceAll(RegExp(r'\bF\|YAT\b'), 'FİYAT');
    text = text.replaceAll(RegExp(r'\bF\|[SŞ]\b'), 'FİŞ');

    // Fix 'l' (lowercase L) misread as '1' (one) in known keywords
    text = text.replaceAll(RegExp(r'\bTOP1AM\b', caseSensitive: false), 'TOPLAM');
    text = text.replaceAll(RegExp(r'\b1T\b'), 'LT');   // "1T" → "LT" (liters)
    text = text.replaceAll(RegExp(r'\bLT\)\s*:\s*'), 'LT): ');

    return text;
  }

  // ── PASS 3: Number/letter ambiguity in non-keyword positions ────────────
  // Only in clearly numeric contexts (after currency keywords, amount columns)
  static String _fixNumberAmbiguities(String text) {
    // Fix "O" (letter O) used instead of "0" (zero) in number sequences
    // Pattern: digits surrounding an O → it's a zero
    // e.g., "1O,50" → "10,50", "4O,OO" → "40,00"
    text = text.replaceAllMapped(
      RegExp(r'(\d)O(\d)'),
      (m) => '${m.group(1)}0${m.group(2)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d)O([,\.])'),
      (m) => '${m.group(1)}0${m.group(2)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'([,\.])O(\d)'),
      (m) => '${m.group(1)}0${m.group(2)}',
    );
    return text;
  }

  // ── PASS 4: Decimal separator normalization ──────────────────────────────
  // Turkish receipts use comma as decimal separator (44,30 not 44.30)
  // OCR sometimes produces periods instead of commas in amounts
  static String _normalizeDecimalSeparators(String text) {
    // Pattern: "44.30" where it's clearly a 2-decimal amount → "44,30"
    // Only normalize if the pattern matches a price (not a date or ID)
    text = text.replaceAllMapped(
      RegExp(r'\b(\d{1,5})\.(\d{2})\b(?!\d)'),
      (m) {
        final intPart = int.tryParse(m.group(1)!);
        // Don't convert if it looks like a year (2024, 2025, 2026)
        if (intPart != null && intPart >= 2000 && intPart <= 2099) {
          return m.group(0)!; // keep as-is (it's a year)
        }
        return '${m.group(1)},${m.group(2)}';
      },
    );
    return text;
  }

  // ── PASS 5: Line break normalization ─────────────────────────────────────
  // ML Kit sometimes merges two lines or splits one line incorrectly
  static String _fixLineBreaks(String text) {
    // Ensure keywords always start on their own line
    const lineStartKeywords = [
      'TOPLAM', 'TOPKDV', 'NAKİT', 'NAKIT', 'PARA ÜSTÜ',
      'TARİH', 'TARIH', 'FİŞ NO', 'EKÜ NO', 'Z NO',
      'TUTAR', 'MİKTAR', 'BİRİM FİYAT', 'ONAY KODU',
      'ARAÇ PLAKA', 'MOTORIN', 'BENZİN',
    ];
    for (final kw in lineStartKeywords) {
      // If keyword appears mid-line (not at start), force a newline before it
      text = text.replaceAll(
        RegExp(r'(?<=[^\n])(' + RegExp.escape(kw) + r')', caseSensitive: false),
        '\n$kw',
      );
    }
    return text;
  }
}
```

### 22B. Wire OcrTextNormalizer into OcrService

In `lib/data/services/ocr_service.dart`, in the `scanReceipt` method, add normalization between ML Kit output and parser:

```dart
// BEFORE (existing):
final rawText = recognized.text;
return TurkishReceiptParser.parse(rawText);

// AFTER (add normalization step):
final rawText = recognized.text;

// Store original for debug mode
OcrService._lastRawText = rawText;

// Normalize ML Kit OCR errors before parsing
final normalizedText = OcrTextNormalizer.normalize(rawText);

// Store normalized for debug mode (useful to see both)
OcrService._lastNormalizedText = normalizedText;

return TurkishReceiptParser.parse(normalizedText);
```

Add these static fields to `OcrService`:
```dart
static String? _lastRawText;
static String? _lastNormalizedText;
static String? get lastRawText => _lastRawText;
static String? get lastNormalizedText => _lastNormalizedText;
```

---

## PHASE 23 — OCR MANUAL CORRECTION BOTTOM SHEET

### Why This Is Essential

Even with the best preprocessing and parsing, OCR will sometimes misread a number or miss a field. A good UX doesn't hide this — it lets the user **see and fix** what was extracted, right inside the add-transaction flow.

### 23A. OcrReviewSheet Widget

Create `lib/presentation/widgets/ocr_review_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import '../../data/models/receipt_item.dart';
import '../../data/services/turkish_receipt_parser.dart';

/// A bottom sheet that shows OCR results with editable fields.
/// User can correct any wrong value before confirming.
/// Returns a corrected ParsedReceipt when confirmed.
class OcrReviewSheet extends StatefulWidget {
  final ParsedReceipt result;
  final VoidCallback onConfirm;

  const OcrReviewSheet({
    required this.result,
    required this.onConfirm,
    super.key,
  });

  static Future<ParsedReceipt?> show(
    BuildContext context,
    ParsedReceipt result,
  ) {
    return showModalBottomSheet<ParsedReceipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OcrReviewSheet(result: result, onConfirm: () {}),
    );
  }

  @override
  State<OcrReviewSheet> createState() => _OcrReviewSheetState();
}

class _OcrReviewSheetState extends State<OcrReviewSheet> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _timeCtrl;
  late List<ReceiptItem> _items;

  // Confidence indicators — show yellow warning for uncertain values
  bool _amountConfident = true;
  bool _merchantConfident = true;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _merchantCtrl = TextEditingController(text: r.merchantName ?? '');
    _amountCtrl   = TextEditingController(
      text: r.total != null ? r.total!.toStringAsFixed(2) : '',
    );
    _dateCtrl = TextEditingController(
      text: r.date != null
          ? '${r.date!.day.toString().padLeft(2,'0')}/'
            '${r.date!.month.toString().padLeft(2,'0')}/'
            '${r.date!.year}'
          : '',
    );
    _timeCtrl = TextEditingController(
      text: r.time != null
          ? '${r.time!.hour.toString().padLeft(2,'0')}:'
            '${r.time!.minute.toString().padLeft(2,'0')}'
          : '',
    );
    _items = List.from(r.items);

    // Flag uncertain values
    _amountConfident = r.hasTotal;
    _merchantConfident = r.merchantName != null && r.merchantName!.isNotEmpty;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + title ───────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                _receiptTypeIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Fiş Tarama Sonucu',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _receiptTypeLabel(),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Confidence badge
                if (!_amountConfident || !_merchantConfident)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '⚠️ Kontrol et',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Editable fields ──────────────────────────────────────────
            _buildField(
              label: 'Mağaza / Açıklama',
              controller: _merchantCtrl,
              icon: Icons.store_outlined,
              isWarning: !_merchantConfident,
              warningText: 'Mağaza adı okunamadı — elle girin',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    label: 'Tutar (₺)',
                    controller: _amountCtrl,
                    icon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isWarning: !_amountConfident,
                    warningText: 'Tutar doğrulanamadı',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    label: 'Tarih',
                    controller: _dateCtrl,
                    icon: Icons.calendar_today_outlined,
                    hint: 'GG/AA/YYYY',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    label: 'Saat',
                    controller: _timeCtrl,
                    icon: Icons.access_time_outlined,
                    hint: 'SS:DD',
                  ),
                ),
              ],
            ),

            // ── Fuel extras ───────────────────────────────────────────────
            if (widget.result.isFuel) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Text('⛽', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Wrap(
                        spacing: 16, runSpacing: 4,
                        children: [
                          if (widget.result.fuelType != null)
                            Text('${widget.result.fuelType}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (widget.result.fuelLiters != null)
                            Text('${widget.result.fuelLiters!.toStringAsFixed(2)} lt',
                                style: const TextStyle(fontSize: 13)),
                          if (widget.result.vehiclePlate != null)
                            Text(widget.result.vehiclePlate!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Items list (collapsible) ───────────────────────────────────
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildItemsSection(),
            ],

            const SizedBox(height: 20),

            // ── Action buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null), // discard
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _confirm,
                    child: const Text('✓ Kullan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isWarning = false,
    String? warningText,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWarning && warningText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '⚠️ $warningText',
              style: const TextStyle(fontSize: 10, color: Colors.orange),
            ),
          ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isWarning
                    ? Colors.orange.withValues(alpha: 0.6)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isWarning ? Colors.orange : Theme.of(context).colorScheme.primary,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📦 Ürünler (${_items.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => setState(() => _items.clear()),
              child: const Text('Temizle', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 8),
            itemBuilder: (_, i) {
              final item = _items[i];
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.quantity != null && item.quantity! > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  Text(
                    '${item.price.toStringAsFixed(2)} ₺',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () => setState(() => _items.removeAt(i)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirm() {
    // Parse the edited fields back into a ParsedReceipt
    final amount = double.tryParse(
      _amountCtrl.text.replaceAll(',', '.'),
    );

    DateTime? date;
    final dateParts = _dateCtrl.text.split('/');
    if (dateParts.length == 3) {
      date = DateTime(
        int.tryParse(dateParts[2]) ?? DateTime.now().year,
        int.tryParse(dateParts[1]) ?? 1,
        int.tryParse(dateParts[0]) ?? 1,
      );
    }

    TimeOfDay? time;
    final timeParts = _timeCtrl.text.split(':');
    if (timeParts.length == 2) {
      final h = int.tryParse(timeParts[0]);
      final m = int.tryParse(timeParts[1]);
      if (h != null && m != null) time = TimeOfDay(hour: h, minute: m);
    }

    final corrected = ParsedReceipt(
      receiptType: widget.result.receiptType,
      merchantName: _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim(),
      total: amount,
      date: date,
      time: time,
      accountHint: widget.result.accountHint,
      items: _items,
      rawText: widget.result.rawText,
      fuelLiters: widget.result.fuelLiters,
      fuelType: widget.result.fuelType,
      vehiclePlate: widget.result.vehiclePlate,
    );

    Navigator.pop(context, corrected);
  }

  Widget _receiptTypeIcon() {
    final (icon, color) = switch (widget.result.receiptType) {
      ReceiptType.fuel       => ('⛽', Colors.orange),
      ReceiptType.market     => ('🛒', Colors.green),
      ReceiptType.restaurant => ('🍽️', Colors.red),
      ReceiptType.utility    => ('⚡', Colors.blue),
      ReceiptType.unknown    => ('🧾', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 20)),
    );
  }

  String _receiptTypeLabel() {
    return switch (widget.result.receiptType) {
      ReceiptType.fuel       => 'Akaryakıt Fişi',
      ReceiptType.market     => 'Market Fişi',
      ReceiptType.restaurant => 'Restoran Fişi',
      ReceiptType.utility    => 'Fatura',
      ReceiptType.unknown    => 'Genel Fiş',
    };
  }
}
```

### 23B. Wire OcrReviewSheet into AddTransactionSheet

In `add_transaction_sheet.dart`, in the `_performScan` method, replace the direct field-filling with the review sheet:

```dart
// BEFORE (fills fields immediately after scan):
setState(() {
  if (result.hasTotal) _amountController.text = ...;
  // etc.
});

// AFTER (show review sheet first, apply only after user confirms):
final corrected = await showModalBottomSheet<ParsedReceipt>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => OcrReviewSheet(result: result, onConfirm: () {}),
);

if (corrected == null) return; // user dismissed — do nothing

// Apply the user-confirmed (possibly corrected) data:
setState(() {
  _receiptImagePath = photo.path;
  _receiptItems = corrected.items;

  if (corrected.total != null) {
    _amountController.text = corrected.total!.toStringAsFixed(2);
  }
  if (corrected.date != null) _selectedDate = corrected.date!;
  if (corrected.time != null) _selectedTime = corrected.time!;
  if (corrected.merchantName != null && corrected.merchantName!.isNotEmpty
      && _descController.text.isEmpty) {
    _descController.text = corrected.merchantName!;
  }
  if (corrected.accountHint != null) _tryAutoSelectAccount(corrected.accountHint!);
  _suggestCategoryFromReceiptType(corrected.receiptType);
});
```

---

## PHASE 24 — SMART SCAN BUTTON IN TRANSACTION LIST (Quick Re-Scan)

Add a "Fişi Yeniden Tara" option to the transaction detail/edit screen for existing transactions that have a receipt image attached. This allows the user to re-run the improved OCR on an old transaction.

In the transaction edit screen (wherever `transaction.receiptImagePath` is shown), add:

```dart
// If transaction has a receipt image but the amount seems wrong (user edited it),
// offer to re-scan:
if (transaction.receiptImagePath != null)
  TextButton.icon(
    icon: const Icon(Icons.document_scanner_outlined, size: 16),
    label: const Text('Fişi Yeniden Tara', style: TextStyle(fontSize: 13)),
    onPressed: () async {
      final result = await OcrService.scanReceipt(transaction.receiptImagePath!);
      if (!mounted) return;
      final corrected = await showModalBottomSheet<ParsedReceipt>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OcrReviewSheet(result: result, onConfirm: () {}),
      );
      if (corrected == null) return;
      setState(() {
        if (corrected.total != null) _amountCtrl.text = corrected.total!.toStringAsFixed(2);
        if (corrected.merchantName != null) _descCtrl.text = corrected.merchantName!;
        if (corrected.date != null) _selectedDate = corrected.date!;
      });
    },
  ),
```

---

## PHASE 25 — ENHANCED OCR DEBUG MODE UPDATE

Update Phase 21's debug dialog to show both raw and normalized text side by side, so you can see exactly what the normalizer fixed:

```dart
void _showOcrDebugDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('🔬 OCR Debug'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(tabs: [
                Tab(text: 'Ham ML Kit'),
                Tab(text: 'Normalleştirilmiş'),
              ]),
              Expanded(
                child: TabBarView(children: [
                  _DebugTextView(text: OcrService.lastRawText ?? 'Henüz tarama yok'),
                  _DebugTextView(text: OcrService.lastNormalizedText ?? 'Henüz tarama yok'),
                ]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
      ],
    ),
  );
}

class _DebugTextView extends StatelessWidget {
  final String text;
  const _DebugTextView({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    padding: const EdgeInsets.all(8),
    child: SingleChildScrollView(
      child: Text(text, style: const TextStyle(
        color: Colors.greenAccent, fontSize: 10, fontFamily: 'monospace',
      )),
    ),
  );
}
```


---

## FINAL BUILD SEQUENCE

```bash
# Update version
# pubspec.yaml: version: 7.1.0+71

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --release

ls -lh build/app/outputs/flutter-apk/
# Expected: Ctrl-v7.1.apk
```

---

## FINAL COMPLETION CHECKLIST — v7.1

| Item | Feature | Status |
|------|---------|--------|
| 19A | `image` package added (if not present) | ☐ |
| 19B | ReceiptPreprocessor — grayscale + contrast + binarization | ☐ |
| 19B | ReceiptPreprocessor — EXIF auto-rotation | ☐ |
| 19B | ReceiptPreprocessor — runs in background isolate | ☐ |
| 19C | TurkishReceiptParser — market receipt parser | ☐ |
| 19C | TurkishReceiptParser — fuel receipt parser | ☐ |
| 19C | TurkishReceiptParser — utility bill parser | ☐ |
| 19C | TurkishReceiptParser — TOPLAM vs TOPLAM KDV distinction | ☐ |
| 19C | TurkishReceiptParser — 2-line item format (name + price separate lines) | ☐ |
| 19C | TurkishReceiptParser — TARİH: DD/MM/YYYY HH:MM parsing | ☐ |
| 19C | TurkishReceiptParser — vehicle plate extraction | ☐ |
| 19D | OcrService — new pipeline wired | ☐ |
| 19E | AddTransactionSheet — category auto-suggestion | ☐ |
| 19F | Fuel receipt summary UI in add sheet | ☐ |
| 19G | Fuel-aware expanded transaction view | ☐ |
| 20  | Camera quality tips in picker BottomSheet | ☐ |
| 21  | OCR debug mode skeleton (long press version) | ☐ |
| 22A | OcrTextNormalizer — T0PLAM / TAR|H / NAK|T fixes | ☐ |
| 22A | OcrTextNormalizer — decimal separator normalization | ☐ |
| 22A | OcrTextNormalizer — line break recovery | ☐ |
| 22B | OcrTextNormalizer wired into OcrService pipeline | ☐ |
| 23A | OcrReviewSheet — editable merchant / amount / date / time | ☐ |
| 23A | OcrReviewSheet — fuel extras display | ☐ |
| 23A | OcrReviewSheet — items list with delete per item | ☐ |
| 23A | OcrReviewSheet — orange warning on uncertain fields | ☐ |
| 23B | OcrReviewSheet wired into AddTransactionSheet | ☐ |
| 24  | Re-scan button on existing transaction with receipt | ☐ |
| 25  | Debug dialog — Ham / Normalleştirilmiş tab view | ☐ |
| ✅  | ŞOK market receipt: correct total extracted | ☐ |
| ✅  | BİM receipt: correct total, items listed | ☐ |
| ✅  | OPET fuel: liters + fuel type + plate + total | ☐ |
| ✅  | OcrTextNormalizer fixes T0PLAM → TOPLAM | ☐ |
| ✅  | Review sheet shows on every scan before auto-fill | ☐ |
| ✅  | flutter analyze — zero errors | ☐ |
| ✅  | Release APK: Ctrl-v7.1.apk | ☐ |
