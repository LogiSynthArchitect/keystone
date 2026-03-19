import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/constants/supabase_constants.dart';
import 'core/storage/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // 01. PRESERVE NATIVE SPLASH
  // We keep the phone's static logo on screen until TransitionScreen is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await HiveService.initialize();

  runApp(
    const ProviderScope(
      child: KeystoneApp(),
    ),
  );
}
