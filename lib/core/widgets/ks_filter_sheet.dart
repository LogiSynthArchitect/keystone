import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// A single selectable filter chip in a [KsFilterSheet].
class KsFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const KsFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? context.ksc.accent500 : context.ksc.primary600,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.captionMedium.copyWith(
            color: isSelected ? context.ksc.primary900 : context.ksc.neutral400,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// A section in a [KsFilterSheet] with a label and a [Wrap] of [KsFilterChip]s.
class KsFilterChipGroup extends StatelessWidget {
  final String label;
  final List<KsFilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const KsFilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.captionMedium
                .copyWith(color: context.ksc.neutral500, letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: options.map((opt) {
            final isSelected = selected == opt.value;
            return KsFilterChip(
              label: opt.display,
              isSelected: isSelected,
              onTap: () => onSelect(isSelected ? null : opt.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Data class for a single filter option in a [KsFilterChipGroup].
class KsFilterOption {
  final String value;
  final String display;

  const KsFilterOption({required this.value, required this.display});
}

/// Reusable filter bottom sheet used by Jobs, Customers, Notes, and Hub.
///
/// Provides a consistent layout: title + CLEAR ALL header, scrollable chip
/// sections, an optional bottom widget (e.g. date range picker), and an
/// APPLY FILTERS button.
///
/// The [onApply] callback is invoked when the user taps APPLY FILTERS.
/// The [onClear] callback is invoked when the user taps CLEAR ALL.
class KsFilterSheet extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const KsFilterSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<KsFilterSheet> createState() => _KsFilterSheetState();
}

class _KsFilterSheetState extends State<KsFilterSheet> {
  void _clear() {
    widget.onClear();
    Navigator.of(context).pop();
  }

  void _apply() {
    widget.onApply();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title,
                      style: AppTextStyles.h3.copyWith(
                          color: context.ksc.white, letterSpacing: 1.5)),
                  TextButton(
                    onPressed: _clear,
                    child: Text('CLEAR ALL',
                        style: AppTextStyles.captionMedium
                            .copyWith(color: context.ksc.error500)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sections
              ...widget.children.expand((w) => [
                w,
                const SizedBox(height: AppSpacing.lg),
              ]),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.ksc.accent500,
                    foregroundColor: context.ksc.primary900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  ),
                  child: Text('APPLY FILTERS',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: context.ksc.primary900,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
