import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../providers/key_code_provider.dart';
import '../../domain/usecases/create_key_code_usecase.dart';

class EditKeyCodeScreen extends ConsumerStatefulWidget {
  final String customerId;
  final KeyCodeEntryEntity? existing; // null = create mode

  const EditKeyCodeScreen({super.key, required this.customerId, this.existing});

  @override
  ConsumerState<EditKeyCodeScreen> createState() => _EditKeyCodeScreenState();
}

class _EditKeyCodeScreenState extends ConsumerState<EditKeyCodeScreen> {
  final _keyCodeController   = TextEditingController();
  final _keyTypeController   = TextEditingController();
  final _bittingController   = TextEditingController();
  final _notesController     = TextEditingController();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _keyCodeController.text  = widget.existing!.keyCode;
      _keyTypeController.text  = widget.existing!.keyType ?? '';
      _bittingController.text  = widget.existing!.bitting ?? '';
      _notesController.text    = widget.existing!.description ?? '';
    }
  }

  @override
  void dispose() {
    _keyCodeController.dispose();
    _keyTypeController.dispose();
    _bittingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final keyCode = _keyCodeController.text.trim();
    if (keyCode.isEmpty) {
      KsSnackbar.show(context, message: "Key code is required", type: KsSnackbarType.error);
      return;
    }

    final notifier = ref.read(keyCodeProvider(widget.customerId).notifier);

    try {
      if (_isEditing) {
        await notifier.update(widget.existing!.copyWith(
          keyCode: keyCode,
          keyType: _keyTypeController.text.trim().isEmpty ? null : _keyTypeController.text.trim(),
          bitting: _bittingController.text.trim().isEmpty ? null : _bittingController.text.trim(),
          description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        ));
      } else {
        await notifier.create(CreateKeyCodeParams(
          customerId: widget.customerId,
          keyCode: keyCode,
          keyType: _keyTypeController.text.trim().isEmpty ? null : _keyTypeController.text.trim(),
          bitting: _bittingController.text.trim().isEmpty ? null : _bittingController.text.trim(),
          description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ));
      }
      if (mounted) {
        context.pop();
        KsSnackbar.show(context, message: _isEditing ? "Key code updated" : "Key code saved", type: KsSnackbarType.success);
      }
    } catch (e) {
      if (mounted) KsSnackbar.show(context, message: "Could not save: $e", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(title: _isEditing ? "EDIT KEY CODE" : "ADD KEY CODE", showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.ksc.accent500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: context.ksc.accent500),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Bitting data is encrypted and only visible to you.", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            _field("Key Code *", _keyCodeController, hint: "e.g. B276"),
            const SizedBox(height: 16),
            _field("Key Type", _keyTypeController, hint: "e.g. SC1, KW1, M1"),
            const SizedBox(height: 16),
            _field("Bitting / Code Data", _bittingController, hint: "e.g. 4-3-2-1-2-3"),
            const SizedBox(height: 16),
            _field("Notes", _notesController, hint: "e.g. Front door, deadbolt", maxLines: 3),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: context.ksc.primary800,
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.ksc.accent500,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text("SAVE KEY CODE", style: AppTextStyles.h2.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: TextStyle(color: context.ksc.neutral600)),
          ),
        ),
      ],
    );
  }
}
