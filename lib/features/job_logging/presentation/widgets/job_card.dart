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

/// Job list card — info only, no action buttons.
///
/// Layout: left accent → [icon box | service + name + meta | amount] → badge row
class JobCard extends StatelessWidget {
  final JobEntity job;
  final CustomerEntity? customer;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.customer, this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'quoted':       return const Color(0xFFC8A84E);
      case 'in_progress':  return const Color(0xFF6BB5FF);
      case 'completed':    return const Color(0xFF4CAF50);
      case 'invoiced':     return const Color(0xFFB388FF);
      default:             return const Color(0xFF4A5A6A);
    }
  }

  KsBadgeVariant _badgeVariant(String status) {
    switch (status) {
      case 'completed': return KsBadgeVariant.success;
      case 'invoiced':  return KsBadgeVariant.success;
      case 'quoted':    return KsBadgeVariant.info;
      case 'in_progress': return KsBadgeVariant.neutral;
      default:          return KsBadgeVariant.neutral;
    }
  }

  KsBadgeVariant _paymentVariant(String status) {
    switch (status) {
      case 'paid':    return KsBadgeVariant.success;
      case 'partial': return KsBadgeVariant.warning;
      default:        return KsBadgeVariant.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _statusColor(job.status);

    // Resolve service icon from service type name via icon mapping
    final serviceIcon = _inferIcon(job.serviceType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + info + amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(serviceIcon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  // Service + name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service type label
                        Text(
                          job.serviceType.replaceAll('_', ' ').toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral500,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Customer name
                        if (customer != null)
                          Text(
                            customer!.fullName,
                            style: AppTextStyles.body.copyWith(
                              color: context.ksc.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        // Meta: date + location
                        Row(
                          children: [
                            Text(
                              DateFormatter.short(job.jobDate),
                              style: AppTextStyles.caption.copyWith(
                                color: context.ksc.neutral500,
                                fontSize: 9,
                              ),
                            ),
                            if (job.hasLocation) ...[
                              const SizedBox(width: 6),
                              Icon(LineAwesomeIcons.map_marker_solid, size: 10, color: context.ksc.neutral500),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  job.location!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: context.ksc.neutral500,
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            SyncStatusIndicator(status: job.syncStatus, size: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  if (job.hasAmount)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatShort(job.amountCharged!),
                          style: AppTextStyles.body.copyWith(
                            color: context.ksc.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text("AMOUNT",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral500,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Badge row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  KsBadge(
                    label: job.status.replaceAll('_', ' ').toUpperCase(),
                    variant: _badgeVariant(job.status),
                  ),
                  KsBadge(
                    label: job.paymentStatus.toUpperCase(),
                    variant: _paymentVariant(job.paymentStatus),
                  ),
                  if (job.followUpSent)
                    KsBadge(
                      label: 'WHATSAPP',
                      variant: KsBadgeVariant.success,
                      icon: LineAwesomeIcons.check_circle_solid,
                    ),
                  if (job.syncStatus == SyncStatus.failed)
                    KsBadge(
                      label: 'SAVE FAILED',
                      variant: KsBadgeVariant.error,
                      icon: LineAwesomeIcons.exclamation_circle_solid,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Map service type slug to an appropriate icon.
  /// Covers known service types; falls back to tools icon.
  IconData _inferIcon(String type) {
    switch (type) {
      case 'cctv_installation':
      case 'cctv':
        return LineAwesomeIcons.video_solid;
      case 'electric_fence_installation':
      case 'electric_fence':
        return LineAwesomeIcons.bolt_solid;
      case 'intercom_systems':
      case 'intercom':
        return LineAwesomeIcons.phone_volume_solid;
      case 'eviction_services':
      case 'eviction':
        return LineAwesomeIcons.shield_alt_solid;
      case 'ignition_repair':
      case 'ignition':
        return LineAwesomeIcons.car_solid;
      case 'burglar_alarms':
      case 'alarm':
        return LineAwesomeIcons.bell_solid;
      case 'car_lock_programming':
      case 'key_programming':
        return LineAwesomeIcons.key_solid;
      case 'door_lock_installation':
      case 'door_installation':
        return LineAwesomeIcons.door_closed_solid;
      case 'door_lock_repair':
      case 'door_repair':
        return LineAwesomeIcons.tools_solid;
      case 'smart_lock_installation':
      case 'smart_lock':
        return LineAwesomeIcons.lock_solid;
      default:
        return LineAwesomeIcons.tools_solid;
    }
  }
}
