import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// Ultra-compact progress indicator: thin progress bar + step info row.
///
/// Layout:
///   ━━━━━━━━━━━━━░░░░░░░░░░░░░░░░░░░░░░░░  4px progress bar
///   ● Step 3 · DETAILS             3 of 4   16px info row
///
/// - Current step: accent500 dot + step name
/// - Completed segments: accent500 fill
/// - Remaining segments: neutral700 fill
/// - Scales to any number of steps without label crowding
class KsStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const KsStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(bottom: BorderSide(color: context.ksc.primary700)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar row
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Row(
                children: List.generate(totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      margin: index > 0 ? const EdgeInsets.only(left: 2) : null,
                      decoration: BoxDecoration(
                        color: index <= currentStep
                            ? context.ksc.accent500
                            : context.ksc.neutral700,
                        borderRadius: BorderRadius.only(
                          topLeft: index == 0 ? const Radius.circular(2) : Radius.zero,
                          bottomLeft: index == 0 ? const Radius.circular(2) : Radius.zero,
                          topRight: index == totalSteps - 1 ? const Radius.circular(2) : Radius.zero,
                          bottomRight: index == totalSteps - 1 ? const Radius.circular(2) : Radius.zero,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Info row: step dot + name on left, counter on right
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: context.ksc.accent500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Step ${currentStep + 1} · ${labels[currentStep].toUpperCase()}",
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${currentStep + 1} of $totalSteps",
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
