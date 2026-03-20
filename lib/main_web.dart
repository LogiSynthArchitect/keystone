import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/ks_colors.dart';
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
      title: 'Keystone',
      theme: buildLightAppTheme(),
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
      backgroundColor: context.ksc.primary900,
      body: Column(
        children: [
          // Top bar
          Container(
            width: double.infinity,
            color: context.ksc.primary800,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              border: Border(bottom: BorderSide(color: context.ksc.primary700)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: context.ksc.accent500,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: SvgPicture.asset(
                          'assets/logo/keystone_logo.svg',
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'KEYSTONE',
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.ksc.primary700),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A1628).withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: SvgPicture.asset(
                            'assets/logo/keystone_logo.svg',
                            colorFilter: ColorFilter.mode(context.ksc.accent500, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Keystone',
                        style: AppTextStyles.h1.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Built for Locksmiths in Ghana',
                        style: AppTextStyles.body.copyWith(
                          color: context.ksc.accent500,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: context.ksc.primary700),
                      const SizedBox(height: 24),
                      Text(
                        'Manage your jobs and stay connected with your customers.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: context.ksc.neutral500,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: Row(
                          children: [
                            Icon(LineAwesomeIcons.user_circle_solid, color: context.ksc.accent500, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Looking for a locksmith? Ask them to share their profile link with you.',
                                style: AppTextStyles.caption.copyWith(
                                  color: context.ksc.neutral500,
                                  height: 1.6,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
