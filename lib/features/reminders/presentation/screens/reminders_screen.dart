import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../providers/reminders_provider.dart';
import '../../domain/models/reminder_model.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final all = state.reminders;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: 'REMINDERS', showBack: true),
      body: all.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _ReminderCard(
                reminder: all[i],
                onDismiss: () =>
                    ref.read(remindersProvider.notifier).dismiss(all[i].jobId, all[i].type),
              ),
            ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDismiss;

  const _ReminderCard({required this.reminder, required this.onDismiss});

  Color _accentColor(BuildContext context) {
    switch (reminder.type) {
      case ReminderType.unpaidJob:       return context.ksc.error500;
      case ReminderType.stuckInProgress: return context.ksc.warning500;
      case ReminderType.followUpPending: return context.ksc.primary400;
      case ReminderType.followUpNoResponse: return context.ksc.primary400;
    }
  }

  IconData get _icon {
    switch (reminder.type) {
      case ReminderType.unpaidJob:       return LineAwesomeIcons.exclamation_triangle_solid;
      case ReminderType.stuckInProgress: return LineAwesomeIcons.clock_solid;
      case ReminderType.followUpPending: return LineAwesomeIcons.whatsapp;
      case ReminderType.followUpNoResponse: return LineAwesomeIcons.comment_dots;
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
          onTap: isDismissed ? null : () => context.push(RouteNames.jobDetail(reminder.jobId)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
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
                if (!isDismissed)
                  IconButton(
                    icon: Icon(LineAwesomeIcons.times_solid, size: 16, color: context.ksc.neutral500),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  )
                else
                  Icon(LineAwesomeIcons.check_solid, size: 14, color: context.ksc.neutral600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.check_circle_solid, size: 64, color: context.ksc.success500),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'ALL CLEAR',
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white, letterSpacing: 1.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No reminders right now.',
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
