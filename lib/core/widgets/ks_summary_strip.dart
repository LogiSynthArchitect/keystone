import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// A reusable summary strip card for list screens.
///
/// Shows a primary metric (big number + label), optional progress bar,
/// and a secondary stats row. Designed to be the first thing a user sees
/// when entering any list screen — gives them "the shape of the data."
///
/// Usage:
/// ```dart
/// KsSummaryStrip(
///   value: totalCount.toString(),
///   label: "ALL CUSTOMERS",
///   subtitle: "$repeatCount repeat ● $pendingSyncCount pending",
/// )
/// ```
class KsSummaryStrip extends StatelessWidget {
  /// The primary display value (e.g. "38" or "¢12,500")
  final String value;

  /// Label under the value (e.g. "ALL CUSTOMERS")
  final String label;

  /// Optional secondary info shown below the divider
  final String? subtitle;

  /// Optional progress fraction 0.0–1.0 (shows a progress bar when set)
  final double? progress;

  /// Optional progress label (e.g. "45% of target")
  final String? progressLabel;

  /// Optional leading icon for the subtitle row
  final IconData? subtitleIcon;

  const KsSummaryStrip({
    super.key,
    required this.value,
    required this.label,
    this.subtitle,
    this.progress,
    this.progressLabel,
    this.subtitleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
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
          // Subtitle row
          if (subtitle != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: context.ksc.primary700),
            const SizedBox(height: 12),
            Row(
              children: [
                if (subtitleIcon != null) ...[
                  Icon(subtitleIcon, size: 12, color: context.ksc.neutral500),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral400,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
