import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/whatsapp_followup/presentation/providers/follow_up_provider.dart';

/// Shows a compact status card indicating whether a follow-up was sent
/// and the current response status. Read-only — used in the COMMUNICATION
/// STATUS section on the job detail screen.
///
/// Editing and sending follow-ups happens in the drawer opened by
/// [FollowUpButton] in the bottom navigation bar.
class FollowUpMessagePreview extends ConsumerWidget {
  final JobEntity job;
  const FollowUpMessagePreview({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(followUpStatusProvider(job.id));
    final currentStatus = statusAsync.valueOrNull?.responseStatus;

    if (!job.followUpSent || currentStatus == null) {
      // ── Not sent or status not loaded yet ──
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.ksc.primary700.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(LineAwesomeIcons.whatsapp, color: context.ksc.neutral500, size: 16),
            const SizedBox(width: 10),
            Text(
              'No follow-up sent yet',
              style: AppTextStyles.body.copyWith(
                color: context.ksc.neutral500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // ── Sent — show status ──
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.ksc.primary700.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.ksc.success500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(LineAwesomeIcons.whatsapp, color: context.ksc.success500, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Follow-up sent',
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (job.followUpSentAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.display(job.followUpSentAt!),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _responseBadge(context, currentStatus),
        ],
      ),
    );
  }

  Widget _responseBadge(BuildContext context, String status) {
    Color color;
    String label;

    switch (status) {
      case 'responded':
        color = context.ksc.success500;
        label = 'RESPONDED';
        break;
      case 'no_response':
        color = context.ksc.error500;
        label = 'NO RESPONSE';
        break;
      default:
        color = context.ksc.neutral400;
        label = 'SENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
