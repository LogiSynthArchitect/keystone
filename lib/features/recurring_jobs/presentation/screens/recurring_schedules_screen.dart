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
import '../../../../core/widgets/ks_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../features/job_logging/presentation/widgets/service_picker_dropdown.dart';
import '../../../../features/job_logging/presentation/widgets/customer_picker_dropdown.dart';
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

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterInterval = 'all';
  String _filterStatus = 'all';
  bool get _hasActiveFilter => _searchQuery.isNotEmpty || _filterInterval != 'all' || _filterStatus != 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecurringScheduleEntity> _applyFilters(List<RecurringScheduleEntity> schedules) {
    var result = schedules;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) =>
        s.customerName.toLowerCase().contains(q) ||
        s.serviceType.toLowerCase().contains(q)
      ).toList();
    }
    if (_filterInterval != 'all') {
      result = result.where((s) => s.intervalType == _filterInterval).toList();
    }
    if (_filterStatus != 'all') {
      result = result.where((s) =>
        _filterStatus == 'active' ? s.isActive : !s.isActive
      ).toList();
    }
    return result;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        var draftInterval = _filterInterval;
        var draftStatus = _filterStatus;
        return StatefulBuilder(
          builder: (context, setInnerState) => KsFilterSheet(
            title: "FILTER SCHEDULES",
            onApply: () => setState(() {
              _filterInterval = draftInterval;
              _filterStatus = draftStatus;
            }),
            onClear: () {
              draftInterval = 'all';
              draftStatus = 'all';
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "INTERVAL",
                selected: draftInterval,
                onSelect: (v) => setInnerState(() => draftInterval = v ?? 'all'),
                options: const [
                  KsFilterOption(value: 'all', display: 'ALL'),
                  KsFilterOption(value: 'weekly', display: 'WEEKLY'),
                  KsFilterOption(value: 'monthly', display: 'MONTHLY'),
                  KsFilterOption(value: 'quarterly', display: 'QUARTERLY'),
                  KsFilterOption(value: 'yearly', display: 'YEARLY'),
                ],
              ),
              KsFilterChipGroup(
                label: "STATUS",
                selected: draftStatus,
                onSelect: (v) => setInnerState(() => draftStatus = v ?? 'all'),
                options: const [
                  KsFilterOption(value: 'all', display: 'ALL'),
                  KsFilterOption(value: 'active', display: 'ACTIVE'),
                  KsFilterOption(value: 'paused', display: 'PAUSED'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSchedule() {
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
    var isSubmitting = false;

    final _drawer = KsBottomSheetScaffold.show<void>(
      context,
      title: "ADD RECURRING SCHEDULE",
      subtitle: "Set up a new recurring service schedule",
      isDirty: () => selectedCustomer != null || selectedService != null || notesCtrl.text.isNotEmpty,
      contentBuilder: (ctx, setSheetState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // ── Customer ──
          CustomerPickerDropdown(
            selected: selectedCustomer,
            customers: customers,
            onSelected: (c) {
              setSheetState(() => selectedCustomer = c?.fullName.isNotEmpty == true ? c : null);
            },
          ),
          const SizedBox(height: 24),
          // ── Service type ──
          ServicePickerDropdown(
            selected: selectedService?.name,
            onSelected: (name) {
              setSheetState(() => selectedService = services.firstWhere((s) => s.name == name));
            },
          ),
          const SizedBox(height: 24),
          // ── Interval ──
          KsFilterChipGroup(
            label: "INTERVAL *",
            options: const [
              KsFilterOption(value: 'weekly', display: 'WEEKLY'),
              KsFilterOption(value: 'monthly', display: 'MONTHLY'),
              KsFilterOption(value: 'quarterly', display: 'QUARTERLY'),
              KsFilterOption(value: 'yearly', display: 'YEARLY'),
            ],
            selected: interval,
            onSelect: (v) {
              if (v != null) setSheetState(() => interval = v);
            },
            borderRadius: 4,
            unselectedColor: context.ksc.primary900,
          ),
          const SizedBox(height: 24),
          // ── Start date ──
          Text("START DATE *",
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                builder: (_, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    dialogTheme: DialogThemeData(backgroundColor: context.ksc.primary800),
                    datePickerTheme: DatePickerThemeData(
                      backgroundColor: context.ksc.primary800,
                      headerBackgroundColor: context.ksc.primary900,
                      todayForegroundColor: WidgetStatePropertyAll(context.ksc.accent500),
                      dayForegroundColor: WidgetStatePropertyAll(context.ksc.white),
                    ),
                  ),
                  child: child!,
                ),
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
              child: Text(DateFormatter.short(startDate),
                style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white)),
            ),
          ),
          const SizedBox(height: 24),
          // ── Notes ──
          Text("NOTES",
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0)),
          const SizedBox(height: 6),
          TextField(
            controller: notesCtrl,
            maxLines: null,
            minLines: 3,
            style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white),
            decoration: InputDecoration(
              hintText: "Optional notes",
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral600),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.ksc.primary700),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.ksc.accent500),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: context.ksc.primary700),
              ),
              filled: false,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomWidget: (ctx, setSheetState) => Container(
        width: double.infinity,
        color: context.ksc.accent500,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSubmitting
                ? null
                : () async {
                    setSheetState(() => isSubmitting = true);
                    if (selectedCustomer == null || selectedService == null) {
                      KsSlidingNotification.show(ctx,
                        message: "Select a customer and service type",
                        type: KsNotificationType.error);
                      setSheetState(() => isSubmitting = false);
                      return;
                    }
                    final userId = ref.read(currentUserProvider).valueOrNull?.id;
                    if (userId == null) {
                      setSheetState(() => isSubmitting = false);
                      return;
                    }
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
                    if (mounted) {
                      KsSlidingNotification.show(context,
                        message: "Recurring schedule created",
                        type: KsNotificationType.success);
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("CREATE SCHEDULE",
                    style: AppTextStyles.body.copyWith(
                      color: context.ksc.primary900,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.0,
                    ),
                  ),
                  isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.ksc.primary900,
                          ),
                        )
                      : Icon(
                          LineAwesomeIcons.arrow_right_solid,
                          color: context.ksc.primary900,
                          size: 20,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _drawer.whenComplete(() => notesCtrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(recurringScheduleProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "RECURRING JOBS",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.filter_solid,
              color: _hasActiveFilter ? context.ksc.accent500 : context.ksc.neutral400,
              size: 22),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: KsSearchBar(
              hint: "Search customer or service...",
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KsOfflineBanner(),
          schedulesAsync.whenOrNull(
            data: (schedules) {
              final filtered = _applyFilters(schedules);
              final active = filtered.where((s) => s.isActive).length;
              final due = filtered.where((s) => s.isDue).length;
              return KsSummaryStrip(
                value: _hasActiveFilter ? '${filtered.length}' : '${schedules.length}',
                label: _hasActiveFilter ? "FILTERED" : "RECURRING SCHEDULES",
                subtitleSegments: [
                  KsSubtitleSegment('$active active', color: context.ksc.success500),
                  KsSubtitleSegment('$due due now', color: context.ksc.error500),
                ],
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
          final filtered = _applyFilters(schedules);
          if (schedules.isEmpty) {
            return KsEmptyState(
              icon: LineAwesomeIcons.calendar_solid,
              title: "NO SCHEDULES YET",
              subtitle: "Set up recurring jobs for regular clients.\nTap + below to add your first schedule.",
            );
          }
          if (filtered.isEmpty) {
            return KsEmptyState(
              icon: LineAwesomeIcons.search_minus_solid,
              title: "NO RESULTS FOUND",
              subtitle: _searchQuery.isNotEmpty
                  ? 'Search yielded zero results for "$_searchQuery".'
                  : "No schedules match the current filters.",
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildCard(filtered[i]),
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
