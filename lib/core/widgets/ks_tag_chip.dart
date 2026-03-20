import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

class KsTagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onRemove;

  const KsTagChip({super.key, required this.tag, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.ksc.primary050,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: context.ksc.primary100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag, style: AppTextStyles.captionMedium.copyWith(color: context.ksc.primary700)),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 14, color: context.ksc.primary600),
            ),
          ],
        ],
      ),
    );
  }
}
