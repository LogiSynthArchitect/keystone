import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final int activeStep;

  const OnboardingStepIndicator({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final isActive = i == activeStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary700 : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
