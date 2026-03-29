import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
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
  bool _initialized = false;

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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFrom(CustomerEntity customer) {
    if (_initialized) return;
    _nameController.text     = customer.fullName;
    _phoneController.text    = customer.phoneNumber;
    _locationController.text = customer.location ?? '';
    _notesController.text    = customer.notes ?? '';
    _propertyType            = customer.propertyType;
    _leadSource              = customer.leadSource;
    _initialized = true;
  }

  Future<void> _onSave(CustomerEntity original) async {
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
      final updated = original.copyWith(
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

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "EDIT CUSTOMER", showBack: true),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (customer) {
          if (customer == null) return const Center(child: Text("Customer not found"));
          _initFrom(customer);

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
                      _phoneField(customer),
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
      bottomNavigationBar: _buildBottomBar(customerAsync.valueOrNull),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
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
      padding: const EdgeInsets.all(24),
      color: context.ksc.primary800,
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: customer != null ? () => _onSave(customer) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.ksc.accent500,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text("SAVE CHANGES", style: AppTextStyles.h2.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
