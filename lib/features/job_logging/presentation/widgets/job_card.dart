import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/job_entity.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';

class JobCard extends StatelessWidget {
  final JobEntity job;
  final String? customerName;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.customerName, this.onTap});

  IconData _serviceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return Icons.car_repair;
      case ServiceType.doorLockInstallation:  return Icons.door_front_door_outlined;
      case ServiceType.doorLockRepair:        return Icons.lock_outlined;
      case ServiceType.smartLockInstallation: return Icons.lock_outlined;
    }
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return "Car Key Programming";
      case ServiceType.doorLockInstallation:  return "Door Lock Installation";
      case ServiceType.doorLockRepair:        return "Door Lock Repair";
      case ServiceType.smartLockInstallation: return "Smart Lock Installation";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_serviceIcon(job.serviceType), size: 20, color: AppColors.primary500),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(_serviceLabel(job.serviceType), style: AppTextStyles.bodyMedium)),
                Text(DateFormatter.short(job.jobDate), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)),
              ],
            ),
            if (customerName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(customerName!, style: AppTextStyles.body.copyWith(color: AppColors.neutral700)),
            ],
            if (job.hasLocation || job.hasAmount) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (job.hasLocation) Expanded(child: Row(children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.neutral400),
                    const SizedBox(width: 2),
                    Flexible(child: Text(job.location!, style: AppTextStyles.caption.copyWith(color: AppColors.neutral500), overflow: TextOverflow.ellipsis)),
                  ])),
                  if (job.hasAmount) Text(CurrencyFormatter.formatShort(job.amountCharged!), style: AppTextStyles.amountSmall.copyWith(color: AppColors.neutral900)),
                ],
              ),
            ],
            if (job.followUpSent || job.syncStatus != SyncStatus.synced) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (job.followUpSent) const _Badge(label: "Follow-up sent", bg: AppColors.success100, textColor: AppColors.success600, icon: Icons.check_circle_outline),
                  if (job.syncStatus == SyncStatus.pending) const _Badge(label: "Saving...", bg: AppColors.warning100, textColor: AppColors.warning600, icon: Icons.sync),
                  if (job.syncStatus == SyncStatus.failed) const _Badge(label: "Sync failed", bg: AppColors.error100, textColor: AppColors.error600, icon: Icons.sync_problem),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;
  final IconData icon;
  const _Badge({required this.label, required this.bg, required this.textColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: textColor),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: textColor)),
      ]),
    );
  }
}
