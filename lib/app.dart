import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

class KeystoneApp extends ConsumerWidget {
  const KeystoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    return MaterialApp(
      title: 'Keystone',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Text('Keystone'),
        ),
      ),
    );
  }
}
