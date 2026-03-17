import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';

class KeystoneApp extends ConsumerWidget {
  const KeystoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError(details.exception.toString(), details.stack.toString());
    };
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Keystone',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) => _ErrorBoundary(child: child ?? const SizedBox.shrink()),
    );
  }

  void _logError(String error, String stack) {
    try {
      Supabase.instance.client.from('app_events').insert({
        'event_name': 'app_error',
        'properties': {'error': error, 'stack': stack.substring(0, stack.length.clamp(0, 500))},
      });
    } catch (_) {}
  }
}

class _ErrorBoundary extends StatefulWidget {
  final Widget child;
  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      if (mounted) setState(() => _hasError = true);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.primary900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: AppColors.error500),
                const SizedBox(height: 24),
                Text('SYSTEM ERROR DETECTED',
                    style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text('CRITICAL ARCHITECTURAL BREACH. REBOOT TERMINAL.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.neutral500, letterSpacing: 0.5)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _hasError = false),
                  child: const Text('RELOAD TERMINAL'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
