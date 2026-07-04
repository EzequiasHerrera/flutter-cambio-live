import 'package:flutter/material.dart';

enum BubbleDirection { left, right, bottom }

class BubbleDialog extends StatelessWidget {
  final String message;
  final BubbleDirection direction;

  const BubbleDialog({
    super.key,
    required this.message,
    this.direction = BubbleDirection.left,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (message.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _buildTriangle(),
      ],
    );
  }

  Widget _buildTriangle() {
    double? left, right, top, bottom;

    switch (direction) {
      case BubbleDirection.left:
        left = -10;
        top = 20;
        break;
      case BubbleDirection.right:
        right = -10;
        top = 20;
        break;
      case BubbleDirection.bottom:
        bottom = -10;
        left = 60;
        break;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: CustomPaint(
        painter: TrianglePainter(
          strokeColor: Colors.transparent,
          fillColor: Colors.white,
          strokeWidth: 0,
          direction: direction,
        ),
        size: const Size(12, 12),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final BubbleDirection direction;

  TrianglePainter({
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    switch (direction) {
      case BubbleDirection.left:
        path.moveTo(size.width, 0);
        path.lineTo(0, size.height / 2);
        path.lineTo(size.width, size.height);
        break;
      case BubbleDirection.right:
        path.moveTo(0, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(0, size.height);
        break;
      case BubbleDirection.bottom:
        path.moveTo(0, 0);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(size.width, 0);
        break;
    }
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    if (strokeWidth > 0 && strokeColor != Colors.transparent) {
      final strokePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
