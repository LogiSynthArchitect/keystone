import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import 'ks_button.dart';

class KsConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final VoidCallback onConfirm;

  const KsConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDanger = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => KsConfirmDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.ksc.primary800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: context.ksc.primary700),
      ),
      title: Text(title.toUpperCase(), style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
      content: Text(message,
          style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
      actions: [
        KsButton(
          label: cancelLabel.toUpperCase(),
          variant: KsButtonVariant.secondary,
          size: KsButtonSize.small,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: 8),
        KsButton(
          label: confirmLabel.toUpperCase(),
          variant: isDanger ? KsButtonVariant.danger : KsButtonVariant.primary,
          size: KsButtonSize.small,
          fullWidth: false,
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop(true);
          },
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }
}
