import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptImageViewer extends StatelessWidget {
  final String imagePath;
  const ReceiptImageViewer({required this.imagePath, super.key});

  static void show(BuildContext context, String imagePath) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity( 0.95),
      pageBuilder: (_, __, ___) => ReceiptImageViewer(imagePath: imagePath),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(File(imagePath)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity( 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

