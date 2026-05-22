import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// Full-screen success confirmation.
///
/// Uses [showGeneralDialog] instead of [OverlayEntry] for reliable
/// lifecycle management. Completes only when the animation actually
/// finishes rendering.
class KsSuccessMoment extends StatefulWidget {
  final String title;
  final String? subtitle;

  const KsSuccessMoment({
    super.key,
    required this.title,
    this.subtitle,
  });

  /// Show and wait for the animation to complete (~1.8s).
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    // Overlay dims the screen — always dark regardless of theme.
    // Text on overlay must always be light for contrast.
    const overlayColor = Color(0xFF0C0C0E);
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: overlayColor.withValues(alpha: 0.85),
      barrierLabel: 'Success',
      pageBuilder: (ctx, _, __) => KsSuccessMoment(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<KsSuccessMoment> createState() => _KsSuccessMomentState();
}

class _KsSuccessMomentState extends State<KsSuccessMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _t = 1800;

  late final Animation<double> _overlayFade;
  late final Animation<double> _checkPop;
  late final Animation<double> _checkDraw;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _sparkleFade;

  static final _sparkleOffsets = List.generate(6, (_) => Offset(
    (Random().nextDouble() - 0.5) * 100,
    (Random().nextDouble() - 0.5) * 100,
  ));

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: _t));

    _overlayFade = _seq([
      [0.0, 1.0, 250],
      [1.0, 1.0, 1300],
      [1.0, 0.0, 250],
    ]);

    _checkPop = _seq([
      [0.0, 0.0, 300],
      [0.0, 1.0, 250, Curves.elasticOut],
      [1.0, 1.0, 1250],
    ]);

    _checkDraw = _seq([
      [0.0, 0.0, 500],
      [0.0, 1.0, 300],
      [1.0, 1.0, 1000],
    ]);

    _textFade = _seq([
      [0.0, 0.0, 700],
      [0.0, 1.0, 300],
      [1.0, 1.0, 800],
    ]);

    _textSlide = _seq([
      [16.0, 16.0, 700],
      [16.0, 0.0, 300, Curves.easeOutCubic],
      [0.0, 0.0, 800],
    ]);

    _sparkleFade = _seq([
      [0.0, 0.0, 150],
      [0.0, 1.0, 100, Curves.easeOut],
      [1.0, 0.0, 200, Curves.easeIn],
      [0.0, 0.0, 1350],
    ]);

    // Pop the dialog when animation completes — based on actual
    // controller state, not a detached timer.
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
      }
    });

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1000), HapticFeedback.heavyImpact);
  }

  Animation<double> _seq(List<dynamic> phases) {
    return TweenSequence(phases.map((p) {
      final b = (p as List)[0] as double;
      final e = p[1] as double;
      final w = (p[2] as int) / _t;
      final c = p.length > 3 ? p[3] as Curve : Curves.linear;
      return TweenSequenceItem(
        tween: Tween(begin: b, end: e).chain(CurveTween(curve: c)),
        weight: w,
      );
    }).toList()).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    return FadeTransition(
      opacity: _overlayFade,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _checkPop,
                    builder: (_, __) => Transform.scale(
                      scale: _checkPop.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.accent500.withValues(alpha: 0.10),
                          border: Border.all(color: theme.accent500, width: 2),
                        ),
                        child: CustomPaint(
                          painter: _CheckmarkPainter(
                            progress: _checkDraw.value,
                            color: theme.accent500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _textFade,
                  builder: (_, __) => Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: DefaultTextStyle(
                        style: const TextStyle(decoration: TextDecoration.none),
                        child: Column(
                          children: [
                            Text(
                              widget.title.toUpperCase(),
                              style: AppTextStyles.label,
                              textAlign: TextAlign.center,
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.subtitle!,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: const Color(0xFFF2F0EB),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(6, (i) {
            final target = _sparkleOffsets[i];
            return AnimatedBuilder(
              animation: _sparkleFade,
              builder: (_, __) {
                final p = _sparkleFade.value;
                final cx = MediaQuery.of(context).size.width / 2;
                final cy = MediaQuery.of(context).size.height / 2;
                return Positioned(
                  left: cx - 2 + target.dx * (1 - p),
                  top: cy - 40 + target.dy * (1 - p),
                  child: Opacity(
                    opacity: p.clamp(0.0, 1.0),
                    child: Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: theme.accent500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.50)
      ..lineTo(size.width * 0.45, size.height * 0.72)
      ..lineTo(size.width * 0.78, size.height * 0.30);

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}
