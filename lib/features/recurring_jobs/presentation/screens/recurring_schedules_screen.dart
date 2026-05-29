import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_summary_strip.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../features/customer_history/data/models/customer_model.dart';
import '../../../../features/service_types/data/models/service_type_model.dart';
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

  void _showAddSchedule() {
    // Load customers and service types from local Hive
    final customers = HiveService.customers.values
        .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final services = HiveService.serviceTypes.values
        .map((e) => ServiceTypeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    CustomerModel? selectedCustomer;
    ServiceTypeModel? selectedService;
    String interval = 'monthly';
    DateTime startDate = DateTime.now().add(const Duration(days: 7));
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ADD RECURRING SCHEDULE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  // Customer picker
                  Text("CUSTOMER *", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.ksc.primary900,
                      border: Border(bottom: BorderSide(color: context.ksc.primary700)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCustomer?.id,
                        isExpanded: true,
                        dropdownColor: context.ksc.primary800,
                        hint: Text("Select customer", style: TextStyle(color: context.ksc.neutral500)),
                        items: customers.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.fullName, style: TextStyle(color: context.ksc.white)),
                        )).toList(),
                        onChanged: (id) {
                          setSheetState(() => selectedCustomer = customers.firstWhere((c) => c.id == id));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Service type picker
                  Text("SERVICE TYPE *", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.ksc.primary900,
                      border: Border(bottom: BorderSide(color: context.ksc.primary700)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedService?.name,
                        isExpanded: true,
                        dropdownColor: context.ksc.primary800,
                        hint: Text("Select service type", style: TextStyle(color: context.ksc.neutral500)),
                        items: services.map((s) => DropdownMenuItem(
                          value: s.name,
                          child: Text(s.name, style: TextStyle(color: context.ksc.white)),
                        )).toList(),
                        onChanged: (name) {
                          setSheetState(() => selectedService = services.firstWhere((s) => s.name == name));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Interval picker
                  Text("INTERVAL *", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['weekly', 'monthly', 'quarterly', 'yearly'].map((v) {
                      final label = v == 'weekly' ? 'WEEKLY' : v == 'monthly' ? 'MONTHLY' : v == 'quarterly' ? 'QUARTERLY' : 'YEARLY';
                      final selected = interval == v;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => interval = v),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary900,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: selected ? context.ksc.accent500 : context.ksc.primary700),
                            ),
                            child: Text(label, style: AppTextStyles.caption.copyWith(
                              color: selected ? context.ksc.accent500 : context.ksc.neutral400,
                              fontWeight: FontWeight.w900,
                            )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Start date
                  Text("START DATE *", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        builder: (ctx, child) => Theme(data: Theme.of(context).copyWith(
                          dialogBackgroundColor: context.ksc.primary800,
                          datePickerTheme: DatePickerThemeData(
                            backgroundColor: context.ksc.primary800,
                            headerBackgroundColor: context.ksc.primary900,
                            todayForegroundColor: WidgetStatePropertyAll(context.ksc.accent500),
                            dayForegroundColor: WidgetStatePropertyAll(context.ksc.white),
                          ),
                        ), child: child!),
                      );
                      if (picked != null) setSheetState(() => startDate = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        border: Border(bottom: BorderSide(color: context.ksc.primary700)),
                      ),
                      child: Text(DateFormatter.short(startDate), style: TextStyle(color: context.ksc.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  Text("NOTES", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    style: TextStyle(color: context.ksc.white),
                    decoration: InputDecoration(
                      hintText: "Optional notes",
                      hintStyle: TextStyle(color: context.ksc.neutral500),
                      filled: true,
                      fillColor: context.ksc.primary900,
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.ksc.accent500,
                        foregroundColor: context.ksc.primary900,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () async {
                        if (selectedCustomer == null || selectedService == null) {
                          KsSlidingNotification.show(ctx, message: "Select a customer and service type", type: KsNotificationType.error);
                          return;
                        }
                        final userId = ref.read(currentUserProvider).valueOrNull?.id;
                        if (userId == null) return;
                        await ref.read(recurringScheduleProvider.notifier).add(
                          customerId: selectedCustomer!.id,
                          customerName: selectedCustomer!.fullName,
                          serviceType: selectedService!.name,
                          serviceTypeId: selectedService!.id,
                          intervalType: interval,
                          nextDueDate: startDate,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          KsSlidingNotification.show(context, message: "Recurring schedule created", type: KsNotificationType.success);
                        }
                      },
                      child: Text("CREATE SCHEDULE", style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(recurringScheduleProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "RECURRING JOBS", showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KsOfflineBanner(),
          schedulesAsync.whenOrNull(
            data: (schedules) {
              final active = schedules.where((s) => s.isActive).length;
              final due = schedules.where((s) => s.isDue).length;
              return KsSummaryStrip(
                value: '${schedules.length}',
                label: "RECURRING SCHEDULES",
                subtitle: '$active active ● $due due now',
                subtitleIcon: LineAwesomeIcons.calendar_solid,
              );
            },
          ) ?? const SizedBox.shrink(),
          // Generate due jobs button
          schedulesAsync.whenOrNull(
            data: (schedules) {
              final due = schedules.where((s) => s.isActive && s.isDue).toList();
              if (due.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final count = await ref.read(recurringScheduleProvider.notifier).generateDueJobs();
                      if (context.mounted) {
                        KsSlidingNotification.show(context,
                          message: "$count job${count == 1 ? '' : 's'} created from due schedules",
                          type: KsNotificationType.success);
                      }
                    },
                    icon: const Icon(LineAwesomeIcons.magic_solid, size: 16),
                    label: Text("GENERATE ${due.length} DUE JOB${due.length == 1 ? '' : 'S'}",
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.ksc.accent500,
                      foregroundColor: context.ksc.primary900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
          Expanded(
            child: schedulesAsync.when(
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
        ),
      ],
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSchedule,
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
    // Resolve current service type name from ID (survives renames)
    final displayServiceType = s.serviceTypeId != null
        ? (HiveService.serviceTypes.values
            .map((e) => ServiceTypeModel.fromJson(Map<String, dynamic>.from(e)))
            .where((st) => st.id == s.serviceTypeId)
            .firstOrNull
            ?.name ?? s.serviceType)
        : s.serviceType;
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
                KsSlidingNotification.show(context, message: "Schedule deleted", type: KsNotificationType.success);
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
                      Text(displayServiceType.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
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
