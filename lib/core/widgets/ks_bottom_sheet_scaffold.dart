import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import 'ks_confirm_dialog.dart';

/// Reusable bottom sheet chrome: drag handle → header (title + subtitle + close) →
/// scrollable content area → optional gold bottom bar.
///
/// Saves ~40 lines of boilerplate per drawer. Handles the modal bottom sheet setup,
/// dirty-close confirmation, and the standard gold DONE button.
///
/// Usage:
/// ```dart
/// KsBottomSheetScaffold.show<bool>(
///   context,
///   title: "ITEMS USED",
///   subtitle: count > 0 ? "$count items" : "No items added",
///   isDirty: dirty,
///   bottomLabel: "DONE",
///   onDone: () { /* commit changes */ Navigator.pop(ctx, true); },
///   contentBuilder: (ctx, setSheetState) => Column(
///     children: [ /* your content */ ],
///   ),
/// );
/// ```
class KsBottomSheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool Function() isDirty;
  final Widget Function(BuildContext context, StateSetter setSheetState) contentBuilder;
  final String? bottomLabel;
  final VoidCallback? onDone;
  final VoidCallback? onClose;
  final IconData bottomIcon;
  final Widget Function(BuildContext context, StateSetter setSheetState)? stickyHeader;
  final bool Function()? canPop;

  static bool _kNeverDirty() => false;

  const KsBottomSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.isDirty = _kNeverDirty,
    required this.contentBuilder,
    this.bottomLabel,
    this.onDone,
    this.onClose,
    this.bottomIcon = LineAwesomeIcons.arrow_right_solid,
    this.stickyHeader,
    this.canPop,
  });

  /// Shows the sheet as a modal bottom sheet. Returns the value passed to Navigator.pop.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool Function() isDirty = _kNeverDirty,
    required Widget Function(BuildContext context, StateSetter setSheetState) contentBuilder,
    String? bottomLabel,
    VoidCallback? onDone,
    VoidCallback? onClose,
    IconData bottomIcon = LineAwesomeIcons.arrow_right_solid,
    Widget Function(BuildContext context, StateSetter setSheetState)? stickyHeader,
    bool Function()? canPop,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => KsBottomSheetScaffold(
        title: title,
        subtitle: subtitle,
        isDirty: isDirty,
        contentBuilder: contentBuilder,
        bottomLabel: bottomLabel,
        onDone: onDone,
        onClose: onClose,
        bottomIcon: bottomIcon,
        stickyHeader: stickyHeader,
        canPop: canPop,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(ctx),
              _buildHeader(ctx),
              if (stickyHeader != null) ...[
                stickyHeader!(ctx, setSheetState),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24, 0, 24,
                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: contentBuilder(ctx, setSheetState),
                ),
              ),
              if (bottomLabel != null && onDone != null)
                _buildBottomBar(ctx),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.ksc.neutral600,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: AppTextStyles.h3.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (isDirty()) {
                final ok = await _confirmClose(context);
                if (!ok) return;
              }
              onClose?.call();
              if (context.mounted) Navigator.pop(context);
            },
            child: Icon(
              LineAwesomeIcons.times_solid,
              color: context.ksc.neutral500,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.ksc.accent500,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onDone?.call();
            if ((canPop == null || canPop!()) && context.mounted) {
              Navigator.pop(context, true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bottomLabel!,
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.primary900,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(bottomIcon, color: context.ksc.primary900, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmClose(BuildContext context) async {
    return await KsConfirmDialog.show(
      context,
      title: 'DISCARD CHANGES?',
      message: 'You have unsaved changes. Discard them?',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () {},
    ) ?? false;
  }
}
