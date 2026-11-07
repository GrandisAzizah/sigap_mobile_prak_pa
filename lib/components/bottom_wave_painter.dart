import 'package:flutter/material.dart';

class BottomWavePainter extends CustomPainter {
  const BottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final firstPaint = Paint()..color = const Color(0xFFE7DFFF);
    final firstPath = Path()
      ..moveTo(0, size.height * 0.30)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.40,
        size.height * 0.85,
        size.width * 0.62,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.42,
        size.width * 0.87,
        size.height * 0.12,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(firstPath, firstPaint);

    final secondPaint = Paint()..color = const Color(0xFFD7C9FF);
    final secondPath = Path()
      ..moveTo(0, size.height * 0.30)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.25,
        size.width * 0.32,
        size.height * 0.72,
        size.width * 0.55,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
