import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_icon_well.dart';
import '../../../../core/widgets/ks_reminder_card.dart';
import '../../../../core/widgets/ks_summary_strip.dart';
import '../providers/reminders_provider.dart';
import '../../domain/models/reminder_model.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final all = state.reminders;
    final active = state.active;
    final undismissed = active.where((r) => !r.isDismissed).toList();
    final dismissed = active.where((r) => r.isDismissed).toList();

    // Compute counts per type
    final unpaidCount = undismissed.where((r) => r.type == ReminderType.unpaidJob).length;
    final stuckCount = undismissed.where((r) => r.type == ReminderType.stuckInProgress).length;
    final followUpCount = undismissed.where((r) => r.type == ReminderType.followUpPending || r.type == ReminderType.followUpNoResponse).length;
    final recurringCount = undismissed.where((r) => r.type == ReminderType.recurringJobOverdue).length;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: 'REMINDERS',
        showBack: true,
        actions: [
          if (active.isNotEmpty)
            KsIconWell(
              icon: LineAwesomeIcons.check_double_solid,
              onTap: () {
                for (final r in undismissed) {
                  ref.read(remindersProvider.notifier).dismiss(r.jobId, r.type);
                }
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (all.isEmpty)
            const Expanded(
              child: KsEmptyState(
                icon: LineAwesomeIcons.check_circle_solid,
                title: 'ALL CLEAR',
                subtitle: 'No reminders right now.',
              ),
            )
          else ...[
            // Summary strip
            KsSummaryStrip(
              icon3d: 'ef4a90-bell.png',
              value: '${active.length}',
              label: "ACTIVE REMINDERS",
              subtitleSegments: [
                if (unpaidCount > 0)
                  KsSubtitleSegment('$unpaidCount unpaid', color: context.ksc.accent500),
                if (stuckCount > 0)
                  KsSubtitleSegment('$stuckCount stuck', color: context.ksc.error500),
                if (followUpCount > 0)
                  KsSubtitleSegment('$followUpCount follow-up', color: context.ksc.warning500),
                if (recurringCount > 0)
                  KsSubtitleSegment('$recurringCount recurring', color: context.ksc.success500),
              ],
              subtitleIcon: LineAwesomeIcons.bell_solid,
            ),
            // List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  _buildSection(context, ref, "UNPAID", undismissed.where((r) => r.type == ReminderType.unpaidJob).toList()),
                  _buildSection(context, ref, "STUCK", undismissed.where((r) => r.type == ReminderType.stuckInProgress).toList()),
                  _buildSection(context, ref, "FOLLOW-UP",
                    undismissed.where((r) => r.type == ReminderType.followUpPending || r.type == ReminderType.followUpNoResponse).toList(),
                    showResend: (r) => r.type == ReminderType.followUpNoResponse,
                  ),
                  _buildSection(context, ref, "RECURRING OVERDUE", undismissed.where((r) => r.type == ReminderType.recurringJobOverdue).toList()),
                  // Dismissed section
                  if (dismissed.isNotEmpty) ...[
                    _sectionHeader(context, "DISMISSED"),
                    ...dismissed.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KsReminderCard(
                        reminder: r,
                        onDismiss: () => {},
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a section with header + KsReminderCard list (animated).
  Widget _buildSection(
    BuildContext context,
    WidgetRef ref,
    String header,
    List<Reminder> items, {
    bool Function(Reminder)? showResend,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, header),
        ...items.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: KsReminderCard(
            reminder: r,
            onDismiss: () => ref.read(remindersProvider.notifier).dismiss(r.jobId, r.type),
            onResend: showResend?.call(r) == true ? () => context.push(RouteNames.jobDetail(r.jobId)) : null,
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: context.ksc.accent500),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.caption.copyWith(
            color: context.ksc.neutral500,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          )),
        ],
      ),
    );
  }
}
