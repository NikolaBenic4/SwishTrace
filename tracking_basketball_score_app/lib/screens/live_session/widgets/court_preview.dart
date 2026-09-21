import 'package:flutter/material.dart';

class CourtPreview extends StatelessWidget {
  const CourtPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CourtPainter());
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final floor = Paint()..color = const Color(0xFFBA6B32);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, floor);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.24, 0, size.width * 0.52, size.height * 0.2),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.24, 0, size.width * 0.52, size.height * 0.2),
      line,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.28), 72, line);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.05),
        radius: size.width * 0.42,
      ),
      0,
      3.14,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
