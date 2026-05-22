import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
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

  const KsFilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<KsFilterChipGroup> createState() => _KsFilterChipGroupState();
}

class _KsFilterChipGroupState extends State<KsFilterChipGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _staggerCtrl.forward());
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: theme.neutral500)),
        ),

        // Option rows with staggered animation + dividers
        ...widget.options.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          final isSel = widget.selected == opt.value;

          final anim = CurvedAnimation(
            parent: _staggerCtrl,
            curve: Interval(i * 0.08, 0.6 + i * 0.08, curve: Curves.easeOutCubic),
          );

          return Column(
            children: [
              AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Opacity(
                  opacity: anim.value,
                  child: Transform.translate(
                    offset: Offset(20 * (1 - anim.value), 0),
                    child: _FilterRow(
                      option: opt,
                      isSelected: isSel,
                      onTap: () => widget.onSelect(isSel ? null : opt.value),
                    ),
                  ),
                ),
              ),
              // 1px divider between rows (list spec)
              if (i < widget.options.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.primary700,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

/// Single filter row card.
class _FilterRow extends StatelessWidget {
  final KsFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accent500.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? theme.accent500.withValues(alpha: 0.4)
                  : theme.primary700,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.accent500.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Radio indicator — 18px per spec
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.accent500 : theme.neutral500,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? theme.accent500.withValues(alpha: 0.15) : Colors.transparent,
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.accent500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),

              // Icon
              if (option.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(option.icon!, style: const TextStyle(fontSize: 18)),
                ),

              // Name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.display,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                        color: isSelected ? theme.accent500 : theme.neutral400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          option.description!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.neutral500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Count badge
              if (option.count != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.accent500.withValues(alpha: 0.12)
                        : theme.primary800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${option.count}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? theme.accent500 : theme.neutral500,
                    ),
                  ),
                ),
            ],
          ),
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

  const KsFilterSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onApply,
    required this.onClear,
    this.totalCount,
    this.activeLabel,
  });

  @override
  State<KsFilterSheet> createState() => _KsFilterSheetState();
}

class _KsFilterSheetState extends State<KsFilterSheet> {
  void _clear() => widget.onClear();
  void _apply() {
    widget.onApply();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.neutral600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title only (no close icon)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 8),
                      child: Text(widget.title,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: theme.accent500)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Filter sections ──
                ...widget.children.expand((w) => [
                  w,
                  const SizedBox(height: 12),
                ]),

                const SizedBox(height: 8),

                // ── Active filter tag ──
                if (widget.activeLabel != null && widget.totalCount != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text('ACTIVE:  ', style: TextStyle(fontSize: 10, color: theme.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.accent500, letterSpacing: 0.5),
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

                // ── Cancel + Apply buttons ──
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.accent500),
                            ),
                            child: Center(
                              child: Text('CANCEL',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.accent500)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _apply,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.accent500,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.accent500.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.totalCount != null
                                    ? 'APPLY (${widget.totalCount})'
                                    : 'APPLY',
                                style: TextStyle(
                        fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: theme.primary900,
                                ),
                              ),
                            ),
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
    );
  }
}
