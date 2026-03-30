import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../providers/timeline_provider.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: 'ACTIVITY',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.sync_solid, size: 18, color: context.ksc.neutral500),
            onPressed: () => ref.read(timelineProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: KsLoadingIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!, style: AppTextStyles.body.copyWith(color: context.ksc.error500)))
              : state.events.isEmpty
                  ? _EmptyState()
                  : _EventList(events: state.events),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<TimelineEvent> events;
  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final event = events[i];
        final showDate = i == 0 || !_sameDay(events[i - 1].timestamp, event.timestamp);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) _DateLabel(event.timestamp),
            _EventTile(event: event),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateLabel extends StatelessWidget {
  final DateTime date;
  const _DateLabel(this.date);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        DateFormatter.display(date).toUpperCase(),
        style: AppTextStyles.captionMedium.copyWith(
          color: context.ksc.neutral500,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final TimelineEvent event;
  const _EventTile({required this.event});

  Color _dotColor(BuildContext context) {
    switch (event.type) {
      case TimelineEventType.jobCreated:          return context.ksc.success500;
      case TimelineEventType.paymentChanged:      return context.ksc.accent500;
      case TimelineEventType.statusChanged:       return context.ksc.primary400;
      case TimelineEventType.archived:            return context.ksc.neutral500;
      case TimelineEventType.correctionRequested: return context.ksc.warning500;
      case TimelineEventType.jobEdited:           return context.ksc.neutral400;
      case TimelineEventType.followUpSent:        return context.ksc.success500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = _dotColor(context);

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(event.jobId)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + dot
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.type.label,
                            style: AppTextStyles.captionMedium.copyWith(
                              color: dot,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.description,
                            style: AppTextStyles.body.copyWith(color: context.ksc.white),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _timeString(event.timestamp),
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeString(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
            Icon(LineAwesomeIcons.history_solid, size: 64, color: context.ksc.primary700),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO ACTIVITY YET',
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.neutral600, letterSpacing: 1.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Activity will appear here as you log and edit jobs.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral700),
            ),
          ],
        ),
      ),
    );
  }
}
