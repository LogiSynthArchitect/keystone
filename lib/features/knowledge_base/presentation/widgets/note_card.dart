import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.toUpperCase(), 
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white, 
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  )
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.short(note.createdAt).toUpperCase(), 
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent500, 
                    fontWeight: FontWeight.w700
                  )
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.description, 
              style: AppTextStyles.body.copyWith(color: AppColors.neutral400, height: 1.4), 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis
            ),
            if (note.hasTags) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent500.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.accent500.withValues(alpha: 0.3)),
      ),
      child: Text(
        "#${tag.toLowerCase()}", 
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.accent500, 
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        )
      ),
    );
  }
}
