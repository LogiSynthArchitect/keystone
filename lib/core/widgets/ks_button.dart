import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
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
  final bool edgeToEdge;

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
    this.edgeToEdge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (edgeToEdge) return _buildEdgeToEdge(context);

    final isDisabled = onPressed == null && !isLoading;
    final btnHeight = size == KsButtonSize.large
        ? AppSpacing.buttonHeight
        : AppSpacing.buttonSmallHeight;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: btnHeight,
      child: _buildButton(context, isDisabled),
    );
  }

  Color _edgeBgColor(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    if (isDisabled) return context.ksc.primary600;
    switch (variant) {
      case KsButtonVariant.cta:
      case KsButtonVariant.secondary:
        return context.ksc.accent500;
      case KsButtonVariant.danger:
        return context.ksc.error500;
      case KsButtonVariant.ghost:
        return context.ksc.primary800.withValues(alpha: 0.6);
      case KsButtonVariant.primary:
        return context.ksc.primary700;
    }
  }

  Color _edgeFgColor(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    if (isDisabled) return context.ksc.neutral500;
    switch (variant) {
      case KsButtonVariant.cta:
      case KsButtonVariant.secondary:
        return context.ksc.primary900;
      case KsButtonVariant.danger:
        return context.ksc.white;
      case KsButtonVariant.ghost:
        return context.ksc.neutral400;
      case KsButtonVariant.primary:
        return context.ksc.white;
    }
  }

  Widget _buildEdgeToEdge(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _edgeBgColor(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: _edgeFgColor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _edgeFgColor(context),
                    ),
                  )
                else
                  Icon(
                    trailingIcon ?? LineAwesomeIcons.arrow_right_solid,
                    color: _edgeFgColor(context),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isDisabled) {
    switch (variant) {
      case KsButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? context.ksc.neutral400 : context.ksc.primary700,
            foregroundColor: isDisabled ? context.ksc.neutral500 : context.ksc.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child: _buildChild(context),
        );
      case KsButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? context.ksc.neutral400 : context.ksc.accent500,
            foregroundColor: isDisabled ? context.ksc.neutral500 : context.ksc.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: EdgeInsets.zero,
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: EdgeInsets.zero,
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: EdgeInsets.zero,
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
    final baseStyle = size == KsButtonSize.large
        ? AppTextStyles.label
        : AppTextStyles.labelSmall;
    // Strip hardcoded gold color — let button's foregroundColor control it
    final textStyle = TextStyle(
      fontFamily: baseStyle.fontFamily,
      fontSize: baseStyle.fontSize,
      fontWeight: baseStyle.fontWeight,
      letterSpacing: baseStyle.letterSpacing,
      height: baseStyle.height,
    );
    final children = <Widget>[];
    if (leadingIcon != null) {
      children.add(Icon(leadingIcon, size: 18));
      children.add(const SizedBox(width: AppSpacing.sm));
    }
    children.add(Text(label, style: textStyle, overflow: TextOverflow.ellipsis));
    if (trailingIcon != null) {
      children.add(const SizedBox(width: AppSpacing.sm));
      children.add(Icon(trailingIcon, size: 18));
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
