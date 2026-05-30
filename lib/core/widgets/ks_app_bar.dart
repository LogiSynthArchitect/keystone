import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import 'ks_icon_well.dart';

class KsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottom;
  final bool searchable;
  final bool isSearchOpen;
  final VoidCallback? onSearchToggle;

  const KsAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.bottom,
    this.searchable = false,
    this.isSearchOpen = false,
    this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.ksc;

    // ── Search toggle in icon well ──
    final actionWidgets = <Widget>[
      if (searchable)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: KsIconWell(
            icon: isSearchOpen ? LineAwesomeIcons.times_solid : LineAwesomeIcons.search_solid,
            isActive: isSearchOpen,
            onTap: onSearchToggle,
          ),
        ),
      ...?actions,
      const SizedBox(width: 8),
    ];

    // ── Gold accent line + title ──
    final titleContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            color: theme.accent500,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: titleWidget ??
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: theme.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
        ),
      ],
    );

    // ── Back button as icon well ──
    final leading = showBack
        ? Padding(
            padding: const EdgeInsets.only(left: 4),
            child: KsIconWell(
              icon: LineAwesomeIcons.angle_left_solid,
              iconSize: 22,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          )
        : null;

    return AppBar(
      backgroundColor: theme.primary900,
      foregroundColor: theme.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: titleContent,
      leading: leading,
      automaticallyImplyLeading: showBack,
      actions: actionWidgets,
      bottom: bottom != null
          ? PreferredSize(preferredSize: const Size.fromHeight(48), child: bottom!)
          : null,
    );
  }

  @override
  Size get preferredSize {
    double h = 56;
    if (bottom != null) h += 48;
    return Size.fromHeight(h);
  }
}
