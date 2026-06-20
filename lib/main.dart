import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fluttersdk_dusk/dusk.dart';
import 'package:fluttersdk_telescope/telescope.dart';
import 'core/constants/supabase_constants.dart';
import 'core/services/local_notification_service.dart';
import 'core/storage/hive_service.dart';
import 'core/recovery/reconcile_pending_edits.dart';
import 'core/recovery/reconcile_pending_restocks.dart';
import 'core/recovery/reconcile_pending_schedule_generation.dart';
import 'core/recovery/reconcile_analytics_invalidations.dart';
import 'core/widgets/force_update_screen.dart';
import 'features/reminders/engine/reminder_worker.dart';
import 'app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 00. AI TESTING SUPPORT — dusk + telescope VM Service extensions
  if (kDebugMode) {
    DuskPlugin.install();
    TelescopePlugin.install();
  }

  // 01. GLOBAL ERROR HANDLER (Avoid Red Screen of Death in field)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[KS:FATAL] ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (details) {
    return const Material(
      color: Color(0xFF0D1117), 
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Color(0xFFF4A300), size: 48), 
            SizedBox(height: 16),
            Text(
              'SOMETHING WENT WRONG',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              'A technical error occurred. Please restart the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  };

  // 02. PRESERVE NATIVE SPLASH
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await HiveService.initialize();

  // Migrate Hive data boxes that have schema version bumps.
  // Per-box schema versions are defined in HiveService.boxSchemaVersions.
  // Each box gets a targeted migration instead of a nuclear wipe+resync.
  await HiveService.migrateAllBoxes();

  // 02b. RECOVER PENDING EDIT TRANSACTIONS (cross-box WAL replay)
  await reconcilePendingEdits();

  // 02c. RECOVER PENDING RESTOCK TRANSACTIONS (restock WAL replay)
  await reconcilePendingRestocks();

  // 02d. RECOVER PENDING SCHEDULE GENERATION (schedule gen WAL replay)
  await reconcilePendingScheduleGeneration();

  // 02e. RECOVER ANALYTICS ROLLUPS (invalidation WAL replay + initial seed)
  await reconcileAnalyticsInvalidations();

  // Init local notifications (tap callback wired in ArclockApp with GoRouter access)
  await LocalNotificationService.initialize();

  // Init background workmanager for periodic reminder checks
  // Linux/desktop platforms may not have a workmanager implementation.
  try {
    await Workmanager().initialize(reminderBackgroundCallback, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'arclock-reminder-check',
      backgroundTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (_) {
    debugPrint('[KS:MAIN] Workmanager not available on this platform');
  }

  // 03. VERSION GATE — block outdated clients
  String? apkUrl;
  String? releaseNotes;
  String? latestVersion;
  bool forceUpdate = false;

  try {
    final pkg = await PackageInfo.fromPlatform();
    final localVer = pkg.version;
    final metaBox = Hive.box(HiveService.metaBox);
    await metaBox.put('local_app_version', localVer);

    final supabase = Supabase.instance.client;
    final configResp = await supabase
        .from('app_config')
        .select('min_app_version, latest_version, force_update, apk_url, release_notes')
        .limit(1)
        .single();
    final minVer = configResp['min_app_version'] as String? ?? '1.0.0';
    latestVersion = configResp['latest_version'] as String? ?? localVer;
    forceUpdate = configResp['force_update'] as bool? ?? false;
    apkUrl = configResp['apk_url'] as String?;
    releaseNotes = configResp['release_notes'] as String?;

    await metaBox.put('min_app_version', minVer);
    await metaBox.put('latest_app_version', latestVersion);
    await metaBox.put('apk_url', apkUrl);
    await metaBox.put('release_notes', releaseNotes);

    final localParts = localVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final minParts = minVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (localParts.length < 3) localParts.add(0);
    while (minParts.length < 3) minParts.add(0);

    final isOutdated = localParts[0] < minParts[0] ||
        (localParts[0] == minParts[0] && localParts[1] < minParts[1]) ||
        (localParts[0] == minParts[0] && localParts[1] == minParts[1] && localParts[2] < minParts[2]);

    await metaBox.put('app_is_outdated', isOutdated);
    debugPrint('[KS:VERSION] Local: $localVer, Min: $minVer, Latest: $latestVersion, Force: $forceUpdate, Outdated: $isOutdated');
  } catch (e) {
    debugPrint('[KS:VERSION] Version check failed (offline or no config table): $e');
    final metaBox = Hive.box(HiveService.metaBox);
    await metaBox.put('app_is_outdated', false);
  }

  // 03b. RENDER — force update screen or normal app
  Widget rootWidget;
  final metaBox = Hive.box(HiveService.metaBox);
  final isOutdated = metaBox.get('app_is_outdated', defaultValue: false) as bool;
  final localVer = metaBox.get('local_app_version', defaultValue: '1.0.0') as String;
  latestVersion ??= metaBox.get('latest_app_version', defaultValue: '1.0.0') as String;
  apkUrl ??= metaBox.get('apk_url', defaultValue: '') as String;
  releaseNotes ??= metaBox.get('release_notes', defaultValue: '') as String;

  if (isOutdated) {
    rootWidget = ForceUpdateScreen(
      currentVersion: localVer,
      latestVersion: latestVersion,
      apkUrl: apkUrl.isNotEmpty ? apkUrl : null,
      releaseNotes: releaseNotes.isNotEmpty ? releaseNotes : null,
    );
  } else {
    rootWidget = const ProviderScope(child: ArclockApp());
  }

  runApp(rootWidget);
}
