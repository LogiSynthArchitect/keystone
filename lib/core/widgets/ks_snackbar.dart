import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

enum KsSnackbarType { success, error, info }

/// Feedback notifications in two variants:
/// - **Pill** (success/info): small floating pill at bottom center, auto-dismisses
/// - **Banner** (error): top banner below app bar, stays until manually dismissed
class KsSnackbar {
  KsSnackbar._();

  /// Shows a feedback notification.
  /// Errors use the top banner; success/info use the bottom pill.
  static void show(
    BuildContext context, {
    required String message,
    KsSnackbarType type = KsSnackbarType.info,
  }) {
    switch (type) {
      case KsSnackbarType.error:
        _showBanner(context, message: message, type: type);
      case KsSnackbarType.success:
      case KsSnackbarType.info:
        _showPill(context, message: message, type: type);
    }
  }

  // ──────────────────────────────────────────────
  // PILL — bottom center, auto-dismiss, success/info
  // ──────────────────────────────────────────────
  static void _showPill(
    BuildContext context, {
    required String message,
    KsSnackbarType type = KsSnackbarType.info,
  }) {
    final theme = context.ksc;
    final isSuccess = type == KsSnackbarType.success;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                  color: theme.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: AppTextStyles.body.copyWith(
                        color: theme.white, fontSize: 12)),
              ),
            ],
          ),
          backgroundColor: theme.primary800,
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(
            side: BorderSide(
              color: isSuccess ? theme.success500 : theme.accent500,
              width: 1,
            ),
          ),
          margin: const EdgeInsets.fromLTRB(48, 0, 48, 24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          duration: Duration(seconds: isSuccess ? 2 : 3),
          dismissDirection: DismissDirection.down,
        ),
      );
  }

  // ──────────────────────────────────────────────
  // BANNER — top, below app bar, stays until dismissed
  // ──────────────────────────────────────────────
  static OverlayEntry? _currentBanner;

  static void _showBanner(
    BuildContext context, {
    required String message,
    KsSnackbarType type = KsSnackbarType.error,
  }) {
    _currentBanner?.remove();

    final entry = OverlayEntry(builder: (_) => _BannerWidget(
      message: message,
      type: type,
      onDismiss: () => _currentBanner?.remove(),
    ));

    _currentBanner = entry;
    Overlay.of(context).insert(entry);
  }
}

// ──────────────────────────────────────────────
// Banner widget with spring slide-down animation
// ──────────────────────────────────────────────
class _BannerWidget extends StatefulWidget {
  final String message;
  final KsSnackbarType type;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.5, curve: Curves.easeIn),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.primary800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _color(theme, widget.type),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _color(theme, widget.type).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_icon(widget.type), color: _color(theme, widget.type), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTextStyles.body.copyWith(
                            color: theme.white, fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, color: theme.neutral500, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _color(KsColors theme, KsSnackbarType type) {
    switch (type) {
      case KsSnackbarType.error: return theme.error500;
      case KsSnackbarType.success: return theme.success500;
      case KsSnackbarType.info: return theme.accent500;
    }
  }

  IconData _icon(KsSnackbarType type) {
    switch (type) {
      case KsSnackbarType.error: return Icons.error_outline;
      case KsSnackbarType.success: return Icons.check_circle_outline;
      case KsSnackbarType.info: return Icons.info_outline;
    }
  }
}
