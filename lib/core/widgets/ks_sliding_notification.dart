import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum KsNotificationType { success, info, error }

/// Themed notification via [OverlayEntry] — floats completely outside
/// the Navigator and Scaffold. No route lifecycle conflicts with GoRouter.
///
/// Slides in from left, pauses center 3s, slides out to right.
/// Color variants: success (green), info (blue), error (red).
/// Gold progress bar shrinks during pause phase.
///
/// API matches previous flushbar-based implementation — all 97 call sites
/// work unchanged. The only difference: zero Navigator interactions.
class KsSlidingNotification {
  KsSlidingNotification._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Show a themed sliding notification via OverlayEntry (no Navigator).
  ///
  /// All parameters match the previous flushbar-based API for zero-migration.
  /// Returns immediately; notification lifecycle is managed internally.
  static void show(
    BuildContext context, {
    required String message,
    KsNotificationType type = KsNotificationType.info,
    Duration? pauseDuration = const Duration(seconds: 3),
    String? label,
    String? title,
    String? entity,
    Map<String, String>? metadata,
    String? detail,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
  }) {
    // Remove any existing notification before showing a new one
    _dismiss(immediate: true);

    final overlay = Overlay.of(context);
    final colorScheme = _colorScheme(type);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _KsNotificationWidget(
        message: message,
        type: type,
        pauseDuration: pauseDuration,
        label: label,
        title: title,
        entity: entity,
        metadata: metadata,
        detail: detail,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        onDismiss: () {
          _dismiss(immediate: false);
          onDismiss?.call();
        },
        onDone: () {
          _dismiss(immediate: false);
          onDismiss?.call();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismiss({bool immediate = false}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static (Color bg, Color accent, IconData icon) _colorScheme(KsNotificationType type) {
    return switch (type) {
      KsNotificationType.success => (
        const Color(0xFF2E7D32),
        const Color(0xFF81C784),
        Icons.check_circle_outline,
      ),
      KsNotificationType.info => (
        const Color(0xFF1565C0),
        const Color(0xFF64B5F6),
        Icons.info_outline,
      ),
      KsNotificationType.error => (
        const Color(0xFFC62828),
        const Color(0xFFEF9A9A),
        Icons.error_outline,
      ),
    };
  }
}

/// Internal stateful widget rendered inside the OverlayEntry.
/// Manages its own slide-in/slide-out and progress bar animation.
class _KsNotificationWidget extends StatefulWidget {
  final String message;
  final KsNotificationType type;
  final Duration? pauseDuration;
  final String? label;
  final String? title;
  final String? entity;
  final Map<String, String>? metadata;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onDismiss;
  final VoidCallback? onDone;

  const _KsNotificationWidget({
    required this.message,
    required this.type,
    this.pauseDuration,
    this.label,
    this.title,
    this.entity,
    this.metadata,
    this.detail,
    this.actionLabel,
    this.onActionPressed,
    this.onDismiss,
    this.onDone,
  });

  @override
  State<_KsNotificationWidget> createState() => _KsNotificationWidgetState();
}

class _KsNotificationWidgetState extends State<_KsNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;
  Timer? _pauseTimer;
  Timer? _progressTimer;
  double _progress = 1.0;

  static const _font = 'BarlowSemiCondensed';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideIn = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Slide in
    _controller.forward();

    // Start auto-dismiss timer after slide completes
    if (widget.pauseDuration != null) {
      const slideDuration = Duration(milliseconds: 400);
      final totalDelay = slideDuration + const Duration(milliseconds: 100);
      Future.delayed(totalDelay, _startAutoDismiss);
    }
  }

  void _startAutoDismiss() {
    final duration = widget.pauseDuration!;
    _pauseTimer = Timer(duration, _slideOut);

    // Progress bar tick
    const tickMs = 16; // ~60fps
    final totalTicks = duration.inMilliseconds ~/ tickMs;
    int ticks = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      ticks++;
      final remaining = 1.0 - (ticks / totalTicks);
      if (mounted) setState(() => _progress = remaining.clamp(0.0, 1.0));
    });
  }

  void _slideOut() {
    _progressTimer?.cancel();
    _controller.reverse().then((_) {
      widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, accentColor, iconData) = KsSlidingNotification._colorScheme(widget.type);

    final topSafe = MediaQuery.of(context).padding.top;

    final defaultLabel = switch (widget.type) {
      KsNotificationType.success => 'SUCCESS',
      KsNotificationType.info => 'INFO',
      KsNotificationType.error => 'ERROR',
    };

    return Stack(
      children: [
        // Dimming backdrop
        if (_fadeIn.value > 0)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _slideOut(),
              child: Container(color: Colors.black.withValues(alpha: 0.3 * _fadeIn.value)),
            ),
          ),
        // Notification card
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideIn,
            child: FadeTransition(
              opacity: _fadeIn,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: EdgeInsets.only(top: topSafe + 12, bottom: 16, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.label ?? defaultLabel,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                if (widget.title != null) ...[
                                  const SizedBox(height: 1),
                                  Text(widget.title!, style: const TextStyle(
                                    fontFamily: _font,
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  )),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Metadata chips
                                if (widget.metadata != null && widget.metadata!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: widget.metadata!.entries.map((e) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${e.key}: ${e.value}',
                                          style: const TextStyle(
                                            fontFamily: _font,
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                // Entity + detail
                                if (widget.entity != null || widget.detail != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (widget.entity != null) widget.entity!,
                                      if (widget.detail != null) widget.detail!,
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontFamily: _font,
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Action pill
                          if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onActionPressed,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    fontFamily: _font,
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Gold progress bar
                      if (widget.pauseDuration != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 3,
                              child: FractionallySizedBox(
                                widthFactor: _progress,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
