import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/knowledge_note_entity.dart';

class NoteCard extends StatelessWidget {
  final KnowledgeNoteEntity note;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;

  const NoteCard({super.key, required this.note, this.onTap, this.onArchive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(note.title, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(DateFormatter.short(note.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.neutral400)),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Text(note.description, style: AppTextStyles.body.copyWith(color: AppColors.neutral600), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (note.hasTags) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: note.tags.take(4).map((tag) => _TagChip(tag: tag)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Text("#$tag", style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral600)),
    );
  }
}
