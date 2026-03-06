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

    // 3. Resize if too large (ML Kit optimal: max 1500px long edge is highly performant and accurate)
    final maxDim = image.width > image.height ? image.width : image.height;
    if (maxDim > 1500) {
      final scale = 1500 / maxDim;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    // 4. Convert to grayscale
    image = img.grayscale(image);

    // 5. Increase contrast — stretch histogram slightly
    image = img.adjustColor(image, contrast: 1.3, brightness: 1.05);

    // Note: Removed adaptive thresholding because ML Kit's underlying 
    // neural networks actually perform better with antialiased grayscale 
    // text than crisp 1-bit binarized text, and it saves massive CPU time.

    // 6. Write preprocessed image to temp file
    final dir = File(path).parent.path;
    final preprocessedPath = '$dir/preprocessed_receipt.jpg';
    File(preprocessedPath).writeAsBytesSync(
      img.encodeJpg(image, quality: 90),
    );

    return preprocessedPath;
  }
}
