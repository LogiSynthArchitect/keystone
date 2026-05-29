import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../domain/entities/job_entity.dart';

/// Step 2 of the Add New Job wizard: Job status + Lead source.
/// When [currentJobStatus] is set (edit mode), backward status transitions
/// are visually disabled to prevent invalid status moves.
class JobStepStatus extends ConsumerWidget {
  final String status;
  final String? leadSource;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onLeadSourceChanged;
  final String? currentJobStatus;

  const JobStepStatus({
    super.key,
    required this.status,
    required this.leadSource,
    required this.onStatusChanged,
    required this.onLeadSourceChanged,
    this.currentJobStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("JOB STATUS",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Where is this job in the workflow?",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 24),
        _buildStatusSelector(context),
        const SizedBox(height: 32),
        Text("LEAD SOURCE",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("How did the customer find you?",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 24),
        _buildLeadSourceRow(context),
      ],
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    final options = [
      ('quoted', 'QUOTED'),
      ('in_progress', 'IN PROGRESS'),
      ('completed', 'COMPLETED'),
      ('invoiced', 'INVOICED'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSelected = status == opt.$1;
        // When editing an existing job, gate each option by validateStatusTransition.
        // A null return means the transition is allowed.
        final isDisallowed = currentJobStatus != null &&
            JobEntity.validateStatusTransition(currentJobStatus, opt.$1) != null;
        return GestureDetector(
          onTap: isDisallowed ? null : () => onStatusChanged(opt.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? context.ksc.accent500
                    : isDisallowed
                        ? context.ksc.neutral700
                        : context.ksc.primary700,
              ),
            ),
            child: Text(opt.$2,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? context.ksc.accent500
                    : isDisallowed
                        ? context.ksc.neutral700
                        : context.ksc.neutral400,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeadSourceRow(BuildContext context) {
    final sources = <String, IconData>{
      'referral': LineAwesomeIcons.user_plus_solid,
      'walk_in': LineAwesomeIcons.user_solid,
      'whatsapp': LineAwesomeIcons.comment_solid,
      'repeat_customer': LineAwesomeIcons.history_solid,
      'social_media': LineAwesomeIcons.share_alt_solid,
      'phone_call': LineAwesomeIcons.phone_alt_solid,
      'online_search': LineAwesomeIcons.search_solid,
      'other': LineAwesomeIcons.ellipsis_h_solid,
    };
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: sources.entries.map((e) {
        final s = e.key;
        final icon = e.value;
        final isSel = leadSource == s;
        return GestureDetector(
          onTap: () => onLeadSourceChanged(isSel ? null : s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSel ? context.ksc.accent500 : context.ksc.primary700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: isSel ? context.ksc.accent500 : context.ksc.neutral400),
                const SizedBox(width: 6),
                Text(s.replaceAll('_', ' ').toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: isSel ? context.ksc.accent500 : context.ksc.neutral400,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
