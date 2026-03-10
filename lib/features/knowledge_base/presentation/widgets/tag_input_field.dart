import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;

  const TagInputField({super.key, required this.tags, required this.onChanged, this.maxTags = 10});

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final tag = value.trim().toLowerCase().replaceAll(' ', '_');
    if (tag.isEmpty) return;
    if (widget.tags.contains(tag)) { _controller.clear(); return; }
    if (widget.tags.length >= widget.maxTags) return;
    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tags", style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral700)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.neutral300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tags.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: widget.tags.map((tag) => _RemovableTag(tag: tag, onRemove: () => _removeTag(tag))).toList(),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              TextField(
                controller: _controller,
                onSubmitted: _addTag,
                decoration: InputDecoration(
                  hintText: widget.tags.length >= widget.maxTags ? "Max tags reached" : "Add tag, press Enter",
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.neutral400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                ),
                enabled: widget.tags.length < widget.maxTags,
                style: AppTextStyles.body,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text("${widget.tags.length}/${widget.maxTags} tags", style: AppTextStyles.caption.copyWith(color: AppColors.neutral400)),
        ],
      ],
    );
  }
}

class _RemovableTag extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;
  const _RemovableTag({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: AppColors.primary050, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text("#$tag", style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary700)),
        const SizedBox(width: 3),
        GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 12, color: AppColors.primary500)),
      ]),
    );
  }
}
