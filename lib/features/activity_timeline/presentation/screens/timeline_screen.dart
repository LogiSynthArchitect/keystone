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
import '../../../../core/widgets/ks_empty_state.dart';
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
                  : RefreshIndicator(
                      onRefresh: () => ref.read(timelineProvider.notifier).load(),
                      child: _EventList(
                        events: state.events,
                        hasMore: state.loadedCount < state.totalCount,
                        onLoadMore: () => ref.read(timelineProvider.notifier).loadMore(),
                      ),
                    ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  const _EventList({required this.events, this.hasMore = false, this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
      itemCount: events.length + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == events.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: onLoadMore,
                icon: Icon(LineAwesomeIcons.angle_double_down_solid, size: 14, color: context.ksc.accent500),
                label: Text('LOAD OLDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.ksc.accent500, letterSpacing: 1)),
              ),
            ),
          );
        }
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
            // Timeline dot + fixed-height connector line
            SizedBox(
              width: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: context.ksc.primary700.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Content — no background container
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: dot,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Text(
                        _timeString(event.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.ksc.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.ksc.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
    return const KsEmptyState(
      icon: LineAwesomeIcons.history_solid,
      title: 'NO ACTIVITY YET',
      subtitle: 'Activity will appear here as you log and edit jobs.',
    );
  }
}
