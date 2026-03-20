import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import '../providers/connectivity_provider.dart';

class KsOfflineBanner extends ConsumerWidget {
  const KsOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStreamProvider);

    return connectivity.when(
      data: (isConnected) => isConnected
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: context.ksc.neutral700,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: context.ksc.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Offline — changes will sync when connected',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.white,
                      )),
                ],
              ),
            ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
