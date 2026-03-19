import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'features/technician_profile/presentation/screens/public_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable clean URLs (removes the # from the link)
  usePathUrlStrategy();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  runApp(const ProviderScope(child: KeystoneWebLite()));
}

class KeystoneWebLite extends StatelessWidget {
  const KeystoneWebLite({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _WebGatewayScreen(),
        ),
        GoRoute(
          path: '/p/:slug',
          builder: (context, state) => PublicProfileScreen(
            slug: state.pathParameters['slug']!,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Keystone Terminal',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _WebGatewayScreen extends StatelessWidget {
  const _WebGatewayScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary900,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent500, width: 2),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: AppColors.accent500, size: 36),
                ),
                const SizedBox(height: 32),
                Text(
                  'KEYSTONE',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TERMINAL',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent500,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: AppColors.primary700),
                const SizedBox(height: 24),
                Text(
                  'Professional job management for locksmiths in Ghana.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.neutral400,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Looking for a technician\'s profile?\nAsk them to share their profile link directly.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral600,
                    height: 1.8,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
