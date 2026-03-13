import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
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
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        title: Text('Discard changes?', style: AppTextStyles.h3.copyWith(color: Colors.white)),
        content: Text('You have unsaved data. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Keep editing', style: AppTextStyles.body.copyWith(color: AppColors.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Discard', style: AppTextStyles.body.copyWith(color: AppColors.error500, fontWeight: FontWeight.bold))),
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
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent500,
            onPrimary: AppColors.primary900,
            surface: AppColors.primary800,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: AppColors.primary900,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _jobDate = picked);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return "TODAY";
    if (target == today.subtract(const Duration(days: 1))) return "YESTERDAY";
    const months = ["","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
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
      KsSnackbar.show(context, message: job.isSynced ? "Job saved" : "Saved. Will sync when online.", type: job.isSynced ? KsSnackbarType.success : KsSnackbarType.info);
    } else {
      final error = ref.read(logJobProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save job.", type: KsSnackbarType.error);
    }
  }

  Widget _buildDarkField({
    required String label, 
    required String hint, 
    required TextEditingController controller, 
    TextInputType type = TextInputType.text, 
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            textInputAction: action,
            maxLines: maxLines,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
            cursorColor: AppColors.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              filled: true,                  // FIX: Transparent fill to stop white-out bug
              fillColor: Colors.transparent, // FIX: Lets the primary800 background show through
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logJobProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary900,
        appBar: const KsAppBar(title: "ADD NEW JOB", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SELECT SERVICE", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    ServiceTypePicker(selected: _serviceType, onSelected: (t) => setState(() => _serviceType = t)),
                    
                    const SizedBox(height: 32),
                    _buildDarkField(label: "Customer Name", hint: "Kwame Mensah", controller: _customerController, onChanged: (_) => setState(() {})),
                    
                    const SizedBox(height: 24),
                    _buildDarkField(label: "Location", hint: "East Legon, Accra", controller: _locationController),
                    
                    const SizedBox(height: 24),
                    _buildDarkField(label: "Amount Charged (GHS)", hint: "350", type: TextInputType.number, controller: _amountController),
                    
                    const SizedBox(height: 24),
                    _buildDarkField(label: "Notes", hint: "Hardware replaced, key code used...", maxLines: 3, action: TextInputAction.done, controller: _notesController),
                    
                    const SizedBox(height: 24),
                    Text("DATE", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary800, 
                          borderRadius: BorderRadius.circular(4), 
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                        ),
                        child: Row(children: [
                          const Icon(LineAwesomeIcons.calendar, size: 20, color: AppColors.accent500),
                          const SizedBox(width: 12),
                          Text(_formatDate(_jobDate), style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 48), // Padding before bottom bar
                  ],
                ),
              ),
            ),
            
            // Bottom Save Bar
            if (!keyboardVisible)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary700,
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                padding: const EdgeInsets.all(24.0),
                child: SafeArea(
                  top: false,
                  child: InkWell(
                    onTap: _canSave && !state.isLoading ? _onSave : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAVE JOB',
                          style: AppTextStyles.h2.copyWith(
                            color: _canSave ? AppColors.white : Colors.white.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        if (state.isLoading)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500))
                        else
                          Icon(
                            Icons.arrow_forward,
                            color: _canSave ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
