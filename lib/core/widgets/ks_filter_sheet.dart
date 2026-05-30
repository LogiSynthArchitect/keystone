import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

/// Data class for a single filter option.
class KsFilterOption {
  final String value;
  final String display;
  final String? icon;
  final int? count;
  final String? description;

  const KsFilterOption({
    required this.value,
    required this.display,
    this.icon,
    this.count,
    this.description,
  });
}

/// A filter section rendered as premium card-rows.
///
/// Each row:
///   ◉ icon  Display Name             count    ← selected (gold)
///           Description text
///
///   ○ icon  Display Name             count    ← unselected (dark)
///           Description text
class KsFilterChipGroup extends StatefulWidget {
  final String label;
  final List<KsFilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final double borderRadius;
  final Color? unselectedColor;

  const KsFilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.borderRadius = 6,
    this.unselectedColor,
  });

  @override
  State<KsFilterChipGroup> createState() => _KsFilterChipGroupState();
}

class _KsFilterChipGroupState extends State<KsFilterChipGroup> {
  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(widget.label,
              style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
        ),

        // Chips in a wrap layout
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.options.map((opt) {
            final isSel = widget.selected == opt.value;
            return _FilterChip(
              option: opt,
              isSelected: isSel,
              onTap: () => widget.onSelect(isSel ? null : opt.value),
              borderRadius: widget.borderRadius,
              unselectedColor: widget.unselectedColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Single filter chip — compact pill matching the add item location chips.
class _FilterChip extends StatelessWidget {
  final KsFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final double borderRadius;
  final Color? unselectedColor;

  const _FilterChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.borderRadius = 6,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 76),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accent500.withValues(alpha: 0.15)
              : (unselectedColor ?? theme.primary800),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isSelected ? theme.accent500 : theme.primary700,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(option.icon!, style: const TextStyle(fontSize: 14)),
              ),
            Text(
              option.display,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isSelected ? theme.accent500 : theme.neutral400,
              ),
            ),
            if (option.count != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '(${option.count})',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? theme.accent500 : theme.neutral500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable filter bottom sheet — premium NoirLuxe design.
///
/// Header: frosted-glass blur + title + ✕.
/// Body: card-rows with radio selection, staggered animation.
/// Footer: active filter tag + CANCEL / APPLY buttons.
class KsFilterSheet extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final int? totalCount;
  final String? activeLabel; // shown as tag chip (e.g. "Residential")
  final double heightFraction; // max fraction of screen height to occupy

  const KsFilterSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onApply,
    required this.onClear,
    this.totalCount,
    this.activeLabel,
    this.heightFraction = 0.45,
  });

  @override
  State<KsFilterSheet> createState() => _KsFilterSheetState();
}

class _KsFilterSheetState extends State<KsFilterSheet> {
  void _clear() {
    widget.onClear();     // reset draft
    widget.onApply();     // persist cleared values to provider
    Navigator.of(context).pop(); // close sheet
  }
  void _apply() {
    widget.onApply();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    final maxHeight = MediaQuery.of(context).size.height * widget.heightFraction;

    return Container(
      color: theme.primary800,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.neutral600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header: title + CLEAR + X close ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: AppTextStyles.h2.copyWith(
                            color: theme.white, fontWeight: FontWeight.w900)),
                  ),
                  GestureDetector(
                    onTap: _clear,
                    child: Text('CLEAR',
                        style: AppTextStyles.caption.copyWith(
                            color: theme.neutral500,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(LineAwesomeIcons.times_solid,
                        color: theme.neutral500, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: theme.primary700),
            const SizedBox(height: 12),

            // ── Filter sections (scrollable) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.children.expand((w) => [
                      w,
                      const SizedBox(height: 12),
                    ]),

                    // Active filter tag
                    if (widget.activeLabel != null && widget.totalCount != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text('ACTIVE:  ',
                                style: AppTextStyles.caption.copyWith(
                                    fontSize: 10, color: theme.neutral500,
                                    fontWeight: FontWeight.w800, letterSpacing: 1)),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.accent500.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: theme.accent500.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(widget.activeLabel!,
                                          style: AppTextStyles.caption.copyWith(
                                              fontSize: 10, fontWeight: FontWeight.w800,
                                              color: theme.accent500, letterSpacing: 0.5),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: _clear,
                                      child: Icon(Icons.close, size: 12, color: theme.accent500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Bottom gold button (matches KsStepDrawer) ──
            Container(
              width: double.infinity,
              color: theme.accent500,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _apply,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.totalCount != null
                              ? 'APPLY (${widget.totalCount})'
                              : 'APPLY',
                          style: AppTextStyles.body.copyWith(
                            color: theme.primary900,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.0,
                          ),
                        ),
          Icon(LineAwesomeIcons.arrow_right_solid,
                              color: theme.primary900, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
