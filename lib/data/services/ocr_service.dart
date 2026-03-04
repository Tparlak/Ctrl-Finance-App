import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_item.dart';

class OcrResult {
  final String rawText;
  final double? amount;
  final DateTime? date;
  final TimeOfDay? time;
  final String? merchantName;
  final String? accountHint;
  final List<ReceiptItem> items;

  const OcrResult({
    required this.rawText,
    this.amount,
    this.date,
    this.time,
    this.merchantName,
    this.accountHint,
    this.items = const [],
  });
}

class OcrService {
  static TextRecognizer? _recognizer;

  static Future<OcrResult> scanImage(String imagePath) async {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer!.processImage(inputImage);
    final text = recognized.text;

    return OcrResult(
      rawText: text,
      amount:       _extractTotal(text),
      date:         _extractDate(text),
      time:         _extractTime(text),
      merchantName: _extractMerchant(text),
      accountHint:  _extractAccountHint(text),
      items:        _extractLineItems(text),
    );
  }

  // ── TOTAL ────────────────────────────────────────────
  static double? _extractTotal(String text) {
    final r = RegExp(r'(?:TOPLAM|TUTAR|TOP\.)[^\d]*(\d{1,6}[.,]\d{2})', caseSensitive: false);
    final m = r.firstMatch(text);
    if (m != null) return _parseAmount(m.group(1)!);

    // Fallback: largest number in receipt
    final all = RegExp(r'\b\d{1,6}[.,]\d{2}\b')
        .allMatches(text)
        .map((m) => _parseAmount(m.group(0)!) ?? 0.0)
        .toList()..sort((a, b) => b.compareTo(a));
    return all.isNotEmpty ? all.first : null;
  }

  // ── DATE ─────────────────────────────────────────────
  static DateTime? _extractDate(String text) {
    final r = RegExp(r'(?:TARIH|TARİH|DATE)?[\s:]*(\d{2})[./-](\d{2})[./-](\d{4})', caseSensitive: false);
    final m = r.firstMatch(text);
    if (m == null) return null;
    try {
      return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
    } catch (_) { return null; }
  }

  // ── TIME ─────────────────────────────────────────────
  static TimeOfDay? _extractTime(String text) {
    final r = RegExp(r'(?:SAAT|TIME)?[\s:]*(\d{2}):(\d{2})', caseSensitive: false);
    final m = r.firstMatch(text);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final min = int.tryParse(m.group(2)!);
    if (h == null || min == null || h > 23 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  // ── MERCHANT ─────────────────────────────────────────
  static String? _extractMerchant(String text) {
    return text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 3)
        .firstOrNull;
  }

  // ── ACCOUNT HINT ─────────────────────────────────────
  static String? _extractAccountHint(String text) {
    const banks = ['AKBANK', 'GARANTİ', 'GARANTI', 'ZİRAAT', 'ZIRAAT',
                   'HALKBANK', 'VAKIFBANK', 'İŞBANKASI', 'ISBANKASI',
                   'YAPI KREDİ', 'YAPI KREDI', 'QNB', 'NAKIT', 'NAKİT'];
    final upper = text.toUpperCase();
    return banks.firstWhere((b) => upper.contains(b), orElse: () => '');
  }

  // ── LINE ITEMS ───────────────────────────────────────
  static List<ReceiptItem> _extractLineItems(String text) {
    final itemRegex = RegExp(
      r'^([A-ZÇĞİÖŞÜa-zçğışöüñ0-9\s./%-]{2,40}?)\s+\*?(\d{1,6}[.,]\d{2})\s*$',
      multiLine: true,
    );

    final skipKeywords = RegExp(
      r'TOPLAM|TUTAR|PARA|TAKSİT|KDV|VERGİ|FIŞ|SAAT|TARIH|KASA|KASIYER|TEŞEKKÜR',
      caseSensitive: false,
    );

    final items = <ReceiptItem>[];
    for (final match in itemRegex.allMatches(text)) {
      final name = match.group(1)!.trim();
      final price = _parseAmount(match.group(2)!);
      if (price != null && price > 0 && !skipKeywords.hasMatch(name)) {
        items.add(ReceiptItem(name: name, price: price));
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
