import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/utils/date_formatter.dart';
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
    _amountController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
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
    switch (_currentStep) {
      case 0: return _serviceType != null;
      case 1: return _customerController.text.trim().isNotEmpty && (widget.preSelectedCustomerId != null || _phoneController.text.trim().isNotEmpty);
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
        backgroundColor: AppColors.primary800,
        title: Text('DISCARD DRAFT?', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Your entered job details will be lost. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KEEP EDITING')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DISCARD', style: TextStyle(color: AppColors.error500, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();

    if (_finalCustomerId == null) { // Only validate if creating a new customer
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
      customerPhone: _finalCustomerId == null ? _phoneController.text.trim() : null, // The validation already handles the case where it's null
      jobDate: _jobDate,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      amountChargedString: amountText,
    );

    if (!mounted) return;
    if (job != null) {
      context.pop();
      KsSnackbar.show(context, message: job.isSynced ? "Job saved" : "Saved locally.", type: KsSnackbarType.success);
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
        backgroundColor: AppColors.primary900,
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
    final stepLabels = ["SERVICE", "ENTITY", "LOGISTICS"];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary800,
        border: Border(bottom: BorderSide(color: AppColors.primary700)),
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
                    color: isActive ? AppColors.accent500 : (isCompleted ? AppColors.accent500.withValues(alpha: 0.2) : AppColors.primary900),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isActive ? AppColors.accent500 : AppColors.primary700),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? AppColors.primary900 : (isCompleted ? AppColors.accent500 : AppColors.neutral500),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Text(
                    stepLabels[index],
                    style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                ],
                if (index < _totalSteps - 1) 
                  const Expanded(child: Divider(color: AppColors.primary700, indent: 8, endIndent: 8)),
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
        Text("SELECT SERVICE TYPE", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Identify the core technical operation performed.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
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
        Text("CUSTOMER ENTITY", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Verify whom this service record is attached to.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(label: "Customer Name", hint: "Kwame Mensah", controller: _customerController, readOnly: widget.preSelectedCustomerId != null, maxLength: 100),
        if (widget.preSelectedCustomerId == null) ...[
          const SizedBox(height: 24),
          _buildDarkField(
            label: "Phone Number", 
            hint: "024 123 4567", 
            controller: _phoneController, 
            type: TextInputType.phone,
            fieldHint: "Required for WhatsApp follow-ups.",
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
        Text("JOB LOGISTICS", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Finalize location, pricing, and technical notes.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
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
          type: TextInputType.number,
          fieldHint: "Total charged (Hardware + Labor).",
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 24),
        _buildDarkField(label: "Notes", hint: "Specific hardware used...", controller: _notesController, maxLines: 3, maxLength: 2000),
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
            decoration: BoxDecoration(color: AppColors.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Row(children: [
              const Icon(LineAwesomeIcons.calendar, size: 20, color: AppColors.accent500),
              const SizedBox(width: 12),
              Text(DateFormatter.short(_jobDate), style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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
      color: AppColors.primary700,
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
                  color: canGo ? Colors.white : Colors.white.withValues(alpha: 0.3), 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                )
              ),
              if (isLoading) const CircularProgressIndicator(color: AppColors.accent500)
              else Icon(
                isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid, 
                color: canGo ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1)
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
    String? fieldHint,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
          Text(fieldHint, style: AppTextStyles.caption.copyWith(color: AppColors.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5)),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            readOnly: readOnly,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: AppTextStyles.bodyLarge.copyWith(color: readOnly ? AppColors.neutral500 : Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)), contentPadding: const EdgeInsets.all(16), border: InputBorder.none, filled: true, fillColor: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
