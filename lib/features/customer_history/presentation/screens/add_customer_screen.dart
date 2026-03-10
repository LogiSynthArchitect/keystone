import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_text_field.dart';
import '../providers/customer_providers.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});
  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
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

  bool get _canSave =>
      _nameController.text.trim().length >= 2 &&
      _phoneController.text.trim().isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Leave anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard', style: TextStyle(color: AppColors.error600))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
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
      KsSnackbar.show(context, message: "Customer saved.", type: KsSnackbarType.success);
    } else {
      final error = ref.read(addCustomerProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save customer.", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addCustomerProvider);
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.neutral050,
        appBar: const KsAppBar(title: "Add customer", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Full name", hint: "Kwame Mensah", controller: _nameController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Phone number", hint: "0201234567", type: KsTextFieldType.phone, controller: _phoneController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Location", hint: "East Legon, Accra", controller: _locationController, textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Notes", hint: "Prefers calls, has 2 cars...", type: KsTextFieldType.multiline, controller: _notesController, textInputAction: TextInputAction.done),
                    const SizedBox(height: AppSpacing.xxxl),
                    KsButton(label: "Save customer", onPressed: _canSave && !state.isLoading ? _onSave : null, isLoading: state.isLoading),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
