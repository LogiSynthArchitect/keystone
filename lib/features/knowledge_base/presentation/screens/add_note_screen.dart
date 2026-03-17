import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../providers/notes_providers.dart';
import '../widgets/tag_input_field.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  const AddNoteScreen({super.key});
  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  int _currentStep = 0;
  final int _totalSteps = 2;

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

  bool get _canMoveForward {
    if (_currentStep == 0) {
      return _titleController.text.trim().length >= 3 &&
             _descriptionController.text.trim().length >= 10;
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
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text('DISCARD CHANGES?', style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('You have unsaved technical notes. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: AppColors.neutral400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: AppColors.error500, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();
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
      KsSnackbar.show(context, message: "Note saved", type: KsSnackbarType.success);
    } else {
      final error = ref.read(addNoteProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save note", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addNoteProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _previousStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary900,
        appBar: KsAppBar(
          title: "ADD NEW NOTE", 
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
    final stepLabels = ["TECHNICAL", "INDEXING"];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary800,
        border: Border(bottom: BorderSide(color: AppColors.primary700)),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent500 : (isCompleted ? AppColors.accent500.withValues(alpha: 0.2) : AppColors.primary900),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isActive ? AppColors.accent500 : AppColors.primary700),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? AppColors.primary900 : (isCompleted ? AppColors.accent500 : AppColors.neutral500),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Text(
                    stepLabels[index],
                    style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                ],
                if (index < _totalSteps - 1) 
                  const Expanded(child: Divider(color: AppColors.primary700, indent: 8, endIndent: 8)),
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
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TECHNICAL LOG", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Document the core technical findings and solutions.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        const SizedBox(height: 32),
        _buildDarkField(
          label: "Note Title", 
          hint: "e.g. Rekeying Kwikset Deadbolt", 
          controller: _titleController, 
          fieldHint: "Concise summary of the technical problem.",
        ),
        const SizedBox(height: 24),
        _buildDarkField(
          label: "Technical Description", 
          hint: "Step by step notes, tips, what worked...", 
          maxLines: 5, 
          controller: _descriptionController,
          fieldHint: "Detailed instructions for future retrieval.",
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SYSTEM INDEXING", style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Categorize this note for rapid technical retrieval.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
        const SizedBox(height: 32),
        Text("TAGS", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TagInputField(tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
        const SizedBox(height: 32),
        Text("SERVICE CATEGORY (OPTIONAL)", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ServiceType.values.map((type) {
            final labels = {
              ServiceType.carLockProgramming: "CAR KEY",
              ServiceType.doorLockInstallation: "DOOR INSTALL",
              ServiceType.doorLockRepair: "DOOR REPAIR",
              ServiceType.smartLockInstallation: "SMART LOCK",
            };
            final isSelected = _serviceType == type;
            return GestureDetector(
              onTap: () => setState(() => _serviceType = isSelected ? null : type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent500.withValues(alpha: 0.1) : AppColors.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  labels[type]!, 
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.accent500 : AppColors.neutral400,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  )
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isLoading) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canGo = _canMoveForward;

    return Container(
      width: double.infinity,
      color: AppColors.primary700,
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: canGo && !isLoading ? _nextStep : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLastStep ? 'SAVE KNOWLEDGE NOTE' : 'NEXT STEP', 
                style: AppTextStyles.h2.copyWith(
                  color: canGo ? Colors.white : Colors.white.withValues(alpha: 0.3), 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                )
              ),
              if (isLoading) CircularProgressIndicator(color: AppColors.accent500)
              else Icon(
                isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid, 
                color: canGo ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1)
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
    int maxLines = 1,
    String? fieldHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
          Text(fieldHint, style: AppTextStyles.caption.copyWith(color: AppColors.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5)),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
            cursorColor: AppColors.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
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
