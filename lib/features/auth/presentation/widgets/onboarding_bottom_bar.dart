import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';

class OnboardingBottomBar extends StatelessWidget {
  final int step;
  final bool isLoading;
  final VoidCallback? onPressed;

  const OnboardingBottomBar({
    super.key,
    required this.step,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.ksc.primary700,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: context.ksc.primary700,
                  disabledBackgroundColor: const Color(0xFFF9A825).withValues(alpha: 0.4),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        step == 0 ? 'Continue' : 'Get Started',
                        style: const TextStyle(
                          fontFamily: 'BarlowSemiCondensed',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
