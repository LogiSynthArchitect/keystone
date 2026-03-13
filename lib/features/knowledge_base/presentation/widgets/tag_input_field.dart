import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TagInputField extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagInputField({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();

  void _addTag(String value) {
    final tag = value.trim().toLowerCase();
    if (tag.isNotEmpty && !widget.tags.contains(tag)) {
      widget.onChanged([...widget.tags, tag]);
    }
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tags.map((tag) => _TagChip(
                    label: tag,
                    onRemove: () {
                      widget.onChanged(
                        widget.tags.where((t) => t != tag).toList(),
                      );
                    },
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _controller,
                onSubmitted: _addTag,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
                cursorColor: AppColors.accent500,
                decoration: InputDecoration(
                  hintText: "Add tag, press Enter",
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: Colors.transparent, // Fixes white-out bug for tags
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.accent500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.accent500.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "#$label",
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent500,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: AppColors.accent500.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
