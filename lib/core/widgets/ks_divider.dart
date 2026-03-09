import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class KsDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;

  const KsDivider({super.key, this.indent, this.endIndent});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.neutral200,
      thickness: 1,
      height: 1,
      indent: indent ?? AppSpacing.lg,
      endIndent: endIndent ?? AppSpacing.lg,
    );
  }
}
