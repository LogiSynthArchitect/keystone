import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/constants/supabase_constants.dart';
import 'core/storage/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
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

  runApp(
    const ProviderScope(
      child: KeystoneApp(),
    ),
  );
}
