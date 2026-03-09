import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum KsButtonVariant { primary, secondary, cta, ghost, danger }
enum KsButtonSize { large, small }

class KsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KsButtonVariant variant;
  final KsButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  const KsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KsButtonVariant.primary,
    this.size = KsButtonSize.large,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    final height = size == KsButtonSize.large
        ? AppSpacing.buttonHeight
        : AppSpacing.buttonSmallHeight;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: _buildButton(isDisabled),
    );
  }

  Widget _buildButton(bool isDisabled) {
    switch (variant) {
      case KsButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? AppColors.neutral200 : AppColors.primary700,
            foregroundColor: isDisabled ? AppColors.neutral500 : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 0,
          ),
          child: _buildChild(),
        );
      case KsButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary700,
            side: BorderSide(
              color: isDisabled ? AppColors.neutral300 : AppColors.primary700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          child: _buildChild(),
        );
      case KsButtonVariant.cta:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent500,
            foregroundColor: AppColors.primary900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 0,
          ),
          child: _buildChild(),
        );
      case KsButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          child: _buildChild(),
        );
      case KsButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error500,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 0,
          ),
          child: _buildChild(),
        );
    }
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
      );
    }
    final textStyle = size == KsButtonSize.large
        ? AppTextStyles.label
        : AppTextStyles.labelSmall;
    final children = <Widget>[];
    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: 18));
      children.add(const SizedBox(width: AppSpacing.sm));
    }
    children.add(Text(label, style: textStyle));
    if (trailingIcon != null) {
      children.add(const SizedBox(width: AppSpacing.sm));
      children.add(Icon(trailingIcon, size: 18));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
