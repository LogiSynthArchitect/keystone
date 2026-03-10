import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_text_field.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../providers/job_providers.dart';
import '../widgets/service_type_picker.dart';

class LogJobScreen extends ConsumerStatefulWidget {
  const LogJobScreen({super.key});
  @override
  ConsumerState<LogJobScreen> createState() => _LogJobScreenState();
}

class _LogJobScreenState extends ConsumerState<LogJobScreen> {
  ServiceType? _serviceType;
  final _customerController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController   = TextEditingController();
  final _notesController    = TextEditingController();
  DateTime _jobDate = DateTime.now();

  @override
  void dispose() {
    _customerController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _serviceType != null ||
      _customerController.text.trim().isNotEmpty ||
      _locationController.text.trim().isNotEmpty ||
      _amountController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty;

  bool get _canSave => _serviceType != null && _customerController.text.trim().isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Leave anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard', style: TextStyle(color: AppColors.error600))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _jobDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary700, onPrimary: AppColors.white, surface: AppColors.white)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _jobDate = picked);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return "Today";
    if (target == today.subtract(const Duration(days: 1))) return "Yesterday";
    const months = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  Future<void> _onSave() async {
    final notifier = ref.read(logJobProvider.notifier);
    final amount = CurrencyFormatter.parse(_amountController.text.trim());
    final job = await notifier.save(
      serviceType: _serviceType!,
      customerId: _customerController.text.trim(),
      jobDate: _jobDate,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      amountCharged: amount,
    );
    if (!mounted) return;
    if (job != null) {
      ref.read(jobListProvider.notifier).addJob(job);
      context.pop();
      KsSnackbar.show(context, message: job.isSynced ? "Job saved." : "Saved. Will sync when online.", type: job.isSynced ? KsSnackbarType.success : KsSnackbarType.info);
    } else {
      final error = ref.read(logJobProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save job.", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logJobProvider);
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.neutral050,
        appBar: const KsAppBar(title: "Log a job", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text("Service", style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral700)),
                    const SizedBox(height: AppSpacing.sm),
                    ServiceTypePicker(selected: _serviceType, onSelected: (t) => setState(() => _serviceType = t)),
                    const SizedBox(height: AppSpacing.xl),
                    KsTextField(label: "Customer name", hint: "Kwame Mensah", controller: _customerController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Location", hint: "East Legon, Accra", controller: _locationController, textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Amount charged (GHS)", hint: "350", type: KsTextFieldType.amount, controller: _amountController, textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Notes", hint: "Car model, key type, solution used...", type: KsTextFieldType.multiline, controller: _notesController, textInputAction: TextInputAction.done),
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.neutral300)),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.neutral500),
                          const SizedBox(width: AppSpacing.sm),
                          Text(_formatDate(_jobDate), style: AppTextStyles.body.copyWith(color: AppColors.neutral700)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    KsButton(label: "Save job", onPressed: _canSave && !state.isLoading ? _onSave : null, isLoading: state.isLoading),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
