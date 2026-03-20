import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

enum KsBadgeVariant { success, warning, error, info, neutral }

class KsBadge extends StatelessWidget {
  final String label;
  final KsBadgeVariant variant;
  final IconData? icon;

  const KsBadge({
    super.key,
    required this.label,
    this.variant = KsBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _textColor(context)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyles.captionMedium.copyWith(color: _textColor(context))),
        ],
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    switch (variant) {
      case KsBadgeVariant.success: return context.ksc.success100;
      case KsBadgeVariant.warning: return context.ksc.warning100;
      case KsBadgeVariant.error:   return context.ksc.error100;
      case KsBadgeVariant.info:    return context.ksc.primary100;
      case KsBadgeVariant.neutral: return context.ksc.neutral100;
    }
  }

  Color _textColor(BuildContext context) {
    switch (variant) {
      case KsBadgeVariant.success: return context.ksc.success600;
      case KsBadgeVariant.warning: return context.ksc.warning600;
      case KsBadgeVariant.error:   return context.ksc.error600;
      case KsBadgeVariant.info:    return context.ksc.primary600;
      case KsBadgeVariant.neutral: return context.ksc.neutral600;
    }
  }
}
