import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/ks_colors.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/supabase_provider.dart';
import 'core/constants/supabase_constants.dart';
import 'core/widgets/privacy_overlay.dart';
import 'core/services/internal_auth/secure_vault_service.dart';
import 'core/services/internal_auth/internal_auth_service.dart';
import 'core/storage/hive_service.dart';
import 'features/job_logging/presentation/providers/job_providers.dart';
import 'features/customer_history/presentation/providers/customer_providers.dart';
import 'features/knowledge_base/presentation/providers/notes_providers.dart';

class KeystoneApp extends ConsumerStatefulWidget {
  const KeystoneApp({super.key});

  @override
  ConsumerState<KeystoneApp> createState() => _KeystoneAppState();
}

class _KeystoneAppState extends ConsumerState<KeystoneApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError(details.exception.toString(), details.stack.toString());
    };
    // Start stale session re-auth listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnectivityListener();
      _initAuthGuard();
    });
  }

  void _initAuthGuard() {
    final supabase = ref.read(supabaseClientProvider);
    supabase.auth.onAuthStateChange.listen((data) async {
      if (data.session == null && mounted) {
        final vault = SecureVaultService();
        await vault.clearAll();
        try { Hive.box('auth').delete(HiveService.lastOnlineSyncKey); } catch (_) {}
        try { HiveService.clearAll(); } catch (_) {}
        ref.invalidate(authStateProvider);
      }
    });
  }

  void _initConnectivityListener() {
    ref.listenManual(connectivityStreamProvider, (AsyncValue<bool>? previous, AsyncValue<bool> next) {
      final wasOffline = previous is AsyncData<bool> && previous.value == false;
      final isOnline = next is AsyncData<bool> && next.value == true;
      if (wasOffline && isOnline) {
        _reauthenticateStaleSession();
      }
    });
  }

  Future<void> _reauthenticateStaleSession() async {
    final supabase = ref.read(supabaseClientProvider);
    final hasSession = supabase.auth.currentSession != null;
    if (!hasSession) return;

    try {
      await supabase.auth.refreshSession();
      await InternalAuthService.markSync();
    } catch (_) {
      // Session token expired or revoked during offline period → force re-login
      final vault = SecureVaultService();
      await vault.clearAll();
      Hive.box('auth').delete(HiveService.lastOnlineSyncKey);
      await supabase.auth.signOut();
      ref.invalidate(authStateProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  void _refreshData() {
    try { ref.read(jobListProvider.notifier).refresh(); } catch (_) {}
    try { ref.read(customerListProvider.notifier).refresh(); } catch (_) {}
    try { ref.read(notesListProvider.notifier).refresh(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Keystone',
      debugShowCheckedModeBanner: false,
      theme: buildLightAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => PrivacyOverlay(
        child: _ErrorBoundary(child: child ?? const SizedBox.shrink()),
      ),
    );
  }

  void _logError(String error, String stack) {
    try {
      Supabase.instance.client.from(SupabaseConstants.appEventsTable).insert({
        'event_name': 'app_error',
        'properties': {'error': error, 'stack': stack.substring(0, stack.length.clamp(0, 500))},
      });
    } catch (e) {
      debugPrint('[KS:APP] Remote error log failed: $e');
    }
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
      debugPrint('[KS:ERROR] ${details.exception}');
      debugPrint('[KS:ERROR] Stack: ${details.stack}');
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _hasError = true));
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: context.ksc.error500),
                const SizedBox(height: 24),
                Text('SOMETHING WENT WRONG',
                    style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text('An unexpected error occurred. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: context.ksc.neutral500, letterSpacing: 0.5)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _hasError = false),
                  child: const Text('TRY AGAIN'),
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
