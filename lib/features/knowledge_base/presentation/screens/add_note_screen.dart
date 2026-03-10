import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_text_field.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../providers/notes_providers.dart';
import '../widgets/tag_input_field.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  const AddNoteScreen({super.key});
  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _tags = [];
  ServiceType? _serviceType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addNoteProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _titleController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _tags.isNotEmpty ||
      _serviceType != null;

  bool get _canSave =>
      _titleController.text.trim().length >= 3 &&
      _descriptionController.text.trim().length >= 10;

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
    final note = await ref.read(addNoteProvider.notifier).save(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tags: _tags,
      serviceType: _serviceType,
    );
    if (!mounted) return;
    if (note != null) {
      ref.read(notesListProvider.notifier).addNote(note);
      context.pop();
      KsSnackbar.show(context, message: "Note saved.", type: KsSnackbarType.success);
    } else {
      final error = ref.read(addNoteProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save note.", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addNoteProvider);
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
        appBar: const KsAppBar(title: "Add note", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Title", hint: "How to rekey a Kwikset deadbolt", controller: _titleController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: "Description", hint: "Step by step notes, tips, what worked...", type: KsTextFieldType.multiline, controller: _descriptionController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.done),
                    const SizedBox(height: AppSpacing.lg),
                    TagInputField(tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
                    const SizedBox(height: AppSpacing.lg),
                    Text("Service type (optional)", style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral700)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: ServiceType.values.map((type) {
                        final labels = {
                          ServiceType.carLockProgramming: "Car Key",
                          ServiceType.doorLockInstallation: "Door Install",
                          ServiceType.doorLockRepair: "Door Repair",
                          ServiceType.smartLockInstallation: "Smart Lock",
                        };
                        final isSelected = _serviceType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _serviceType = isSelected ? null : type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary700 : AppColors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              border: Border.all(color: isSelected ? AppColors.primary700 : AppColors.neutral300),
                            ),
                            child: Text(labels[type]!, style: AppTextStyles.caption.copyWith(color: isSelected ? AppColors.white : AppColors.neutral700)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    KsButton(label: "Save note", onPressed: _canSave && !state.isLoading ? _onSave : null, isLoading: state.isLoading),
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
