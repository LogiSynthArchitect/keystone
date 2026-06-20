import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/secure_vault_service.dart';
import '../../../../core/services/internal_auth/models/auth_method.dart';
import '../../../../core/services/internal_auth/models/unlock_result.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';
import '../../../../core/widgets/ks_logo_animated.dart';
import '../providers/auth_notifier.dart';

class TransitionScreen extends ConsumerStatefulWidget {
  const TransitionScreen({super.key});

  @override
  ConsumerState<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends ConsumerState<TransitionScreen> {
  bool _canNavigate = false;
  bool _profileTimedOut = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Self-heal corrupted vault states on every app launch
    Future.microtask(() async {
      final vault = SecureVaultService();
      await vault.healVaultState();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _canNavigate = true);
    });

    // Fallback: if profile takes >10s, proceed without it
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_profileTimedOut) {
        setState(() => _profileTimedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final profileLoading = profileState.isLoading;
    final authUiState = ref.watch(authNotifierProvider);

    if (_canNavigate && !_hasNavigated && !authStateAsync.isLoading && (!profileLoading || _profileTimedOut)) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final state = authStateAsync.valueOrNull ?? const AuthState();
        ref.read(authNotifierProvider.notifier).reset();
        if (!state.isAuthenticated) {
          context.go(RouteNames.landing);
        } else if (!state.hasProfile) {
          context.go(RouteNames.onboarding);
        } else if (profile == null ||
            profile.termsAcceptedAt == null ||
            profile.termsVersion < RouteNames.currentTermsVersion) {
          context.go(RouteNames.termsAccept);
        } else if (state.needsPasswordUpgrade) {
          context.go(RouteNames.upgradeAccount);
        } else if (!state.isLocallyUnlocked) {
          final supabase = ref.read(supabaseClientProvider);
          final service = InternalAuthService(supabase);
          final result = await service.tryAutoLogin();
          if (!mounted) return;
          if (result is UnlockSuccess) {
            ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
            ref.read(authNotifierProvider.notifier).reset();
            if (mounted) context.go(RouteNames.dashboard);
          } else if (result is UnlockLocked) {
            ref.read(authNotifierProvider.notifier).reset();
            if (mounted) context.go(RouteNames.locked);
          } else if (result is UnlockNeedsOnline) {
            ref.read(authNotifierProvider.notifier).reset();
            if (mounted) context.go(RouteNames.staleData, extra: result);
          } else {
            ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
            ref.read(authNotifierProvider.notifier).reset();
            if (mounted) context.go(RouteNames.dashboard);
          }
        } else {
          // Going to dashboard — check if quick unlock needs setup
          final vault = SecureVaultService();
          final method = await vault.getEnrolledMethod();
          if (method == AuthMethod.none && mounted) {
            // No local credentials — enforce mandatory PIN setup
            if (mounted) context.go(RouteNames.pinSetup);
            return; // HARD STOP — no dashboard until PIN is enrolled
          }
          if (mounted) context.go(RouteNames.dashboard);
        }
      });
    }

    String greeting = '';
    String subtext = '';
    bool isIdentified = false;

    authStateAsync.whenData((state) {
      if (state.isAuthenticated) {
        isIdentified = true;
        final isJustForged = authUiState.hasProfile == true;

        if (isJustForged) {
          greeting = 'PROFILE CREATED';
          subtext = 'Redirecting to your dashboard...';
        } else if (state.hasProfile && profile != null) {
          greeting = 'WELCOME BACK,\n${profile.displayName.toUpperCase()}';
          subtext = _getSubtextForFlow(state);
        } else {
          greeting = 'VERIFYING...';
          subtext = 'Connecting to Arclock...';
        }
      }
    });

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KsLogoAnimated(size: 140),
            if (isIdentified) ...[
              const SizedBox(height: 40),
              FadeInDelayed(
                child: Column(
                  children: [
                    Text(
                      greeting,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: context.ksc.accent500,
                        height: 1.1,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtext,
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.ksc.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSubtextForFlow(AuthState state) {
    // Determine transition message based on how the user arrived
    // Re-auth: "Device unlocked."
    // Forgot: "Password has been reset."
    // Upgrade: "Your security has been upgraded."
    // Default: "Getting things ready..."
    return 'Loading your account...';
  }
}

class FadeInDelayed extends StatefulWidget {
  final Widget child;
  const FadeInDelayed({super.key, required this.child});

  @override
  State<FadeInDelayed> createState() => _FadeInDelayedState();
}

class _FadeInDelayedState extends State<FadeInDelayed> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
