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

  const KsAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.bottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(syncStatusProvider);

    return AppBar(
      backgroundColor: context.ksc.primary900,
      foregroundColor: context.ksc.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      title: titleWidget ?? Text(
        title,
        style: AppTextStyles.h3.copyWith(
          color: context.ksc.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(LineAwesomeIcons.angle_left_solid, size: 22),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: [
        if (pendingCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.ksc.accent500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LineAwesomeIcons.sync_solid, size: 12, color: context.ksc.accent500),
                  const SizedBox(width: 6),
                  Text(
                    '$pendingCount PENDING',
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...?actions,
      ],
      bottom: bottom != null ? PreferredSize(preferredSize: const Size.fromHeight(48), child: bottom!) : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? 56 : 104);
}
