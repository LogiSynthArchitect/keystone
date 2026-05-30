import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/ks_colors.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../features/reminders/domain/models/reminder_model.dart';

/// Reusable reminder card with type-colored accent, icon, details, and actions.
///
/// Matches the visual contract of JobCard — colored left accent, icon,
/// title/subtitle, trailing dismiss/resend actions.
class KsReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDismiss;
  final VoidCallback? onResend;

  const KsReminderCard({
    super.key,
    required this.reminder,
    required this.onDismiss,
    this.onResend,
  });

  Color _accentColor(BuildContext context) {
    switch (reminder.type) {
      case ReminderType.unpaidJob:            return context.ksc.error500;
      case ReminderType.stuckInProgress:      return context.ksc.warning500;
      case ReminderType.followUpPending:      return context.ksc.primary400;
      case ReminderType.followUpNoResponse:   return context.ksc.primary400;
      case ReminderType.recurringJobOverdue:  return context.ksc.accent500;
    }
  }

  IconData get _icon {
    switch (reminder.type) {
      case ReminderType.unpaidJob:            return LineAwesomeIcons.exclamation_triangle_solid;
      case ReminderType.stuckInProgress:      return LineAwesomeIcons.clock_solid;
      case ReminderType.followUpPending:      return LineAwesomeIcons.whatsapp;
      case ReminderType.followUpNoResponse:   return LineAwesomeIcons.comment_dots;
      case ReminderType.recurringJobOverdue:  return LineAwesomeIcons.calendar_check_solid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    final isDismissed = reminder.isDismissed;

    return Opacity(
      opacity: isDismissed ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isDismissed ? context.ksc.primary700 : accent.withAlpha(60),
          ),
        ),
        child: InkWell(
          onTap: isDismissed ? null : onResend ?? () {},
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(_icon, size: 18, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.type.label,
                        style: AppTextStyles.captionMedium.copyWith(
                          color: isDismissed ? context.ksc.neutral600 : accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reminder.jobServiceType,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDismissed ? context.ksc.neutral600 : context.ksc.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormatter.relative(reminder.jobDate),
                            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                          ),
                          if (reminder.amountCharged != null) ...[
                            Text(' · ', style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600)),
                            Text(
                              CurrencyFormatter.formatShort(reminder.amountCharged!),
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Trailing actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isDismissed)
                      IconButton(
                        icon: Icon(LineAwesomeIcons.times_solid, size: 16, color: context.ksc.neutral500),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      )
                    else
                      Icon(LineAwesomeIcons.check_solid, size: 14, color: context.ksc.neutral600),
                    if (!isDismissed && reminder.type == ReminderType.followUpNoResponse && onResend != null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: onResend,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.ksc.accent500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LineAwesomeIcons.whatsapp, size: 10, color: context.ksc.accent500),
                              const SizedBox(width: 4),
                              Text("RESEND", style: AppTextStyles.caption.copyWith(
                                color: context.ksc.accent500,
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
