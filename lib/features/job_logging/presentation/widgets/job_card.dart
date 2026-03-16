import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_enums.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

class JobCard extends StatelessWidget {
  final JobEntity job;
  final CustomerEntity? customer; // Changed from String? customerName
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.customer, this.onTap});

  IconData _serviceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return LineAwesomeIcons.car_solid;
      case ServiceType.doorLockInstallation:  return LineAwesomeIcons.door_closed_solid;
      case ServiceType.doorLockRepair:        return LineAwesomeIcons.tools_solid;
      case ServiceType.smartLockInstallation: return LineAwesomeIcons.lock_solid;
    }
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return "CAR KEY PROGRAMMING";
      case ServiceType.doorLockInstallation:  return "DOOR LOCK INSTALLATION";
      case ServiceType.doorLockRepair:        return "DOOR LOCK REPAIR";
      case ServiceType.smartLockInstallation: return "SMART LOCK INSTALLATION";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_serviceIcon(job.serviceType), size: 20, color: AppColors.accent500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _serviceLabel(job.serviceType),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                  )
                ),
                Text(
                  DateFormatter.short(job.jobDate).toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w700)
                ),
                if (job.followUpSent) ...[
                  const SizedBox(width: 4),
                  const Icon(LineAwesomeIcons.check_double_solid, size: 14, color: Colors.greenAccent),
                ],
              ],
            ),
            if (customer != null) ...[
              const SizedBox(height: 12),
              Text(customer?.fullName ?? "Deleted Customer", style: AppTextStyles.body.copyWith(color: AppColors.neutral400, fontWeight: FontWeight.w600)),
            ],
            if (job.hasLocation || job.hasAmount) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (job.hasLocation) Expanded(child: Row(children: [
                    const Icon(LineAwesomeIcons.map_marker_solid, size: 14, color: AppColors.neutral500),
                    const SizedBox(width: 4),
                    Flexible(child: Text(job.location!, style: AppTextStyles.caption.copyWith(color: AppColors.neutral400), overflow: TextOverflow.ellipsis)),
                  ])),
                  if (job.hasAmount) Text(CurrencyFormatter.formatShort(job.amountCharged!), style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
            if (job.followUpSent || job.syncStatus != SyncStatus.synced) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (job.followUpSent) const _Badge(label: "FOLLOW-UP SENT", color: Colors.greenAccent, icon: LineAwesomeIcons.check_circle_solid),
                  
                  if (job.syncStatus == SyncStatus.pending) 
                    Tooltip(
                      message: (customer != null && customer!.isFailed) 
                        ? "Waiting for Customer sync to complete." 
                        : "Waiting for network to sync...",
                      child: const _Badge(label: "SAVING...", color: Colors.orangeAccent, icon: LineAwesomeIcons.sync_solid),
                    ),

                  if (job.syncStatus == SyncStatus.failed)
                    Tooltip(
                      message: "${job.syncErrorMessage ?? "Sync failed"} - Pull to refresh to retry",
                      child: const _Badge(label: "SYNC FAILED", color: Colors.redAccent, icon: LineAwesomeIcons.exclamation_circle_solid),
                    ),
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
  final Color color;
  final IconData icon;

  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]
      ),
    );
  }
}
