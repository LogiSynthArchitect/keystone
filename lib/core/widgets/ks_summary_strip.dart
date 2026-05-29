import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// A reusable summary strip card for list screens.
///
/// Shows a primary metric (big number + label), optional progress bar,
/// and a secondary stats row. Designed to be the first thing a user sees
/// when entering any list screen — gives them "the shape of the data."
///
/// Usage (plain text):
/// ```dart
/// KsSummaryStrip(
///   value: totalCount.toString(),
///   label: "ALL CUSTOMERS",
///   subtitle: "$repeatCount repeat ● $pendingSyncCount pending",
/// )
/// ```
///
/// Usage (colored segments):
/// ```dart
/// KsSummaryStrip(
///   value: active.length.toString(),
///   label: "ACTIVE REMINDERS",
///   subtitleSegments: [
///     KsSubtitleSegment('$unpaidCount unpaid', color: amber500),
///     KsSubtitleSegment('$stuckCount stuck', color: error500),
///   ],
///   subtitleIcon: LineAwesomeIcons.bell_solid,
/// )
/// ```
///
/// Pass [margin] to override the default horizontal spacing. Set to
/// `EdgeInsets.zero` when the parent already provides padding.
///
/// When both [subtitle] and [subtitleSegments] are provided, [subtitleSegments]
/// takes precedence.
class KsSummaryStrip extends StatelessWidget {
  /// The primary display value (e.g. "38" or "¢12,500")
  final String value;

  /// Label under the value (e.g. "ALL CUSTOMERS")
  final String label;

  /// Optional secondary info shown below the divider (plain text).
  /// Ignored when [subtitleSegments] is provided.
  final String? subtitle;

  /// Optional colored subtitle segments. When set, overrides [subtitle].
  /// Each segment renders in its own color with ● separators between them.
  final List<KsSubtitleSegment>? subtitleSegments;

  /// Optional progress fraction 0.0–1.0 (shows a progress bar when set)
  final double? progress;

  /// Optional progress label (e.g. "45% of target")
  final String? progressLabel;

  /// Optional leading icon for the subtitle row
  final IconData? subtitleIcon;

  /// Override the default container margin. Default matches ListView padding
  /// used across screens. Set to `EdgeInsets.zero` when parent provides spacing.
  final EdgeInsetsGeometry margin;

  const KsSummaryStrip({
    super.key,
    required this.value,
    required this.label,
    this.subtitle,
    this.subtitleSegments,
    this.progress,
    this.progressLabel,
    this.subtitleIcon,
    this.margin = const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary metric
          Text(
            value,
            style: AppTextStyles.h1.copyWith(
              color: context.ksc.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          // Progress bar
          if (progress != null && progress! > 0) ...[
            const SizedBox(height: 14),
            if (progressLabel != null)
              Text(
                progressLabel!,
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: context.ksc.primary700,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress!.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.ksc.success500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Subtitle row — colored segments have priority
          if (subtitleSegments != null || subtitle != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: context.ksc.primary700),
            const SizedBox(height: 12),
            _buildSubtitle(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final iconColor = context.ksc.neutral500;
    final textStyle = AppTextStyles.caption.copyWith(
      color: context.ksc.neutral400,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    // Colored segments mode
    if (subtitleSegments != null && subtitleSegments!.isNotEmpty) {
      final segments = subtitleSegments!;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          if (subtitleIcon != null)
            Icon(subtitleIcon, size: 12, color: iconColor),
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Text('●', style: textStyle.copyWith(color: iconColor)),
            const SizedBox(width: 4),
            Text(
              segments[i].text,
              style: textStyle.copyWith(
                color: segments[i].color ?? context.ksc.neutral400,
              ),
            ),
          ],
        ],
      );
    }

    // Legacy plain text mode
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        if (subtitleIcon != null)
          Icon(subtitleIcon, size: 12, color: iconColor),
        Text(subtitle!, style: textStyle),
      ],
    );
  }
}

/// A single text segment with an optional color for [KsSummaryStrip.subtitleSegments].
class KsSubtitleSegment {
  /// The segment text (e.g. "3 unpaid")
  final String text;

  /// Optional color for this segment. When null, uses the default [KsSummaryStrip]
  /// subtitle text color (`neutral400`).
  final Color? color;

  const KsSubtitleSegment(this.text, {this.color});
}
