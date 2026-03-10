import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KsLogo extends StatelessWidget {
  final double size;
  const KsLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- ARCH (navy) ---
    final archPaint = Paint()
      ..color = AppColors.primary700
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round;

    final archPath = Path();
    // left leg bottom
    archPath.moveTo(w * 0.18, h * 0.88);
    // curve up and over
    archPath.cubicTo(
      w * 0.18, h * 0.40,
      w * 0.38, h * 0.10,
      w * 0.50, h * 0.10,
    );
    archPath.cubicTo(
      w * 0.62, h * 0.10,
      w * 0.82, h * 0.40,
      w * 0.82, h * 0.88,
    );
    canvas.drawPath(archPath, archPaint);

    // --- KEYSTONE BLOCK (gold trapezoid) ---
    final goldPaint = Paint()
      ..color = const Color(0xFFF9A825)
      ..style = PaintingStyle.fill;

    final trapPath = Path();
    trapPath.moveTo(w * 0.38, h * 0.08); // top left
    trapPath.lineTo(w * 0.62, h * 0.08); // top right
    trapPath.lineTo(w * 0.57, h * 0.32); // bottom right
    trapPath.lineTo(w * 0.43, h * 0.32); // bottom left
    trapPath.close();
    canvas.drawPath(trapPath, goldPaint);

    // --- KEYHOLE (navy) ---
    final holePaint = Paint()
      ..color = AppColors.primary700
      ..style = PaintingStyle.fill;

    // circle top
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.15),
      w * 0.055,
      holePaint,
    );

    // rectangle bottom
    final rectPath = Path();
    rectPath.moveTo(w * 0.465, h * 0.17);
    rectPath.lineTo(w * 0.535, h * 0.17);
    rectPath.lineTo(w * 0.535, h * 0.28);
    rectPath.lineTo(w * 0.465, h * 0.28);
    rectPath.close();
    canvas.drawPath(rectPath, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
