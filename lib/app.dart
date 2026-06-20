import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'core/widgets/inactivity_lock_wrapper.dart';
import 'core/widgets/dev_auth_panel.dart';
import 'core/services/internal_auth/secure_vault_service.dart';
import 'core/network/connectivity_service.dart';
import 'core/services/internal_auth/internal_auth_service.dart';
import 'core/storage/hive_service.dart';
import 'features/job_logging/presentation/providers/job_providers.dart';
import 'features/customer_history/presentation/providers/customer_providers.dart';
import 'features/knowledge_base/presentation/providers/notes_providers.dart';
import 'core/services/local_notification_service.dart';
import 'core/router/route_names.dart';
import 'core/providers/sync_orchestrator_provider.dart';

class ArclockApp extends ConsumerStatefulWidget {
  const ArclockApp({super.key});

  @override
  ConsumerState<ArclockApp> createState() => _ArclockAppState();
}

class _ArclockAppState extends ConsumerState<ArclockApp> with WidgetsBindingObserver {
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
      _initNotificationTap();
    });
  }

  void _initNotificationTap() {
    final router = ref.read(routerProvider);
    LocalNotificationService.onNotificationTap = (jobId) {
      try {
        router.push(RouteNames.jobDetail(jobId));
      } catch (e) {
        debugPrint('[KS:APP] Notification tap navigation failed: $e');
      }
    };
  }

  void _initAuthGuard() {
    final supabase = ref.read(supabaseClientProvider);
    supabase.auth.onAuthStateChange.listen((data) async {
      if (data.session == null && mounted) {
        // If offline, the signedOut is likely a transient network failure
        // during session recovery or auto-refresh. Keep local data —
        // re-authentication will be handled at point of need.
        final connectivity = ConnectivityService();
        if (!await connectivity.isConnected) {
          debugPrint('[KS:APP] signedOut while offline — preserving local data');
          return;
        }
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
        _runBackgroundSync();
      }
    });
  }

  Future<void> _runBackgroundSync() async {
    try {
      final results = await ref.read(syncOrchestratorProvider).runFullSync();
      for (final phase in results) {
        debugPrint('[KS:SYNC] Phase "${phase.name}": ${phase.success ? "OK" : "FAILED — ${phase.error}"}');
      }
      // Refresh UI after sync completes
      _refreshData();
    } catch (e) {
      debugPrint('[KS:SYNC] Sync failed: $e');
    }
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
      _runBackgroundSync();
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
      title: 'Arclock',
      debugShowCheckedModeBanner: false,
      theme: buildLightAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => InactivityLockWrapper(
        child: Stack(
          children: [
            _BackPressExitHandler(child: child ?? const SizedBox.shrink()),
            const DevAuthPanel(),
          ],
        ),
      ),
    );
  }

  void _logError(String error, String stack) {
    try {
      Supabase.instance.client.from('app_events').insert({
        'event_name': 'app_error',
        'properties': {'error': error, 'stack': stack.substring(0, stack.length.clamp(0, 500))},
      });
    } catch (e) {
      debugPrint('[KS:APP] Remote error log failed: $e');
    }
  }
}

/// Wraps app content with [PopScope] to implement double-back-to-exit.
///
/// When the user presses the system back button on a root route and no
/// route is popped, a SnackBar appears: "Tap back again to exit". A second
/// press within 2 seconds closes the app. This prevents accidental exits.
class _BackPressExitHandler extends StatefulWidget {
  final Widget child;
  const _BackPressExitHandler({required this.child});

  @override
  State<_BackPressExitHandler> createState() => _BackPressExitHandlerState();
}

class _BackPressExitHandlerState extends State<_BackPressExitHandler> {
  DateTime _lastBackPress = DateTime.now();
  static const _exitDelay = Duration(seconds: 2);
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBarController;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        if (now.difference(_lastBackPress) < _exitDelay) {
          _snackBarController?.close();
          SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          _snackBarController?.close();
          _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tap back again to exit'),
              duration: _exitDelay,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: widget.child,
    );
  }
}
