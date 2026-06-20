import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/app_text_styles.dart';

/// A single key in the [KsNumpad] connected grid layout.
///
/// No rounded corners, no shadow, no individual border — the grid container
/// and thin line separators handle the visual structure.
class KsNumpadKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final double height;

  const KsNumpadKey({
    super.key,
    this.label,
    this.icon,
    required this.onTap,
    this.height = 68,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: icon != null ? onTap : null,
          splashColor: context.ksc.primary600.withValues(alpha: 0.3),
          highlightColor: context.ksc.primary600.withValues(alpha: 0.15),
          child: Container(
            color: context.ksc.primary800,
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: AppTextStyles.h2.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    )
                  : Icon(icon, color: context.ksc.neutral300, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
