import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/job_providers.dart';
import '../../../service_types/presentation/widgets/service_type_picker_v2.dart';

class _PartRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}

class LogJobScreen extends ConsumerStatefulWidget {
  final String? preSelectedCustomerId;
  const LogJobScreen({super.key, this.preSelectedCustomerId});

  @override
  ConsumerState<LogJobScreen> createState() => _LogJobScreenState();
}

class _LogJobScreenState extends ConsumerState<LogJobScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4; // Increased to 4 for Hardware/Parts/Photos

  String? _serviceType;
  String? _finalCustomerId;
  String _status = 'in_progress';
  String _paymentStatus = 'unpaid';

  final _customerController     = TextEditingController();
  final _phoneController        = TextEditingController();
  final _locationController     = TextEditingController();
  final _amountController       = TextEditingController();
  final _quotedAmountController = TextEditingController();
  final _notesController        = TextEditingController();
  final _brandController        = TextEditingController();
  final _keywayController       = TextEditingController();

  final List<_PartRow> _parts = [];
  final List<XFile> _beforePhotos = [];
  final List<XFile> _afterPhotos = [];

  DateTime _jobDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final preSelectedId = widget.preSelectedCustomerId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(logJobProvider.notifier).reset();

      if (preSelectedId != null) {
        _finalCustomerId = preSelectedId;
        try {
          final repo = ref.read(customerRepositoryProvider);
          final customer = await repo.getCustomerById(preSelectedId);
          setState(() {
            _customerController.text = customer.fullName;
            _phoneController.text    = customer.phoneNumber;
          });
        } catch (e) {
          debugPrint('[KS:LOG_JOB] Fast-prefill failed: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _quotedAmountController.dispose();
    _notesController.dispose();
    _brandController.dispose();
    _keywayController.dispose();
    for (var p in _parts) { p.dispose(); }
    super.dispose();
  }

  bool get _isDirty => _serviceType != null ||
                      _customerController.text.isNotEmpty ||
                      _amountController.text.isNotEmpty ||
                      _notesController.text.isNotEmpty ||
                      _parts.isNotEmpty ||
                      _beforePhotos.isNotEmpty ||
                      _afterPhotos.isNotEmpty;

  bool get _canMoveForward {
    final hasCustomer = _finalCustomerId != null;
    switch (_currentStep) {
      case 0: return _serviceType != null;
      case 1: return _customerController.text.trim().isNotEmpty && (hasCustomer || _phoneController.text.trim().isNotEmpty);
      case 2: return true;
      case 3: return true;
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
        if (mounted) KsSnackbar.show(context, message: "Enter a valid 10-digit Ghana number starting with 0", type: KsSnackbarType.error);
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
      amountChargedString: _amountController.text.trim(),
      status: _status,
      paymentStatus: _paymentStatus,
      quotedPriceString: _quotedAmountController.text.trim(),
      hardwareBrand: _brandController.text.trim(),
      hardwareKeyway: _keywayController.text.trim(),
      parts: _parts.map((p) => (
        p.nameController.text.trim(),
        int.tryParse(p.qtyController.text.trim()) ?? 1,
        CurrencyFormatter.parseToPesewas(p.priceController.text.trim()) ?? 0
      )).toList(),
      photos: [
        ..._beforePhotos.map((p) => (File(p.path), 'before')),
        ..._afterPhotos.map((p) => (File(p.path), 'after')),
      ],
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
    final stepLabels = ["SERVICE", "CUSTOMER", "DETAILS", "EXTRAS"];
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
                  width: 20,
                  height: 20,
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
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Text(
                    stepLabels[index],
                    style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 10),
                  ),
                ],
                if (index < _totalSteps - 1)
                  Expanded(child: Divider(color: context.ksc.primary700, indent: 6, endIndent: 6)),
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
      case 3: return _buildStep4();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SERVICE TYPE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        ServiceTypePickerV2(
          selected: _serviceType,
          onSelected: (t) => setState(() => _serviceType = t),
        ),
        const SizedBox(height: 32),
        Text("JOB STATUS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildStatusSelector(),
      ],
    );
  }

  Widget _buildStatusSelector() {
    final options = [
      ('quoted', 'QUOTED'),
      ('in_progress', 'IN PROGRESS'),
      ('completed', 'COMPLETED'),
      ('invoiced', 'INVOICED'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _status == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _status = opt.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700),
            ),
            child: Text(opt.$2, style: AppTextStyles.caption.copyWith(color: isSelected ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
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
            isNumeric: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("FINANCIALS", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        _buildDarkField(label: "Quoted Amount (GHS)", hint: "0.00", controller: _quotedAmountController, isNumeric: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]),
        const SizedBox(height: 24),
        _buildDarkField(label: "Final Amount (GHS)", hint: "0.00", controller: _amountController, isNumeric: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]),
        const SizedBox(height: 24),
        Text("PAYMENT STATUS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildPaymentStatusRow(),
        const SizedBox(height: 48),
        Text("LOCATION & DATE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        _buildDarkField(label: "Location", hint: "East Legon, Accra", controller: _locationController, maxLength: 255),
        const SizedBox(height: 24),
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

  Widget _buildPaymentStatusRow() {
    final statusOpts = [('unpaid', 'UNPAID'), ('partial', 'PARTIAL'), ('paid', 'PAID')];
    return Row(
      children: statusOpts.map((opt) {
        final isSel = _paymentStatus == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _paymentStatus = opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isSel ? context.ksc.accent500 : context.ksc.primary700),
              ),
              child: Text(opt.$2, style: AppTextStyles.caption.copyWith(color: isSel ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("HARDWARE (OPTIONAL)", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        _buildDarkField(label: "Lock Brand", hint: "e.g. Yale, Union", controller: _brandController),
        const SizedBox(height: 24),
        _buildDarkField(label: "Keyway Type", hint: "e.g. SC1, KW1", controller: _keywayController),
        const SizedBox(height: 48),
        Text("PARTS USED (OPTIONAL)", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ..._parts.asMap().entries.map((entry) => _buildPartRow(entry.key, entry.value)),
        if (_parts.length < 20)
          TextButton.icon(
            onPressed: () => setState(() => _parts.add(_PartRow())),
            icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
            label: Text("ADD PART", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
          ),
        const SizedBox(height: 48),
        Text("PHOTOS (OPTIONAL)", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        _buildPhotoGroup("BEFORE PHOTOS", _beforePhotos),
        const SizedBox(height: 24),
        _buildPhotoGroup("AFTER PHOTOS", _afterPhotos),
        const SizedBox(height: 48),
        _buildDarkField(label: "NOTES", hint: "Specific hardware used...", controller: _notesController, maxLines: 3, maxLength: 2000),
      ],
    );
  }

  Widget _buildPartRow(int index, _PartRow part) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildDarkField(label: "Part Name", hint: "Deadbolt", controller: part.nameController)),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _buildDarkField(label: "Qty", hint: "1", controller: part.qtyController, isNumeric: true)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildDarkField(label: "Cost", hint: "0.00", controller: part.priceController, isNumeric: true)),
          IconButton(icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18), onPressed: () => setState(() => _parts.removeAt(index))),
        ],
      ),
    );
  }

  Widget _buildPhotoGroup(String label, List<XFile> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: [
            ...photos.map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), image: DecorationImage(image: FileImage(File(p.path)), fit: BoxFit.cover))),
                  Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => photos.remove(p)), child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)))),
                ],
              ),
            )),
            if (photos.length < 2)
              GestureDetector(
                onTap: () => _pickPhoto(photos),
                child: Container(width: 60, height: 60, decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)), child: Icon(LineAwesomeIcons.camera_solid, color: context.ksc.neutral500)),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPhoto(List<XFile> list) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked != null) setState(() => list.add(picked));
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
                style: AppTextStyles.h2.copyWith(color: canGo ? context.ksc.white : context.ksc.neutral500.withValues(alpha: 0.3), fontWeight: FontWeight.w900, letterSpacing: 1.5)
              ),
              if (isLoading) CircularProgressIndicator(color: context.ksc.accent500)
              else Icon(isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid, color: canGo ? context.ksc.accent500 : context.ksc.neutral600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkField({required String label, required String hint, required TextEditingController controller, TextInputType type = TextInputType.text, int maxLines = 1, bool readOnly = false, bool isNumeric = false, String? fieldHint, List<TextInputFormatter>? inputFormatters, int? maxLength, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
        if (fieldHint != null) ...[const SizedBox(height: 4), Text(fieldHint, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5))],
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
            style: AppTextStyles.body.copyWith(color: readOnly ? context.ksc.neutral500 : context.ksc.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: context.ksc.neutral500), contentPadding: const EdgeInsets.all(16), border: InputBorder.none, filled: true, fillColor: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
