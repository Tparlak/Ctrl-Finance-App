import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_preprocessor.dart';
import 'turkish_receipt_parser.dart';
import 'ocr_text_normalizer.dart';

/// Main entry point for receipt scanning.
/// Pipeline: Preprocess image → ML Kit OCR → Normalize text → Turkish parser → ParsedReceipt
class OcrService {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static String? _lastRawText;
  static String? _lastNormalizedText;
  static String? get lastRawText => _lastRawText;
  static String? get lastNormalizedText => _lastNormalizedText;

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
      
      _lastRawText = rawText; // Store original for debug mode

      if (rawText.trim().isEmpty) {
        return const ParsedReceipt(
          receiptType: ReceiptType.unknown,
          items: [],
          rawText: '',
        );
      }

      // Step 3: Normalize ML Kit OCR errors before parsing
      final normalizedText = OcrTextNormalizer.normalize(rawText);
      _lastNormalizedText = normalizedText; // Store normalized for debug mode

      // Step 4: Parse using Turkish fiscal receipt intelligence
      return TurkishReceiptParser.parse(normalizedText);

    } catch (e, stack) {
      debugPrint('OcrService error: $e\n$stack');
      // Return empty result — never crash
      return const ParsedReceipt(
        receiptType: ReceiptType.unknown,
        items: [],
        rawText: '',
      );
    }
  }

  static void dispose() => _recognizer.close();
}
