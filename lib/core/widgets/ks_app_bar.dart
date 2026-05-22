import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import '../providers/sync_status_provider.dart';

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
  final bool goldStyle; // gold background + dot pattern

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
    this.goldStyle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(syncStatusProvider);

    final actionWidgets = <Widget>[
      if (searchable)
        IconButton(
          icon: Icon(
            isSearchOpen ? LineAwesomeIcons.times_solid : LineAwesomeIcons.search_solid,
            color: goldStyle
                ? context.ksc.primary900
                : (isSearchOpen ? context.ksc.accent500 : context.ksc.neutral500),
            size: 20,
          ),
          onPressed: onSearchToggle,
        ),
      ...?actions,
    ];

    final bgColor = goldStyle ? context.ksc.accent500 : context.ksc.primary900;
    final fgColor = goldStyle ? context.ksc.primary900 : context.ksc.white;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      title: titleWidget ?? Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: Icon(LineAwesomeIcons.angle_left_solid, size: 22, color: fgColor),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: actionWidgets,
      bottom: bottom != null ? PreferredSize(preferredSize: const Size.fromHeight(48), child: bottom!) : null,
    );
  }

  @override
  Size get preferredSize {
    double h = 56;
    if (bottom != null) h += 48;
    return Size.fromHeight(h);
  }
}
