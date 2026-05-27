import 'dart:math';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// A step in a multi-step drawer progression.
class KsStep {
  final String label;
  final IconData icon;
  final int subSteps;
  final String? tip;
  final String? imageAsset;

  const KsStep({
    required this.label,
    required this.icon,
    this.subSteps = 1,
    this.tip,
    this.imageAsset,
  });
}

/// Reusable bottom-sheet drawer with circular step progression + sub-steps.
///
/// [steps] → circular ring + sub-step dot indicators
/// [steps] null → single-step mode, no ring
///
/// Bottom bar is always a single full-width gold button with sharp edges.
/// Back navigation via [showBackArrow] in header.
class KsStepDrawer extends StatefulWidget {
  final String title;
  final List<KsStep>? steps;
  final bool showBackArrow;
  final VoidCallback? onBack;
  final Widget Function(int step, int subStep, StateSetter rebuild, VoidCallback advance) stepContent;
  final bool Function(int step, int subStep)? canAdvance;
  final Future<void> Function()? onSave;
  final String nextLabel;
  final String saveLabel;
  final VoidCallback? onClose;
  final bool readOnly;

  const KsStepDrawer({
    super.key,
    required this.title,
    this.steps,
    this.showBackArrow = false,
    this.onBack,
    required this.stepContent,
    this.canAdvance,
    this.onSave,
    this.nextLabel = 'NEXT',
    this.saveLabel = 'SAVE',
    this.onClose,
    this.readOnly = false,
  });

  @override
  State<KsStepDrawer> createState() => _KsStepDrawerState();
}

class _KsStepDrawerState extends State<KsStepDrawer>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  int _subStep = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  int get _totalSteps => widget.steps?.length ?? 1;
  int get _currentSubSteps => widget.steps?[_currentStep].subSteps ?? 1;
  bool get _isLastSubStep => _subStep >= _currentSubSteps - 1;
  bool get _isLastStep => _currentStep >= _totalSteps - 1;
  bool get _isComplete => _isLastStep && _isLastSubStep;
  bool get _canProceed => widget.canAdvance?.call(_currentStep, _subStep) ?? true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 0.7).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_subStep > 0) {
      setState(() => _subStep--);
    } else if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _subStep = (widget.steps![_currentStep].subSteps - 1);
      });
    } else {
      widget.onBack?.call();
    }
  }

  void _handleNextStep() {
    if (_isComplete) {
      widget.onSave?.call();
    } else if (_isLastSubStep) {
      setState(() {
        _currentStep++;
        _subStep = 0;
      });
    } else {
      setState(() => _subStep++);
    }
  }

  void _handleBottomTap() {
    if (!_canProceed) return;
    if (widget.readOnly) {
      widget.onSave?.call();
      return;
    }
    _handleNextStep();
  }

  void _showTip(BuildContext context) {
    final tip = widget.steps?[_currentStep].tip;
    if (tip == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.5)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("💡", style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text("TIP", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(tip, style: AppTextStyles.body.copyWith(
              color: context.ksc.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Text("GOT IT", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row with tip icon
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                if (widget.showBackArrow)
                  GestureDetector(
                    onTap: _handleBack,
                    child: Icon(LineAwesomeIcons.angle_left_solid,
                        color: context.ksc.accent500, size: 18),
                  ),
                if (widget.showBackArrow) const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                    style: AppTextStyles.h2.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                    )),
                ),
                // Tip icon — opens a modal
                if (widget.steps != null && widget.steps![_currentStep].tip != null)
                  GestureDetector(
                    onTap: () => _showTip(context),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(LineAwesomeIcons.question_circle_solid,
                          color: context.ksc.accent500, size: 20),
                    ),
                  ),
                GestureDetector(
                  onTap: widget.onClose ?? () => Navigator.pop(context),
                  child: Icon(LineAwesomeIcons.times_solid,
                      color: context.ksc.neutral500, size: 20),
                ),
              ],
            ),
          ),
          // Big ring with center icon + step label below
          if (widget.steps != null && _totalSteps > 1) ...[
            const SizedBox(height: 8),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BigProgressRing(
                    key: ValueKey('step_$_currentStep'),
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    steps: widget.steps!,
                    pulseValue: _pulseAnim.value,
                  ),
                  const SizedBox(height: 8),
                  Text("STEP ${_currentStep + 1}/${_totalSteps}",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
                  const SizedBox(height: 2),
                  Text(widget.steps![_currentStep].label,
                    style: AppTextStyles.body.copyWith(
                      color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  // Sub-step dots
                  if (_currentSubSteps > 1) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_currentSubSteps, (i) {
                        final isActive = i <= _subStep;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: isActive ? 14 : 6,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive
                                ? context.ksc.accent500
                                : context.ksc.primary700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Divider
            Container(height: 1, color: context.ksc.primary700),
            const SizedBox(height: 12),
          ],
          // Step content (flexible area, centered, scrollable with keyboard)
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset + 16),
                  child: Center(
                    child: widget.stepContent(_currentStep, _subStep, (fn) => setState(fn), _handleNextStep),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            color: _canProceed
                ? context.ksc.accent500
                : context.ksc.primary600,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _canProceed ? _handleBottomTap : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.readOnly ? "CLOSE" : (_isComplete ? widget.saveLabel : widget.nextLabel),
                        style: AppTextStyles.body.copyWith(
                          color: _canProceed
                              ? context.ksc.primary900
                              : context.ksc.neutral500,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(
                        _isComplete
                            ? LineAwesomeIcons.check_solid
                            : LineAwesomeIcons.arrow_right_solid,
                        color: _canProceed
                            ? context.ksc.primary900
                            : context.ksc.neutral500,
                        size: 20,
                      ),
                    ],
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

/// Big central progress ring — 3D icon inside, arc segments around it.
class _BigProgressRing extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<KsStep> steps;
  final double pulseValue;

  const _BigProgressRing({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.steps,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    const center = size / 2;
    const radius = 48.0;
    const iconSize = 52.0;
    const strokeWidth = 8.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Progress ring arcs
          CustomPaint(
            size: const Size(size, size),
            painter: _RingPainter(
              currentStep: currentStep,
              totalSteps: totalSteps,
              accentColor: context.ksc.accent500,
              mutedColor: context.ksc.primary700,
              activeGlow: pulseValue,
              strokeWidth: strokeWidth,
              radius: radius,
              center: const Offset(center, center),
            ),
          ),
          // Large 3D icon in the center
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: steps[currentStep].imageAsset != null
                  ? Image.asset(
                      steps[currentStep].imageAsset!,
                      key: ValueKey('img_$currentStep'),
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      steps[currentStep].icon,
                      key: ValueKey('icon_$currentStep'),
                      size: iconSize * 0.6,
                      color: context.ksc.accent500,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final int currentStep;
  final int totalSteps;
  final Color accentColor;
  final Color mutedColor;
  final double activeGlow;
  final double strokeWidth;
  final double radius;
  final Offset center;

  _RingPainter({
    required this.currentStep,
    required this.totalSteps,
    required this.accentColor,
    required this.mutedColor,
    required this.activeGlow,
    required this.strokeWidth,
    required this.radius,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSteps < 2) return;
    final segmentAngle = (2 * pi) / totalSteps;
    final startAngle = -pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < totalSteps; i++) {
      final segStart = startAngle + i * segmentAngle;
      if (i < currentStep) {
        paint.color = accentColor;
      } else if (i == currentStep) {
        paint.color = accentColor.withValues(alpha: activeGlow);
      } else {
        paint.color = mutedColor;
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segStart, segmentAngle, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.currentStep != currentStep || old.activeGlow != activeGlow;
}
