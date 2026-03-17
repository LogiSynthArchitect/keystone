import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'onboarding_step_indicator.dart';

class NameStepView extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isValid;
  final VoidCallback onSubmitted;

  const NameStepView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isValid,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LineAwesomeIcons.user_circle,
            color: Color(0xFFF9A825),
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'What should\nwe call you?',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: AppColors.primary700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your name appears on your public profile.',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        const OnboardingStepIndicator(activeStep: 0),
        const SizedBox(height: 32),
        const Text(
          'Full name',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? AppColors.primary700 : const Color(0xFFEAEAEC),
              width: isFocused ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: isValid ? (_) => onSubmitted() : null,
            style: const TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
            ),
            decoration: InputDecoration(
              hintText: 'Jeremie Mensah',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: controller.text.isNotEmpty
                  ? Icon(
                      isValid ? LineAwesomeIcons.check_circle : LineAwesomeIcons.times_circle,
                      color: isValid ? const Color(0xFFF9A825) : AppColors.neutral400,
                      size: 22,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
