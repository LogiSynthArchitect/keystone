import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// Displays a modal bottom sheet with consistent drawer chrome:
/// drag handle → header (icon + title + close) → divider → content → optional gold bottom bar.
///
/// For the common case (single action CTA), pass [bottomLabel] + [bottomOnPressed]
/// to render the gold full-width bar matching KsStepDrawer's style.
/// For custom bottom widgets, pass [bottom] (mutually exclusive with typed params).
///
/// Usage:
/// ```dart
/// KsContentDrawer.show(
///   context,
///   icon: LineAwesomeIcons.key_solid,
///   title: "KEY CODES",
///   child: myContentWidget,
///   bottomLabel: "ADD KEY CODE",
///   bottomOnPressed: () => ...,
/// );
/// ```
class KsContentDrawer {
  static Future<T?> show<T>(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
    String? bottomLabel,
    VoidCallback? bottomOnPressed,
    IconData bottomIcon = LineAwesomeIcons.arrow_right_solid,
    Widget? bottom,
    double heightFactor = 0.85,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(ctx).size.height * heightFactor,
          child: Column(
            children: [
              _buildHandle(ctx),
              _buildHeader(ctx, icon, title),
              Container(height: 1, color: ctx.ksc.primary700),
              Expanded(child: child),
              if (bottomLabel != null && bottomOnPressed != null)
                _buildBottomBar(ctx, bottomLabel, bottomOnPressed, bottomIcon)
              else if (bottom != null)
                bottom,
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: context.ksc.neutral600,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static Widget _buildHeader(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 8, 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.ksc.accent500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
              style: AppTextStyles.h2.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral400, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static Widget _buildBottomBar(BuildContext context, String label, VoidCallback onPressed, IconData icon) {
    return Container(
      width: double.infinity,
      color: context.ksc.accent500,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.primary900,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(icon, color: context.ksc.primary900, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
