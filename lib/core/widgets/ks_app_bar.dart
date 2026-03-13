import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class KsAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
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
              icon: const Icon(LineAwesomeIcons.angle_left_solid, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: actions,
      bottom: bottom != null ? PreferredSize(preferredSize: const Size.fromHeight(48), child: bottom!) : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? 56 : 104);
}
