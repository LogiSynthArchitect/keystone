import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

enum KsSnackbarType { success, error, info }

class KsSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    KsSnackbarType type = KsSnackbarType.info,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_icon(type), color: context.ksc.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.body.copyWith(color: context.ksc.white)),
            ),
          ],
        ),
        backgroundColor: _color(context, type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Color _color(BuildContext context, KsSnackbarType type) {
    switch (type) {
      case KsSnackbarType.success: return context.ksc.success500;
      case KsSnackbarType.error:   return context.ksc.error500;
      case KsSnackbarType.info:    return context.ksc.primary700;
    }
  }

  static IconData _icon(KsSnackbarType type) {
    switch (type) {
      case KsSnackbarType.success: return Icons.check_circle_outline;
      case KsSnackbarType.error:   return Icons.error_outline;
      case KsSnackbarType.info:    return Icons.info_outline;
    }
  }
}
