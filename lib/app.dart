import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class KeystoneApp extends ConsumerWidget {
  const KeystoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError(details.exception.toString(), details.stack.toString());
    };
    final router = ref.watch(appRouterProvider);
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
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Color(0xFF9E9E9E)),
                SizedBox(height: 16),
                Text('Something went wrong.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Please restart the app.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
