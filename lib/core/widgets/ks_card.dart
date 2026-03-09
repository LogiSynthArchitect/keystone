import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum KsCardVariant { elevated, outlined, flat }

class KsCard extends StatelessWidget {
  final Widget child;
  final KsCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const KsCard({
    super.key,
    required this.child,
    this.variant = KsCardVariant.outlined,
    this.onTap,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.cardPadding);

    BoxDecoration decoration;
    switch (variant) {
      case KsCardVariant.elevated:
        decoration = BoxDecoration(
          color: backgroundColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.neutral900.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case KsCardVariant.outlined:
        decoration = BoxDecoration(
          color: backgroundColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.neutral200),
        );
      case KsCardVariant.flat:
        decoration = BoxDecoration(
          color: backgroundColor ?? AppColors.neutral050,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        );
    }

    final content = Container(
      decoration: decoration,
      padding: effectivePadding,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
