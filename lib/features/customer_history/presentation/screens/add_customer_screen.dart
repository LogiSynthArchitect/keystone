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
import '../../../../core/widgets/ks_step_indicator.dart';
import '../../../../core/router/route_names.dart';
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
  String? _propertyType;
  String? _leadSource;

  // Duplicate detection state
  String? _duplicateId;
  String? _duplicateName;

  static const _propertyTypes = [
    ('residential', 'Residential'),
    ('commercial', 'Commercial'),
    ('automotive', 'Automotive'),
  ];

  static const _leadSources = [
    ('word_of_mouth', 'Word of Mouth'),
    ('google_maps', 'Google Maps'),
    ('referral', 'Referral'),
    ('physical_card', 'Physical Card'),
    ('whatsapp', 'WhatsApp'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    // Reset provider state so a returning user never sees stale saved/error state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addCustomerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicate(String phone) async {
    if (phone.length != 10) {
      setState(() { _duplicateId = null; _duplicateName = null; });
      return;
    }
    final existing = await ref.read(customerRepositoryProvider).getCustomerByPhone(phone);
    setState(() {
      _duplicateId   = existing?.id;
      _duplicateName = existing?.fullName;
    });
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
          side: BorderSide(color: context.ksc.primary700),
        ),
        title: Text('DISCARD CHANGES?', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
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
      propertyType: _propertyType,
      leadSource: _leadSource,
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
            KsStepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: ["CONTACT", "DETAILS"],
            ),
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
        Text("CUSTOMER DETAILS", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
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
          type: TextInputType.text,
          controller: _phoneController,
          fieldHint: "Used to send WhatsApp follow-up messages.",
          isNumeric: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (v) => _checkDuplicate(v),
        ),
        if (_duplicateId != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: context.ksc.warning500.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.warning500.withValues(alpha: 0.4))),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, size: 16, color: context.ksc.warning500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(TextSpan(
                    style: AppTextStyles.caption.copyWith(color: context.ksc.warning500, fontSize: 11),
                    children: [
                      const TextSpan(text: "A customer named "),
                      TextSpan(text: _duplicateName, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const TextSpan(text: " already exists with this number. "),
                    ],
                  )),
                ),
                TextButton(
                  onPressed: () => context.push(RouteNames.customerDetail(_duplicateId!)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text("VIEW", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("EXTRA DETAILS", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Optional details to help classify and locate the customer.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 32),

        Text("PROPERTY TYPE (OPTIONAL)", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _chipSelector(
          options: _propertyTypes,
          selected: _propertyType,
          onSelect: (v) => setState(() => _propertyType = _propertyType == v ? null : v),
        ),
        const SizedBox(height: 32),

        Text("LEAD SOURCE (OPTIONAL)", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        _chipSelector(
          options: _leadSources,
          selected: _leadSource,
          onSelect: (v) => setState(() => _leadSource = _leadSource == v ? null : v),
        ),
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

  Widget _chipSelector({
    required List<(String, String)> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected == o.$1;
        return GestureDetector(
          onTap: () => onSelect(o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700),
            ),
            child: Text(o.$2, style: AppTextStyles.caption.copyWith(color: isSelected ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
          ),
        );
      }).toList(),
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
                  color: canGo ? context.ksc.white : context.ksc.neutral500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                )
              ),
              if (isLoading) CircularProgressIndicator(color: context.ksc.accent500)
              else Icon(
                isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid,
                color: canGo ? context.ksc.accent500 : context.ksc.primary700
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
    bool isNumeric = false,
    ValueChanged<String>? onChanged,
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
            border: Border.all(color: context.ksc.primary700),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            autocorrect: !isNumeric,
            enableSuggestions: !isNumeric,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
            cursorColor: context.ksc.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.ksc.neutral500),
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
