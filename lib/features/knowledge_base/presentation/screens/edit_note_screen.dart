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
import '../providers/notes_providers.dart';
import '../widgets/tag_input_field.dart';
import '../../domain/entities/knowledge_note_entity.dart';

class EditNoteScreen extends ConsumerStatefulWidget {
  final String noteId;
  const EditNoteScreen({super.key, required this.noteId});

  @override
  ConsumerState<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends ConsumerState<EditNoteScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _tags = [];
  String? _serviceType;
  bool _initialised = false;

  static const _serviceTypes = [
    'car_lock_programming',
    'door_lock_installation',
    'door_lock_repair',
    'smart_lock_installation',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFrom(KnowledgeNoteEntity note) {
    if (_initialised) return;
    _titleController.text       = note.title;
    _descriptionController.text = note.description;
    _tags                       = List.from(note.tags);
    _serviceType                = note.serviceType;
    _initialised = true;
  }

  bool get _isDirty =>
      _titleController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty;

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
        content: Text('Unsaved changes will be lost.', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: context.ksc.error500, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave(KnowledgeNoteEntity original) async {
    HapticFeedback.heavyImpact();
    final updated = original.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tags: _tags,
      serviceType: _serviceType,
    );
    final result = await ref.read(editNoteProvider.notifier).save(updated);
    if (!mounted) return;
    if (result != null) {
      ref.read(notesListProvider.notifier).updateNote(result);
      context.pop();
      KsSnackbar.show(context, message: "Note updated", type: KsSnackbarType.success);
    } else {
      final error = ref.read(editNoteProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not update note", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(editNoteProvider);
    final note     = ref.watch(notesListProvider).notes.where((n) => n.id == widget.noteId).firstOrNull;
    final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;

    if (note == null) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "EDIT NOTE", showBack: true),
        body: Center(child: Text("NOTE NOT FOUND", style: TextStyle(color: context.ksc.neutral400))),
      );
    }

    _initFrom(note);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (!context.mounted) return;
        if (ok) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "EDIT NOTE", showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NOTE CONTENT", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text("Edit the title, description, tags, and category.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
                    const SizedBox(height: 32),
                    _buildField(label: "NOTE TITLE", hint: "e.g. Rekeying Kwikset Deadbolt", controller: _titleController, maxLength: 200),
                    const SizedBox(height: 24),
                    _buildField(label: "DESCRIPTION", hint: "Step by step notes, tips, what worked...", controller: _descriptionController, maxLines: 6),
                    const SizedBox(height: 32),
                    Text("TAGS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    TagInputField(tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
                    const SizedBox(height: 32),
                    Text("SERVICE CATEGORY (OPTIONAL)", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceTypes.map((type) {
                        final label = type.replaceAll('_', ' ').toUpperCase();
                        final isSelected = _serviceType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _serviceType = isSelected ? null : type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700),
                            ),
                            child: Text(
                              label,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            if (!keyboard) _buildSaveButton(state.isLoading, note),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
            cursorColor: context.ksc.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.ksc.neutral500),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isLoading, KnowledgeNoteEntity note) {
    final canSave = _titleController.text.trim().length >= 3 &&
                    _descriptionController.text.trim().length >= 10;
    return Container(
      width: double.infinity,
      color: context.ksc.primary700,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: canSave && !isLoading ? () => _onSave(note) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVE CHANGES',
                style: AppTextStyles.h2.copyWith(
                  color: canSave ? context.ksc.white : context.ksc.neutral500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (isLoading)
                CircularProgressIndicator(color: context.ksc.accent500)
              else
                Icon(LineAwesomeIcons.check_solid, color: canSave ? context.ksc.accent500 : context.ksc.primary700),
            ],
          ),
        ),
      ),
    );
  }
}
