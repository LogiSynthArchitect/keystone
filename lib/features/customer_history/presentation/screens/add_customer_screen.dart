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
import '../providers/customer_providers.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});
  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  int _currentStep = 0;
  final int _totalSteps = 2;

  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _nameController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty ||
      _locationController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty;

  bool get _canMoveForward {
    if (_currentStep == 0) {
      return _nameController.text.trim().length >= 2 &&
             _phoneController.text.trim().isNotEmpty;
    }
    return true;
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text('DISCARD CHANGES?', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('You have unsaved customer details. Leave anyway?', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: context.ksc.error500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();

    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !phone.startsWith('0')) {
      if (mounted) {
        KsSnackbar.show(context, message: "Enter a valid 10-digit Ghana number starting with 0", type: KsSnackbarType.error);
      }
      return;
    }

    final customer = await ref.read(addCustomerProvider.notifier).save(
      fullName: _nameController.text.trim(),
      phoneNumber: phone,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    if (!mounted) return;
    if (customer != null) {
      ref.read(customerListProvider.notifier).addCustomer(customer);
      context.pop();
      KsSnackbar.show(context, message: "Customer saved", type: KsSnackbarType.success);
    } else {
      final error = ref.read(addCustomerProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save customer", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addCustomerProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _previousStep();
      },
      child: Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: KsAppBar(
          title: "ADD NEW CUSTOMER",
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
    final stepLabels = ["CONTACT", "NOTES"];
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
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER DETAILS", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Contact details for the customer.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(
          label: "Full Name",
          hint: "Kwame Mensah",
          controller: _nameController,
          maxLength: 100,
        ),
        const SizedBox(height: 24),
        _buildDarkField(
          label: "Phone Number",
          hint: "020 123 4567",
          type: TextInputType.number,
          controller: _phoneController,
          fieldHint: "Used to send WhatsApp follow-up messages.",
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("EXTRA NOTES", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Optional details to help locate or identify the customer.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(
          label: "Primary Location",
          hint: "East Legon, Accra",
          controller: _locationController,
          fieldHint: "Used for navigating to return sites.",
          maxLength: 255,
        ),
        const SizedBox(height: 24),
        _buildDarkField(
          label: "Customer Notes",
          hint: "Prefers calls, has 2 cars...",
          maxLines: 3,
          controller: _notesController,
          fieldHint: "Any useful details about this customer.",
          maxLength: 1000,
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
                isLastStep ? 'SAVE CUSTOMER RECORD' : 'NEXT STEP',
                style: AppTextStyles.h2.copyWith(
                  color: canGo ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                )
              ),
              if (isLoading) CircularProgressIndicator(color: context.ksc.accent500)
              else Icon(
                isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid,
                color: canGo ? context.ksc.accent500 : Colors.white.withValues(alpha: 0.1)
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
    String? fieldHint,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
          Text(fieldHint, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5)),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
            cursorColor: context.ksc.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
