import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// Confirmation dialog with hero icon, gold left accent, centered layout,
/// pop-in animation, and ghost/gold/danger buttons.
///
/// Usage (backward-compatible — all existing callers work unchanged):
/// ```dart
/// final confirmed = await KsConfirmDialog.show(context,
///   title: 'Delete Item',
///   message: 'Are you sure?',
///   onConfirm: () => deleteItem(),
///   isDanger: true,
/// );
/// ```
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

  /// Shows the dialog with a pop-in elastic transition.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, secAnim, child) {
        return AnimatedBuilder(
          animation: anim,
          builder: (ctx, child) {
            final scale = 0.88 + (0.12 * anim.value); // 0.88 → 1.0
            final opacity = anim.value;
            final translateY = 20.0 * (1.0 - anim.value); // 20 → 0
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
      pageBuilder: (ctx, anim, secAnim) => KsConfirmDialog(
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
    final iconData = isDanger ? Icons.error_outline : Icons.warning_amber_rounded;
    final iconBgColor = isDanger
        ? context.ksc.error500.withValues(alpha: 0.18)
        : context.ksc.accent500.withValues(alpha: 0.18);
    final iconColor = isDanger ? context.ksc.error500 : context.ksc.accent500;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 60,
                offset: Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero icon + title + message ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    // Hero icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 28),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      title.toUpperCase(),
                      style: AppTextStyles.h2.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Message
                    Text(
                      message,
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.neutral400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // ── Buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    // Cancel — ghost style
                    Expanded(
                      child: _buildGhostButton(context, cancelLabel.toUpperCase(),
                          () => Navigator.of(context).pop(false)),
                    ),
                    const SizedBox(width: 10),
                    // Confirm — gold or danger
                    Expanded(
                      child: _buildSolidButton(
                        context,
                        confirmLabel.toUpperCase(),
                        isDanger,
                        () {
                          onConfirm();
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(BuildContext context, String label, VoidCallback onTap) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: context.ksc.neutral400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: context.ksc.neutral700),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSolidButton(
    BuildContext context,
    String label,
    bool danger,
    VoidCallback onTap,
  ) {
    final bgColor = danger ? context.ksc.error500 : context.ksc.accent500;
    final fgColor = danger ? const Color(0xFFFFFFFF) : context.ksc.primary900;
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
          shadowColor: bgColor.withValues(alpha: 0.25),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
