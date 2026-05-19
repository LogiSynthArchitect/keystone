import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/router/route_names.dart';
import '../providers/recurring_schedule_provider.dart';
import '../../domain/entities/recurring_schedule_entity.dart';

class RecurringSchedulesScreen extends ConsumerStatefulWidget {
  const RecurringSchedulesScreen({super.key});
  @override
  ConsumerState<RecurringSchedulesScreen> createState() => _RecurringSchedulesScreenState();
}

class _RecurringSchedulesScreenState extends ConsumerState<RecurringSchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringScheduleProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(recurringScheduleProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "RECURRING JOBS", showBack: true),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error loading", style: TextStyle(color: context.ksc.error500))),
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LineAwesomeIcons.calendar_solid, color: context.ksc.neutral500, size: 48),
                  const SizedBox(height: 16),
                  Text("NO SCHEDULES", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text("Set up recurring jobs for regular clients", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (_, i) => _buildCard(schedules[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/jobs/new?recurring=true'),
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
    );
  }

  Widget _buildCard(RecurringScheduleEntity s) {
    final due = s.isDue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: due ? context.ksc.accent500.withValues(alpha: 0.5) : context.ksc.primary700),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () {
            KsConfirmDialog.show(context,
              title: "DELETE SCHEDULE",
              message: "Remove recurring schedule for ${s.customerName}?",
              confirmLabel: "DELETE",
              cancelLabel: "CANCEL",
              isDanger: true,
              onConfirm: () {
                ref.read(recurringScheduleProvider.notifier).delete(s.id);
                KsSnackbar.show(context, message: "Schedule deleted", type: KsSnackbarType.success);
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: due ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.neutral500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(LineAwesomeIcons.calendar_check_solid, color: due ? context.ksc.accent500 : context.ksc.neutral500, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.serviceType.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(s.customerName, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                      Text("${s.intervalLabel} · Next: ${DateFormatter.short(s.nextDueDate)}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                    ],
                  ),
                ),
                if (due)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: context.ksc.accent500, borderRadius: BorderRadius.circular(4)),
                    child: Text("DUE", style: AppTextStyles.caption.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, fontSize: 9)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
