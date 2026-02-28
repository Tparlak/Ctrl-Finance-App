import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text;

    return OcrResult(
      rawText: text,
      amount: _extractAmount(text),
      description: _extractDescription(text),
    );
  }

  double? _extractAmount(String text) {
    // Priority 1: Look near TOPLAM / TUTAR / TOP.
    final keywords = RegExp(
      r'(?:TOPLAM|TUTAR|TOP\.|GENEL TOPLAM)[^\d]*(\d{1,6}[.,]\d{2})',
      caseSensitive: false,
    );
    final match = keywords.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '.'));
    }

    // Priority 2: Find the largest currency number in text
    final allNumbers = RegExp(r'\b\d{1,6}[.,]\d{2}\b')
        .allMatches(text)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')) ?? 0.0)
        .toList();

    if (allNumbers.isEmpty) return null;
    allNumbers.sort((a, b) => b.compareTo(a));
    return allNumbers.first;
  }

  String? _extractDescription(String text) {
    // Return first non-empty line as description hint
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return lines.isNotEmpty ? lines.first : null;
  }

  void dispose() => _recognizer.close();
}

class OcrResult {
  final String rawText;
  final double? amount;
  final String? description;
  const OcrResult({required this.rawText, this.amount, this.description});
}
