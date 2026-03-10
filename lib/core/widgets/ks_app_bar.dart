import 'package:flutter/material.dart';
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
      backgroundColor: AppColors.primary700,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.white)),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
