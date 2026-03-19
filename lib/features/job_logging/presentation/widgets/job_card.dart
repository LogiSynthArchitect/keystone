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
  final CustomerEntity? customer; 
  final VoidCallback? onTap;

  JobCard({super.key, required this.job, this.customer, this.onTap});

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
          border: Border.all(color: AppColors.primary700),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_serviceIcon(job.serviceType), size: 18, color: AppColors.accent500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _serviceLabel(job.serviceType),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white, 
                      fontWeight: FontWeight.w800, 
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  DateFormatter.short(job.jobDate).toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral400, 
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (customer != null) 
                        Text(
                          customer?.fullName.toUpperCase() ?? "DELETED CUSTOMER", 
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white, 
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      
                      SizedBox(height: 4),
                      
                      if (job.hasLocation) 
                        Row(
                          children: [
                            Icon(LineAwesomeIcons.map_marker_solid, size: 14, color: AppColors.accent500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                job.location!.toUpperCase(), 
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.neutral400,
                                  fontWeight: FontWeight.w600,
                                ), 
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                if (job.hasAmount) 
                  Text(
                    CurrencyFormatter.formatShort(job.amountCharged!), 
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.white, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            
            if (job.followUpSent || job.syncStatus != SyncStatus.synced) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.primary700, height: 1),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (job.followUpSent) 
                        _Badge(
                          label: "WHATSAPP OPENED", 
                          color: AppColors.success500, 
                          icon: LineAwesomeIcons.check_circle_solid,
                        ),
                      
                      if (job.syncStatus == SyncStatus.pending) 
                        _Badge(
                          label: "SYNCING TO CLOUD", 
                          color: AppColors.accent500, 
                          icon: LineAwesomeIcons.sync_solid,
                        ),

                      if (job.syncStatus == SyncStatus.failed)
                        _Badge(
                          label: "SYNC FAILED", 
                          color: AppColors.error500, 
                          icon: LineAwesomeIcons.exclamation_circle_solid,
                        ),
                    ],
                  ),
                  if (job.syncStatus == SyncStatus.failed && job.syncErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        job.syncErrorMessage!.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error500,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label, 
            style: AppTextStyles.caption.copyWith(
              color: color, 
              fontWeight: FontWeight.w800, 
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
        ]
      ),
    );
  }
}
