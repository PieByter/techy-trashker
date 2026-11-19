import 'package:flutter/material.dart';

/// Subtle concentric-circle / magnifying-glass motif used across the design.
class EcoPattern extends StatelessWidget {
  const EcoPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.10,
    this.alignment = const Alignment(1.15, -1.15),
  });

  final Color color;
  final double opacity;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EcoPatternPainter(
          color: color.withValues(alpha: opacity),
          alignment: alignment,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EcoPatternPainter extends CustomPainter {
  _EcoPatternPainter({required this.color, required this.alignment});

  final Color color;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = alignment.alongSize(size);
    final base = size.shortestSide * 0.32;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, base * i, stroke);
    }

    // Magnifying-glass motif, echoing the search/explore visual in the design.
    final lensCenter = Offset(size.width * 0.12, size.height * 0.56);
    final lensRadius = size.shortestSide * 0.18;
    canvas.drawCircle(lensCenter, lensRadius, stroke);
    canvas.drawLine(
      lensCenter + Offset(lensRadius * 0.68, lensRadius * 0.68),
      lensCenter + Offset(lensRadius * 1.35, lensRadius * 1.35),
      stroke..strokeWidth = 2.4,
    );

    // A few small orbiting dots.
    final dot = Paint()..color = color;
    canvas.drawCircle(center + Offset(base * 0.8, -base * 1.6), 2.2, dot);
    canvas.drawCircle(center + Offset(-base * 1.7, base * 0.6), 1.8, dot);
    canvas.drawCircle(center + Offset(base * 2.2, base * 0.8), 1.5, dot);
  }

  @override
  bool shouldRepaint(covariant _EcoPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.alignment != alignment;
  }
}
