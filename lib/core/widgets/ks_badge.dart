import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _textColor),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyles.captionMedium.copyWith(color: _textColor)),
        ],
      ),
    );
  }

  Color get _backgroundColor {
    switch (variant) {
      case KsBadgeVariant.success: return AppColors.success100;
      case KsBadgeVariant.warning: return AppColors.warning100;
      case KsBadgeVariant.error:   return AppColors.error100;
      case KsBadgeVariant.info:    return AppColors.primary100;
      case KsBadgeVariant.neutral: return AppColors.neutral100;
    }
  }

  Color get _textColor {
    switch (variant) {
      case KsBadgeVariant.success: return AppColors.success600;
      case KsBadgeVariant.warning: return AppColors.warning600;
      case KsBadgeVariant.error:   return AppColors.error600;
      case KsBadgeVariant.info:    return AppColors.primary600;
      case KsBadgeVariant.neutral: return AppColors.neutral600;
    }
  }
}
