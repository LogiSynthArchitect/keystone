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
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text('DISCARD CHANGES?', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('You have unsaved customer details. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: AppColors.neutral400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: AppColors.error500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();
    final customer = await ref.read(addCustomerProvider.notifier).save(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
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
        backgroundColor: AppColors.primary900,
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
    final stepLabels = ["IDENTITY", "CONTEXT"];
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
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER IDENTITY", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Primary contact information for the system database.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(
          label: "Full Name", 
          hint: "Kwame Mensah", 
          controller: _nameController, 
        ),
        const SizedBox(height: 24),
        _buildDarkField(
          label: "Phone Number", 
          hint: "020 123 4567", 
          type: TextInputType.phone, 
          controller: _phoneController, 
          fieldHint: "Required for automated follow-up messages.",
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SITUATIONAL CONTEXT", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Optional details to help locate or identify the customer.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(
          label: "Primary Location", 
          hint: "East Legon, Accra", 
          controller: _locationController,
          fieldHint: "Used for navigating to return sites.",
        ),
        const SizedBox(height: 24),
        _buildDarkField(
          label: "Dossier Notes", 
          hint: "Prefers calls, has 2 cars...", 
          maxLines: 3, 
          controller: _notesController,
          fieldHint: "Long-term observations about this entity.",
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
                isLastStep ? 'SAVE CUSTOMER RECORD' : 'NEXT STEP', 
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
    String? fieldHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
          Text(fieldHint, style: AppTextStyles.caption.copyWith(color: AppColors.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5)),
        ],
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
            maxLines: maxLines,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
            cursorColor: AppColors.accent500,
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
