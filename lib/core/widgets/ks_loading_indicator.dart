import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class KsLoadingIndicator extends StatelessWidget {
  final bool fullScreen;

  const KsLoadingIndicator({super.key, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    if (fullScreen) {
      return const Scaffold(
        backgroundColor: AppColors.neutral050,
        body: Center(child: CircularProgressIndicator(
          color: AppColors.primary700,
          strokeWidth: 2.5,
        )),
      );
    }
    return const Center(child: CircularProgressIndicator(
      color: AppColors.primary700,
      strokeWidth: 2.5,
    ));
  }
}
