import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_bottom_sheet_scaffold.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_hardware_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../domain/usecases/recovery_save_usecase.dart';
import '../providers/job_providers.dart';

/// Bottom sheet that shows the status of each child type for an incomplete job
/// and lets the user trigger [RecoverySaveUsecase] to flip subEntitiesSaved → true.
///
/// Uses [KsBottomSheetScaffold] for consistent chrome (drag handle, header,
/// scrollable body, gold bottom bar).
///
/// Triggered by tapping the "INCOMPLETE" badge on a [JobCard] whose
/// [JobEntity.subEntitiesSaved] is `false`.
class JobRecoverySheet extends ConsumerWidget {
  final JobEntity job;

  const JobRecoverySheet({super.key, required this.job});

  /// Show as a modal bottom sheet.
  static Future<void> show(BuildContext context, JobEntity job) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => JobRecoverySheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KsBottomSheetScaffold(
      title: '⚠️ INCOMPLETE JOB',
      subtitle: 'This job was interrupted during save. '
          'All data is already on this device — tap RECOVER to finalize it.',
      isDirty: _kNeverDirtyBool,
      contentBuilder: (ctx, _) => _buildContent(context),
      bottomLabel: 'RECOVER JOB',
      bottomIcon: LineAwesomeIcons.check_circle_solid,
      onDone: () => _onRecover(context, ref),
    );
  }

  static bool _kNeverDirtyBool() => false;

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── Job summary card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.short(job.jobDate),
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral400,
                  fontSize: 11,
                ),
              ),
              if (job.hasAmount) ...[
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatShort(job.amountCharged!),
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Child type list (static — data loaded at recover time) ──
        _infoRow(context, LineAwesomeIcons.wrench_solid, 'Services'),
        const SizedBox(height: 10),
        _infoRow(context, LineAwesomeIcons.cogs_solid, 'Parts'),
        const SizedBox(height: 10),
        _infoRow(context, LineAwesomeIcons.microchip_solid, 'Hardware'),
        const SizedBox(height: 10),
        _infoRow(context, LineAwesomeIcons.money_bill_solid, 'Expenses'),

        const SizedBox(height: 24),

        // ── Info note ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.ksc.primary900.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ksc.neutral700),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LineAwesomeIcons.info_circle_solid,
                  size: 14, color: context.ksc.accent500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recovering does NOT sync to the server — it only saves locally. '
                  'The job will sync on the next connection.',
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext c, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.ksc.primary900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.ksc.neutral400),
          const SizedBox(width: 10),
          Text(label,
            style: AppTextStyles.caption.copyWith(
              color: c.ksc.neutral300,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Icon(
            LineAwesomeIcons.check_circle_solid,
            size: 14,
            color: c.ksc.success500,
          ),
        ],
      ),
    );
  }

  Future<void> _onRecover(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(jobRepositoryProvider);
      final invRepo = ref.read(inventoryRepositoryProvider);
      final usecase = RecoverySaveUsecase(repo, invRepo);

      // Load whatever children survived the crash
      final services = await repo.getServicesForJob(job.id);
      final parts = await repo.getPartsForJob(job.id);
      final hardware = await repo.getHardwareForJob(job.id);
      final expenses = await repo.getExpensesForJob(job.id);

      await usecase(RecoverySaveParams(
        jobId: job.id,
        userId: job.userId,
        services: services,
        parts: parts,
        hardware: hardware,
        expenses: expenses,
      ));

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job recovered — ready to sync.'),
            backgroundColor: context.ksc.success500,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recovery failed: $e'),
            backgroundColor: context.ksc.error500,
          ),
        );
      }
    }
  }
}
