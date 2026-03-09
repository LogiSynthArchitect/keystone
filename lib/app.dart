import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class KeystoneApp extends ConsumerWidget {
  const KeystoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Keystone',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
