import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';

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
  static const _kMaxTags = 10;

  bool get _isAtMax => widget.tags.length >= _kMaxTags;

  void _addTag(String value) {
    if (_isAtMax) return;
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
          padding: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tags.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Wrap(
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
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _controller,
                onSubmitted: _addTag,
                enabled: !_isAtMax,
                style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  hintText: _isAtMax ? "Max 10 tags reached" : "Add tag, press Enter",
                  hintStyle: TextStyle(color: _isAtMax ? context.ksc.error500.withValues(alpha: 0.7) : context.ksc.neutral500),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "${widget.tags.length}/$_kMaxTags tags",
                    style: AppTextStyles.caption.copyWith(
                      color: _isAtMax ? context.ksc.error500 : context.ksc.neutral500,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  if (_isAtMax) ...[
                    const SizedBox(width: 8),
                    Text(
                      "MAX REACHED",
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.error500,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ],
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
        color: context.ksc.accent500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "#$label",
            style: AppTextStyles.labelSmall.copyWith(
              color: context.ksc.accent500,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: context.ksc.accent500.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
