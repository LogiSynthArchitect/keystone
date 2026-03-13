import 'package:flutter/material.dart';
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
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text('Discard changes?', style: AppTextStyles.h3.copyWith(color: Colors.white)),
        content: Text('You have unsaved data. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text('Keep editing', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('Discard', style: AppTextStyles.body.copyWith(color: AppColors.error500, fontWeight: FontWeight.bold)),
          ),
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
      KsSnackbar.show(context, message: "Customer saved", type: KsSnackbarType.success);
    } else {
      final error = ref.read(addCustomerProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save customer", type: KsSnackbarType.error);
    }
  }

  Widget _buildDarkField({
    required String label, 
    required String hint, 
    required TextEditingController controller, 
    TextInputType type = TextInputType.text, 
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
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
            textInputAction: action,
            maxLines: maxLines,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
            cursorColor: AppColors.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent, // Resolves text visibility bug
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addCustomerProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary900,
        appBar: const KsAppBar(title: "ADD NEW CUSTOMER", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  children: [
                    _buildDarkField(
                      label: "Full Name", 
                      hint: "Kwame Mensah", 
                      controller: _nameController, 
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    _buildDarkField(
                      label: "Phone Number", 
                      hint: "020 123 4567", 
                      type: TextInputType.phone, 
                      controller: _phoneController, 
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    _buildDarkField(
                      label: "Location", 
                      hint: "East Legon, Accra", 
                      controller: _locationController,
                    ),
                    const SizedBox(height: 24),
                    _buildDarkField(
                      label: "Notes", 
                      hint: "Prefers calls, has 2 cars...", 
                      maxLines: 3, 
                      action: TextInputAction.done, 
                      controller: _notesController,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            if (!keyboardVisible)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary700,
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                padding: const EdgeInsets.all(24.0),
                child: SafeArea(
                  top: false,
                  child: InkWell(
                    onTap: _canSave && !state.isLoading ? _onSave : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAVE CUSTOMER',
                          style: AppTextStyles.h2.copyWith(
                            color: _canSave ? AppColors.white : Colors.white.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        if (state.isLoading)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500))
                        else
                          Icon(
                            LineAwesomeIcons.arrow_right_solid,
                            color: _canSave ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
