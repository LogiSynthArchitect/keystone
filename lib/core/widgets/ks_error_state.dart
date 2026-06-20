import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import 'ks_button.dart';

class KsErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String title;
  final String subtitle;
  final IconData icon;

  const KsErrorState({
    super.key,
    required this.onRetry,
    this.title = 'FAILED TO LOAD',
    required this.subtitle,
    this.icon = LineAwesomeIcons.exclamation_triangle_solid,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.ksc.error500),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.neutral400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            KsButton(
              label: 'TAP TO RETRY',
              variant: KsButtonVariant.primary,
              size: KsButtonSize.small,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
