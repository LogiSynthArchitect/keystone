import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

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
      child: _buildButton(context, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, bool isDisabled) {
    switch (variant) {
      case KsButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? context.ksc.neutral200 : context.ksc.primary700,
            foregroundColor: isDisabled ? context.ksc.neutral500 : context.ksc.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 0,
          ),
          child: _buildChild(context),
        );
      case KsButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: context.ksc.primary700,
            side: BorderSide(
              color: isDisabled ? context.ksc.neutral300 : context.ksc.primary700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          child: _buildChild(context),
        );
      case KsButtonVariant.cta:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.ksc.accent500,
            foregroundColor: context.ksc.primary900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 0,
          ),
          child: _buildChild(context),
        );
      case KsButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: context.ksc.primary600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          child: _buildChild(context),
        );
      case KsButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.ksc.error500,
            foregroundColor: context.ksc.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            elevation: 0,
          ),
          child: _buildChild(context),
        );
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.white),
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
