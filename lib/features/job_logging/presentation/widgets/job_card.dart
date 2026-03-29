import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/ks_badge.dart';
import '../../../../core/widgets/sync_status_indicator.dart';
import 'package:keystone/features/customer_history/domain/entities/customer_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

class JobCard extends StatelessWidget {
  final JobEntity job;
  final CustomerEntity? customer;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.customer, this.onTap});

  IconData _serviceIcon(String type) {
    switch (type) {
      case 'car_lock_programming':    return LineAwesomeIcons.car_solid;
      case 'door_lock_installation':  return LineAwesomeIcons.door_closed_solid;
      case 'door_lock_repair':        return LineAwesomeIcons.tools_solid;
      case 'smart_lock_installation': return LineAwesomeIcons.lock_solid;
      default:                        return LineAwesomeIcons.tools_solid;
    }
  }

  String _serviceLabel(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_serviceIcon(job.serviceType), size: 18, color: context.ksc.accent500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _serviceLabel(job.serviceType),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SyncStatusIndicator(status: job.syncStatus, size: 14),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.short(job.jobDate).toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral400,
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
                            color: context.ksc.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),

                      const SizedBox(height: 4),

                      if (job.hasLocation)
                        Row(
                          children: [
                            Icon(LineAwesomeIcons.map_marker_solid, size: 14, color: context.ksc.accent500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                job.location!.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: context.ksc.neutral400,
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
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusBadge(job.status),
                const SizedBox(width: 8),
                _buildPaymentBadge(job.paymentStatus),
              ],
            ),

            if (job.followUpSent || job.syncStatus == SyncStatus.failed) ...[
              const SizedBox(height: 16),
              Divider(color: context.ksc.primary700, height: 1),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (job.followUpSent)
                        _CustomBadge(
                          label: "WHATSAPP OPENED",
                          color: context.ksc.success500,
                          icon: LineAwesomeIcons.check_circle_solid,
                        ),

                      if (job.syncStatus == SyncStatus.failed)
                        _CustomBadge(
                          label: "SAVE FAILED",
                          color: context.ksc.error500,
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
                          color: context.ksc.error500,
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

  Widget _buildStatusBadge(String status) {
    String label = status.replaceAll('_', ' ').toUpperCase();
    KsBadgeVariant variant = KsBadgeVariant.neutral;
    if (status == 'completed' || status == 'invoiced') variant = KsBadgeVariant.success;
    if (status == 'quoted') variant = KsBadgeVariant.info;
    return KsBadge(label: label, variant: variant);
  }

  Widget _buildPaymentBadge(String status) {
    String label = status.toUpperCase();
    KsBadgeVariant variant = KsBadgeVariant.error;
    if (status == 'paid') variant = KsBadgeVariant.success;
    if (status == 'partial') variant = KsBadgeVariant.warning;
    return KsBadge(label: label, variant: variant);
  }
}

class _CustomBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CustomBadge({required this.label, required this.color, required this.icon});

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
