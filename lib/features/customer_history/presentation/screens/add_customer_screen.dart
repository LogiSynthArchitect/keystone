import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import 'package:keystone/core/widgets/ks_success_moment.dart';
import 'package:keystone/core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../core/router/route_names.dart' show RouteNames;
import 'package:go_router/go_router.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customer_providers.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => const AddCustomerScreen(),
    );
  }

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController    = TextEditingController();
  String? _propertyType;
  String? _leadSource;

  // Duplicate detection state
  String? _duplicateId;
  String? _duplicateName;
  String? _duplicateByName;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addCustomerProvider.notifier).reset();
    });
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
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

  Future<void> _checkDuplicateName(String name) async {
    if (name.trim().length < 2) {
      setState(() => _duplicateByName = null);
      return;
    }
    final results = await ref.read(customerRepositoryProvider).searchCustomers(name.trim());
    CustomerEntity? match;
    for (final c in results) {
      if (c.fullName.toLowerCase() == name.trim().toLowerCase()) {
        match = c;
        break;
      }
    }
    setState(() => _duplicateByName = match?.fullName);
  }

  bool get _isDirty =>
      _nameController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty ||
      _locationController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty;

  bool _canAdvance(int step, int subStep) {
    if (step == 0) {
      final phone = _phoneController.text.trim();
      return _nameController.text.trim().length >= 2 &&
             phone.length == 10 && phone.startsWith('0');
    }
    return true;
  }

  void _handleBack() {
    _confirmDiscard().then((ok) {
      if (ok && context.mounted) Navigator.of(context).pop();
    });
  }

  void _handleClose() {
    _confirmDiscard().then((ok) {
      if (ok && context.mounted) Navigator.of(context).pop();
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await KsConfirmDialog.show(
      context,
      title: 'DISCARD CHANGES?',
      message: 'You have unsaved customer details. Leave anyway?',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () {},
    ) ?? false;
  }

  Future<void> _onSave() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !phone.startsWith('0')) {
      if (mounted) {
        KsSlidingNotification.show(context, message: "Enter a valid 10-digit Ghana number starting with 0", type: KsNotificationType.error);
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
      Navigator.of(context).pop(customer);
      await KsSuccessMoment.show(context,
        title: "Customer Saved",
        subtitle: customer.fullName,
      );
    } else {
      final error = ref.read(addCustomerProvider).errorMessage;
      KsSlidingNotification.show(context, message: error ?? "Could not save customer", type: KsNotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) Navigator.of(context).pop();
      },
      child: KsStepDrawer(
        showBackArrow: true,
        title: "ADD CUSTOMER",
        steps: const [
          KsStep(
            label: 'CONTACT',
            icon: LineAwesomeIcons.phone_solid,
            tip: 'Enter the customer name and phone number.',
            imageAsset: 'assets/icons/3d/transparent/1b19dc-call-only.png',
          ),
          KsStep(
            label: 'EXTRA DETAILS',
            icon: LineAwesomeIcons.info_circle_solid,
            tip: 'Optional property type, lead source, location, and notes.',
            imageAsset: 'assets/icons/3d/transparent/58aeba-message.png',
          ),
        ],
        onBack: _handleBack,
        onClose: _handleClose,
        nextLabel: "NEXT",
        saveLabel: "SAVE",
        canAdvance: _canAdvance,
        onSave: _onSave,
        stepContent: (step, subStep, setSheetState, _) {
          switch (step) {
            case 0: return _buildStep1();
            case 1: return _buildStep2();
            default: return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
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
          onChanged: (v) => _checkDuplicateName(v),
        ),
        if (_duplicateByName != null) ...[
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
                      TextSpan(text: _duplicateByName, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const TextSpan(text: " already exists. Consider checking for duplicates."),
                    ],
                  )),
                ),
              ],
            ),
          ),
        ],
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
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
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
      ),
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
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}


