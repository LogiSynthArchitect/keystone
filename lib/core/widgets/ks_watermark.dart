import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';

/// Places a subtle Art Deco Sunburst watermark behind [child].
/// The pattern is rendered as a single centered emblem at low opacity.
class KsWatermark extends StatelessWidget {
  final Widget child;
  final double opacity;

  const KsWatermark({
    super.key,
    required this.child,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SunburstPainter(
        color: context.ksc.accent500,
        opacity: opacity,
      ),
      child: child,
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _SunburstPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.38;

    // Concentric arcs (upper half only — sits behind content)
    for (int i = 0; i < 3; i++) {
      final radius = r * (0.5 + i * 0.25);
      paint.strokeWidth = 0.6 - i * 0.15;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -3.14, // start at left
        3.14, // draw upper half only
        false,
        paint,
      );
    }

    // Sunburst rays radiating from center
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * 3.14159 / 180;
      final innerR = r * 0.15;
      final outerR = r * 0.95;
      canvas.drawLine(
        Offset(cx + innerR * cos(angle), cy + innerR * sin(angle)),
        Offset(cx + outerR * cos(angle), cy + outerR * sin(angle)),
        paint,
      );
    }

    // Small circle at center
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 0;
    canvas.drawCircle(Offset(cx, cy), r * 0.08, paint);

    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), r * 0.05, paint);
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.color != color || old.opacity != opacity;
}
