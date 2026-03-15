import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../providers/job_providers.dart';
import '../widgets/service_type_picker.dart';

class LogJobScreen extends ConsumerStatefulWidget {
  final String? preSelectedCustomerId;
  const LogJobScreen({super.key, this.preSelectedCustomerId});

  @override
  ConsumerState<LogJobScreen> createState() => _LogJobScreenState();
}

class _LogJobScreenState extends ConsumerState<LogJobScreen> {
  ServiceType? _serviceType;
  String? _finalCustomerId;

  final _customerController = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController   = TextEditingController();
  final _notesController    = TextEditingController();

  final ValueNotifier<bool> _canSaveNotifier = ValueNotifier(false);
  DateTime _jobDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _customerController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    if (widget.preSelectedCustomerId != null) {
      _finalCustomerId = widget.preSelectedCustomerId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final customer = await ref.read(customerDetailProvider(widget.preSelectedCustomerId!).future);
        if (customer != null) {
          setState(() {
            _customerController.text = customer.fullName;
            if (customer.location != null) _locationController.text = customer.location!;
          });
        }
      });
    }
  }

  void _validateForm() {
    final canSave = _serviceType != null &&
        _customerController.text.trim().isNotEmpty &&
        (widget.preSelectedCustomerId != null || _phoneController.text.trim().isNotEmpty);
    if (_canSaveNotifier.value != canSave) _canSaveNotifier.value = canSave;
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _canSaveNotifier.dispose();
    super.dispose();
  }

  // Task 1: Check if form has data before allowing pop
  bool get _isDirty => _serviceType != null || 
                      _customerController.text.isNotEmpty || 
                      _amountController.text.isNotEmpty || 
                      _notesController.text.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primary800,
        title: Text('DISCARD DRAFT?', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Your entered job details will be lost. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KEEP EDITING')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DISCARD', style: TextStyle(color: AppColors.error500, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    final amountText = _amountController.text.trim();
    final job = await ref.read(logJobProvider.notifier).save(
      serviceType: _serviceType!,
      existingCustomerId: _finalCustomerId,
      newCustomerName: _finalCustomerId == null ? _customerController.text.trim() : null,
      customerPhone: _finalCustomerId == null ? _phoneController.text.trim() : null,
      jobDate: _jobDate,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      amountChargedString: amountText,
    );

    if (!mounted) return;
    if (job != null) {
      ref.read(jobListProvider.notifier).addJob(job);
      context.pop();
      KsSnackbar.show(context, message: job.isSynced ? "Job saved" : "Saved locally.", type: KsSnackbarType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logJobProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false, // Always intercept to check _isDirty
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary900,
        appBar: const KsAppBar(title: "ADD NEW JOB", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SELECT SERVICE", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ServiceTypePicker(
                      selected: _serviceType,
                      onSelected: (t) { setState(() => _serviceType = t); _validateForm(); }
                    ),
                    const SizedBox(height: 32),
                    _buildDarkField(label: "Customer Name", hint: "Kwame Mensah", controller: _customerController, readOnly: widget.preSelectedCustomerId != null),
                    if (widget.preSelectedCustomerId == null) ...[
                      const SizedBox(height: 24),
                      _buildDarkField(label: "Phone Number", hint: "024 123 4567", controller: _phoneController, type: TextInputType.phone),
                    ],
                    const SizedBox(height: 24),
                    _buildDarkField(label: "Location", hint: "East Legon, Accra", controller: _locationController),
                    const SizedBox(height: 24),
                    _buildDarkField(label: "Amount (GHS)", hint: "350", controller: _amountController, type: TextInputType.number),
                    const SizedBox(height: 24),
                    _buildDarkField(label: "Notes", hint: "Specific hardware used...", controller: _notesController, maxLines: 3),
                    const SizedBox(height: 24),
                    Text("DATE", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _jobDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                        if (picked != null) setState(() => _jobDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.primary800, borderRadius: BorderRadius.circular(4)),
                        child: Row(children: [
                          const Icon(LineAwesomeIcons.calendar, size: 20, color: AppColors.accent500),
                          const SizedBox(width: 12),
                          Text(_jobDate.toIso8601String().split('T').first, style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            if (!keyboardVisible)
              ValueListenableBuilder<bool>(
                valueListenable: _canSaveNotifier,
                builder: (context, canSave, _) => Container(
                  width: double.infinity,
                  color: AppColors.primary700,
                  padding: const EdgeInsets.all(24.0),
                  child: SafeArea(
                    top: false,
                    child: InkWell(
                      onTap: canSave && !state.isLoading ? _onSave : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('SAVE JOB', style: AppTextStyles.h2.copyWith(color: canSave ? Colors.white : Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w900)),
                          if (state.isLoading) const CircularProgressIndicator(color: AppColors.accent500)
                          else const Icon(LineAwesomeIcons.arrow_right_solid, color: AppColors.accent500),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkField({required String label, required String hint, required TextEditingController controller, TextInputType type = TextInputType.text, int maxLines = 1, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            readOnly: readOnly,
            style: AppTextStyles.bodyLarge.copyWith(color: readOnly ? AppColors.neutral500 : Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)), contentPadding: const EdgeInsets.all(16), border: InputBorder.none, filled: true, fillColor: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
