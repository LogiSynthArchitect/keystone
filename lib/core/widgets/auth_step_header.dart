import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';

/// Compact inline step header for auth screens.
///
/// Renders a 60px ring with arc-segment progress, center icon,
/// "STEP X/N" label, step title, and sub-step dot indicators.
///
/// Same philosophy as [KsStepDrawer]'s ring but optimized for
/// full-page scaffold use (not modal bottom sheets).
class AuthStepHeader extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final int subStep;
  final int subSteps;
  final IconData icon;
  final String stepLabel;

  const AuthStepHeader({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.subStep = 0,
    this.subSteps = 1,
    required this.icon,
    required this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ksc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 60px ring with arc segments
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(60, 60),
                painter: _AuthRingPainter(
                  currentStep: currentStep,
                  totalSteps: totalSteps,
                  accentColor: colors.accent500,
                  mutedColor: colors.primary700,
                ),
              ),
              Center(
                child: Icon(icon, size: 22, color: colors.accent500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // "STEP 1/4" label
        Text(
          'STEP ${currentStep + 1}/$totalSteps',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: colors.accent500,
          ),
        ),
        const SizedBox(height: 2),
        // Step title
        Text(
          stepLabel,
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.white,
          ),
        ),
        // Sub-step dots (when subSteps > 1)
        if (subSteps > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(subSteps, (i) {
              final isActive = i <= subStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: isActive ? 14 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? colors.accent500
                      : colors.primary700,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
        // Fake main-step dots below sub-step dots
        if (totalSteps > 1 && subSteps <= 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalSteps, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: i == currentStep ? 14 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: i <= currentStep
                      ? colors.accent500
                      : colors.primary700,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the 60px auth step ring.
class _AuthRingPainter extends CustomPainter {
  final int currentStep;
  final int totalSteps;
  final Color accentColor;
  final Color mutedColor;

  _AuthRingPainter({
    required this.currentStep,
    required this.totalSteps,
    required this.accentColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSteps < 2) {
      // Draw simple full circle in muted
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = mutedColor;
      canvas.drawCircle(const Offset(30, 30), 24, paint);
      return;
    }

    const center = Offset(30, 30);
    const radius = 24.0;
    const strokeWidth = 4.0;

    final segmentAngle = (2 * pi) / totalSteps;
    const startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < totalSteps; i++) {
      final segStart = startAngle + i * segmentAngle;
      paint.color = i <= currentStep ? accentColor : mutedColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segStart,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AuthRingPainter old) =>
      old.currentStep != currentStep || old.totalSteps != totalSteps;
}
