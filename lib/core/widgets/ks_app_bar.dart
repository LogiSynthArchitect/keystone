import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../providers/sync_status_provider.dart';

class KsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottom;

  const KsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.bottom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(syncStatusProvider);

    return AppBar(
      backgroundColor: AppColors.primary900,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title.toUpperCase(),
        style: AppTextStyles.h3.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: Icon(LineAwesomeIcons.angle_left_solid, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: [
        if (pendingCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LineAwesomeIcons.sync_solid, size: 12, color: AppColors.primary900),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingCount PENDING',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary900,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
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
