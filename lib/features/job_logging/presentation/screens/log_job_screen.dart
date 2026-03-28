import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../providers/job_providers.dart';
import '../widgets/service_type_picker.dart';

class LogJobScreen extends ConsumerStatefulWidget {
  final String? preSelectedCustomerId;
  const LogJobScreen({super.key, this.preSelectedCustomerId});

  @override
  ConsumerState<LogJobScreen> createState() => _LogJobScreenState();
}

class _LogJobScreenState extends ConsumerState<LogJobScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  ServiceType? _serviceType;
  String? _finalCustomerId;

  final _customerController = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController   = TextEditingController();
  final _notesController    = TextEditingController();

  DateTime _jobDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final preSelectedId = widget.preSelectedCustomerId;
    if (preSelectedId != null) {
      _finalCustomerId = preSelectedId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final repo = ref.read(customerRepositoryProvider);
          final customer = await repo.getCustomerById(preSelectedId);
          setState(() {
            _customerController.text = customer.fullName;
            if (customer.location != null) _locationController.text = customer.location!;
          });
        } catch (e) {
          debugPrint('[KS:LOG_JOB] Fast-prefill failed: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isDirty => _serviceType != null ||
                      _customerController.text.isNotEmpty ||
                      _amountController.text.isNotEmpty ||
                      _notesController.text.isNotEmpty;

  bool get _canMoveForward {
    final hasCustomer = _finalCustomerId != null;
    switch (_currentStep) {
      case 0: return _serviceType != null;
      case 1: return _customerController.text.trim().isNotEmpty && (hasCustomer || _phoneController.text.trim().isNotEmpty);
      case 2: return true;
      default: return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.mediumImpact();
      setState(() => _currentStep++);
    } else {
      _onSave();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _confirmDiscard().then((ok) {
        if (ok && mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text('DISCARD DRAFT?', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: Text('Your entered job details will be lost. Leave anyway?', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: context.ksc.error500, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();

    if (_finalCustomerId == null) {
      final phone = _phoneController.text.trim();
      if (phone.length != 10 || !phone.startsWith('0')) {
        if (mounted) {
          KsSnackbar.show(context, message: "Enter a valid 10-digit Ghana number starting with 0", type: KsSnackbarType.error);
        }
        return;
      }
    }

    final amountText = _amountController.text.trim();
    if (amountText.isNotEmpty) {
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        if (mounted) {
          KsSnackbar.show(context, message: "Amount must be a positive number", type: KsSnackbarType.error);
        }
        return;
      }
    }

    final job = await ref.read(logJobProvider.notifier).save(
      serviceType: _serviceType!,
      existingCustomerId: _finalCustomerId,
      newCustomerName: _finalCustomerId == null ? _customerController.text.trim() : null,
      customerPhone: _finalCustomerId == null ? PhoneFormatter.normalize(_phoneController.text.trim()) : null,
      jobDate: _jobDate,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      amountChargedString: amountText,
    );

    if (!mounted) return;
    if (job != null) {
      ref.read(logJobProvider.notifier).reset();
      context.pop();
      KsSnackbar.show(context, message: job.isSynced ? "Job saved" : "Saved locally.", type: KsSnackbarType.success);
    } else {
      final error = ref.read(logJobProvider).errorMessage;
      if (error != null && error.isNotEmpty) {
        KsSnackbar.show(context, message: error, type: KsSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logJobProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousStep();
      },
      child: Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: KsAppBar(
          title: "ADD NEW JOB",
          showBack: true,
          onBack: _previousStep,
        ),
        body: Column(
          children: [
            const KsOfflineBanner(),
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_currentStep),
                  padding: const EdgeInsets.all(24.0),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            if (!keyboardVisible) _buildBottomAction(state.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final stepLabels = ["SERVICE", "CUSTOMER", "DETAILS"];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(bottom: BorderSide(color: context.ksc.primary700)),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? context.ksc.accent500 : (isCompleted ? context.ksc.accent500.withValues(alpha: 0.2) : context.ksc.primary900),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isActive ? context.ksc.accent500 : context.ksc.primary700),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? context.ksc.primary900 : (isCompleted ? context.ksc.accent500 : context.ksc.neutral500),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Text(
                    stepLabels[index],
                    style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                ],
                if (index < _totalSteps - 1)
                  Expanded(child: Divider(color: context.ksc.primary700, indent: 8, endIndent: 8)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SELECT SERVICE TYPE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Select the type of service performed.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 32),
        ServiceTypePicker(
          selected: _serviceType,
          onSelected: (t) => setState(() => _serviceType = t),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Who is this job for?", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(label: "Customer Name", hint: "Kwame Mensah", controller: _customerController, readOnly: widget.preSelectedCustomerId != null, maxLength: 100),
        if (widget.preSelectedCustomerId == null) ...[
          const SizedBox(height: 24),
          _buildDarkField(
            label: "Phone Number",
            hint: "024 123 4567",
            controller: _phoneController,
            type: TextInputType.text,
            fieldHint: "Required for WhatsApp follow-ups.",
            isNumeric: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("JOB DETAILS", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Add location, amount charged, and any notes.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(
          label: "Location",
          hint: "East Legon, Accra",
          controller: _locationController,
          fieldHint: "Include landmarks for return service.",
          maxLength: 255,
        ),
        const SizedBox(height: 24),
        _buildDarkField(
          label: "Amount (GHS)",
          hint: "350",
          controller: _amountController,
          type: TextInputType.text,
          fieldHint: "Total charged (Hardware + Labor).",
          isNumeric: true,
          onChanged: (_) => setState(() {}),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
        ),
        const SizedBox(height: 24),
        _buildDarkField(label: "Notes", hint: "Specific hardware used...", controller: _notesController, maxLines: 3, maxLength: 2000),
        const SizedBox(height: 24),
        Text("DATE", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _jobDate, firstDate: DateTime(2024), lastDate: DateTime.now());
            if (picked != null) setState(() => _jobDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: Row(children: [
              Icon(LineAwesomeIcons.calendar, size: 20, color: context.ksc.accent500),
              const SizedBox(width: 12),
              Text(DateFormatter.short(_jobDate), style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isLoading) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canGo = _canMoveForward;

    return Container(
      width: double.infinity,
      color: context.ksc.primary700,
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: canGo && !isLoading ? _nextStep : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLastStep ? 'SAVE JOB RECORD' : 'NEXT STEP',
                style: AppTextStyles.h2.copyWith(
                  color: canGo ? context.ksc.white : context.ksc.neutral500.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                )
              ),
              if (isLoading) CircularProgressIndicator(color: context.ksc.accent500)
              else Icon(
                isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid,
                color: canGo ? context.ksc.accent500 : context.ksc.neutral600
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    bool isNumeric = false,
    String? fieldHint,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
          Text(fieldHint, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5)),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            readOnly: readOnly,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            autocorrect: !isNumeric,
            enableSuggestions: !isNumeric,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge.copyWith(color: readOnly ? context.ksc.neutral500 : context.ksc.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: context.ksc.neutral500), contentPadding: const EdgeInsets.all(16), border: InputBorder.none, filled: true, fillColor: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
