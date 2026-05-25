import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/update_customer_usecase.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  final String customerId;
  const EditCustomerScreen({super.key, required this.customerId});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  CustomerEntity? _customer;

  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController    = TextEditingController();
  String? _propertyType;
  String? _leadSource;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomer());
  }

  void _loadCustomer() {
    final customer = ref.read(customerDetailProvider(widget.customerId)).valueOrNull;
    if (customer == null) return;
    _nameController.text     = customer.fullName;
    _phoneController.text    = customer.phoneNumber;
    _locationController.text = customer.location ?? '';
    _notesController.text    = customer.notes ?? '';
    _propertyType            = customer.propertyType;
    _leadSource              = customer.leadSource;
    _customer = customer;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isDirty => _nameController.text.trim().isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await KsConfirmDialog.show(
      context,
      title: 'DISCARD CHANGES',
      message: 'Unsaved changes will be lost.',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () {},
    );
    return result ?? false;
  }

  Future<void> _onSave() async {
    final customer = _customer;
    if (customer == null) return;

    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !phone.startsWith('0')) {
      KsSnackbar.show(context, message: "Enter a valid 10-digit Ghana number starting with 0", type: KsSnackbarType.error);
      return;
    }
    final name = _nameController.text.trim();
    if (name.length < 2) {
      KsSnackbar.show(context, message: "Name must be at least 2 characters", type: KsSnackbarType.error);
      return;
    }

    try {
      final updated = customer.copyWith(
        fullName: name,
        phoneNumber: phone,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        propertyType: _propertyType,
        leadSource: _leadSource,
      );
      await ref.read(updateCustomerUsecaseProvider).call(UpdateCustomerParams(customer: updated));
      if (mounted) {
        ref.invalidate(customerDetailProvider(widget.customerId));
        ref.read(customerListProvider.notifier).load();
        context.pop();
        KsSnackbar.show(context, message: "Customer updated", type: KsSnackbarType.success);
      }
    } catch (e) {
      if (mounted) KsSnackbar.show(context, message: "Update failed: $e", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final customer = _customer ?? customerAsync.valueOrNull;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "EDIT CUSTOMER", showBack: true),
        body: customerAsync.when(
          loading: () => const Center(child: KsLoadingIndicator()),
          error: (e, _) => KsEmptyState(
            icon: LineAwesomeIcons.exclamation_triangle_solid,
            title: "FAILED TO LOAD",
            subtitle: "Could not load customer details.",
            actionLabel: "TAP TO RETRY",
            onAction: () => ref.invalidate(customerDetailProvider(widget.customerId)),
          ),
          data: (c) {
            if (c == null) {
              return const KsEmptyState(icon: LineAwesomeIcons.user_slash_solid, title: "CUSTOMER NOT FOUND");
            }
            if (_customer == null) return const SizedBox.shrink();

            return Column(
              children: [
                const KsOfflineBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel("CONTACT"),
                        _textField("Full Name", _nameController),
                        const SizedBox(height: 16),
                        _phoneField(c),
                        const SizedBox(height: 32),
                        _sectionLabel("PROPERTY TYPE"),
                        _chipSelector(
                          options: _propertyTypes,
                          selected: _propertyType,
                          onSelect: (v) => setState(() => _propertyType = _propertyType == v ? null : v),
                        ),
                        const SizedBox(height: 32),
                        _sectionLabel("LEAD SOURCE"),
                        _chipSelector(
                          options: _leadSources,
                          selected: _leadSource,
                          onSelect: (v) => setState(() => _leadSource = _leadSource == v ? null : v),
                        ),
                        const SizedBox(height: 32),
                        _sectionLabel("OTHER"),
                        _textField("Location", _locationController),
                        const SizedBox(height: 16),
                        _textField("Notes", _notesController, maxLines: 3),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomBar(customer),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
  );

  Widget _phoneField(CustomerEntity customer) {
    final hasJobs = customer.totalJobs > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField("Phone Number", _phoneController, keyboardType: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
        if (hasJobs) ...[
          const SizedBox(height: 6),
          Text(
            "This customer has ${customer.totalJobs} job${customer.totalJobs == 1 ? '' : 's'}. Changing the number will not affect those links — they use a stable ID.",
            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10),
          ),
        ],
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType, List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
          cursorColor: context.ksc.accent500,
          decoration: InputDecoration(
            filled: false,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.accent500, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            isDense: true,
          ),
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
      spacing: 8,
      runSpacing: 8,
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

  Widget _buildBottomBar(CustomerEntity? customer) {
    return Container(
      width: double.infinity,
      color: context.ksc.accent500,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: customer != null ? () => _onSave() : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("SAVE CHANGES",
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.primary900,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(LineAwesomeIcons.check_solid, color: context.ksc.primary900, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
