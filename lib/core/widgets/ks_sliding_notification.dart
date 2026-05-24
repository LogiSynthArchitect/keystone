import 'dart:async';

import 'package:another_flushbar/another_flushbar.dart';
import 'package:flutter/material.dart';

enum KsNotificationType { success, info, error }

/// Themed notification via [Flushbar] — full-top cover with hero icon, detail
/// subtitle, and optional action pill.
///
/// Slides down from top with elasticOut bounce, edge-to-edge grounded style,
/// covering the full screen top (including notch area) with a dimming backdrop.
/// Existing [KsSlidingNotification.show] callsites continue to work unchanged.
class KsSlidingNotification {
  KsSlidingNotification._();

  /// The app-wide font family used across all UI text.
  static const String _font = 'BarlowSemiCondensed';

  /// Show a themed [Flushbar] that covers the full top of the screen.
  ///
  /// All new parameters are optional — existing callsites need zero changes.
  ///
  /// [pauseDuration] controls auto-dismiss; pass `null` for persistent
  /// notifications that stay until the user swipes or taps the action pill.
  static void show(
    BuildContext context, {
    required String message,
    String? label,
    KsNotificationType type = KsNotificationType.success,
    Duration? pauseDuration = const Duration(seconds: 3),
    String? title,
    String? entity,
    Map<String, String>? metadata,
    String? detail,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onDismiss,
  }) {
    final bgColor = switch (type) {
      KsNotificationType.success => const Color(0xFF2E7D32),
      KsNotificationType.info => const Color(0xFF1565C0),
      KsNotificationType.error => const Color(0xFFC62828),
    };

    final defaultLabel = switch (type) {
      KsNotificationType.success => 'SUCCESS',
      KsNotificationType.info => 'INFO',
      KsNotificationType.error => 'ERROR',
    };

    final leftColor = switch (type) {
      KsNotificationType.success => const Color(0xFF81C784),
      KsNotificationType.info => const Color(0xFF64B5F6),
      KsNotificationType.error => const Color(0xFFEF9A9A),
    };

    final iconData = switch (type) {
      KsNotificationType.success => Icons.check_circle_outline,
      KsNotificationType.info => Icons.info_outline,
      KsNotificationType.error => Icons.error_outline,
    };

    final topSafe = MediaQuery.of(context).padding.top;

    // ── Label style: heavy uppercase badge ──
    const labelStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white70,
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    );

    // ── Title style: bold headline ──
    const titleStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w900,
    );

    // ── Message style: primary notification text ──
    const messageStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w900,
    );

    // ── Entity tag style ──
    final entityStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white.withValues(alpha: 0.65),
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );

    // ── Detail style: secondary info ──
    final detailStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white.withValues(alpha: 0.55),
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );

    // ── Metadata chip style ──
    final chipStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );

        // ── Action pill style ──
    const actionStyle = TextStyle(
      fontFamily: _font,
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w900,
    );

    // ── White progress bar for countdown ──

    final flushbar = Flushbar(
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.GROUNDED,
      safeArea: false,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.fastOutSlowIn,
      animationDuration: const Duration(milliseconds: 300),
      duration: pauseDuration,
      onStatusChanged: onDismiss != null
          ? (status) {
              if (status == FlushbarStatus.DISMISSED) onDismiss();
            }
          : null,
      padding: EdgeInsets.only(
        top: topSafe + 12,
        bottom: 16,
        left: 24,
        right: 24,
      ),
      backgroundColor: bgColor,
      leftBarIndicatorColor: leftColor,
      routeColor: Colors.black.withValues(alpha: 0.3),
      barBlur: 3.0,
      blockBackgroundInteraction: true,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: Colors.white, size: 22),
      ),
      shouldIconPulse: true,
      isDismissible: true,
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      messageText: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label ?? defaultLabel,
                      style: labelStyle,
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 1),
                      Text(title, style: titleStyle),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: messageStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // ── Metadata chips row ──
                    if (metadata != null && metadata.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: metadata.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: chipStyle,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // ── Entity + detail row ──
                    if (entity != null || detail != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (entity != null) entity,
                          if (detail != null) detail,
                        ].join(' · '),
                        style: entity != null ? entityStyle : detailStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onActionPressed != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onActionPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      actionLabel,
                      style: actionStyle,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // ── Shrinking white bar = time until auto-dismiss ──
          if (pauseDuration != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: pauseDuration,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    unawaited(flushbar.show(context));
  }
}
