import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/notes_providers.dart';
import '../../domain/entities/knowledge_note_entity.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  KnowledgeNoteEntity? _findNote(NotesListState state) {
    try { return state.notes.firstWhere((n) => n.id == noteId); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesListProvider);
    final note = _findNote(state);

    if (note == null) {
      return const Scaffold(
        appBar: KsAppBar(title: "Note", showBack: true),
        body: Center(child: Text("Note not found.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: KsAppBar(
        title: "Note",
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: AppColors.neutral500),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Archive note?"),
                  content: const Text("This note will be removed from your list."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Archive", style: TextStyle(color: AppColors.error600))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(notesListProvider.notifier).archiveNote(note.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  KsSnackbar.show(context, message: "Note archived.", type: KsSnackbarType.info);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(note.title, style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(DateFormatter.display(note.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.neutral400)),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Text(note.description, style: AppTextStyles.body.copyWith(color: AppColors.neutral800, height: 1.6)),
            ),
            if (note.hasTags) ...[
              const SizedBox(height: AppSpacing.lg),
              Text("Tags", style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral500)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: note.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: AppColors.primary050, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                  child: Text("#$tag", style: AppTextStyles.caption.copyWith(color: AppColors.primary700)),
                )).toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
