import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_logo_animated.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../providers/auth_notifier.dart';

class TransitionScreen extends ConsumerStatefulWidget {
  const TransitionScreen({super.key});

  @override
  ConsumerState<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends ConsumerState<TransitionScreen> {
  bool _isMinDelayPassed = false;

  @override
  void initState() {
    super.initState();
    
    // 01. SEAMLESS HANDOVER
    // Once this screen is painted, we remove the native splash
    // The user's eye won't see a jump because KsLogoAnimated is in the same spot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    // Ensure the branded reveal is seen for at least 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isMinDelayPassed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final profile = ref.watch(profileProvider).profile;
    final authUiState = ref.watch(authNotifierProvider);

    // Navigation logic: Move out once delay is passed AND data is ready
    if (_isMinDelayPassed && !authStateAsync.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final state = authStateAsync.valueOrNull ?? const AuthState();
        if (!state.isAuthenticated) {
          context.go(RouteNames.landing);
        } else if (!state.hasProfile) {
          context.go(RouteNames.onboarding);
        } else {
          context.go(RouteNames.jobs);
        }
      });
    }

    String greeting = "";
    String subtext = "";
    bool isIdentified = false;

    authStateAsync.whenData((state) {
      if (state.isAuthenticated) {
        isIdentified = true;
        // Check if they JUST came from onboarding (Forge) or are returning (Welcome)
        final isJustForged = authUiState.hasProfile == true;
        
        if (isJustForged) {
          greeting = "PROFILE CREATED";
          subtext = "Setting up your terminal...";
        } else if (state.hasProfile && profile != null) {
          greeting = "WELCOME BACK,\n${profile.displayName.toUpperCase()}";
          subtext = "Loading your account...";
        } else {
          greeting = "IDENTIFYING...";
          subtext = "Connecting to Keystone...";
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KsLogoAnimated(size: 240, primaryColor: AppColors.white),
            if (isIdentified) ...[
              const SizedBox(height: 60),
              FadeInDelayed(
                child: Column(
                  children: [
                    Text(
                      greeting,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.accent500,
                        height: 1.1,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtext,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
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
