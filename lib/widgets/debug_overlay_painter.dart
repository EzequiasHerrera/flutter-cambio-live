import 'package:flutter/material.dart';

class DebugOverlayPainter extends CustomPainter {
  final List<({String text, Rect rect})> detections;
  final double scale;
  final double offsetX;
  final double offsetY;

  DebugOverlayPainter(this.detections, {
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var detection in detections) {
      // Aplicamos la transformación geométrica para que el recuadro coincida
      final Rect adjustedRect = Rect.fromLTRB(
        (detection.rect.left * scale) - offsetX,
        (detection.rect.top * scale) - offsetY,
        (detection.rect.right * scale) - offsetX,
        (detection.rect.bottom * scale) - offsetY,
      );

      // Dibujamos el recuadro
      canvas.drawRect(adjustedRect, paint);

      // Dibujamos el texto encima
      final textSpan = TextSpan(
        text: detection.text,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, adjustedRect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant DebugOverlayPainter oldDelegate) => true;
}