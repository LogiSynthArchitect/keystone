import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  @override
  void initState() {
    super.initState();
    _startTransition();
  }

  void _startTransition() async {
    // MANDATORY: 6-second total brand moment for the cinematic intro
    await Future.delayed(const Duration(seconds: 6));
    if (!mounted) return;

    final authState = ref.read(authStateProvider).valueOrNull;

    // Final routing decision after the 6s brand moment
    if (authState == null || !authState.isAuthenticated) {
      context.go(RouteNames.landing);
    } else if (!authState.hasProfile) {
      context.go(RouteNames.onboarding);
    } else {
      context.go(RouteNames.jobs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final profile = ref.watch(profileProvider).profile;
    final authUiState = ref.watch(authNotifierProvider);

    String greeting = "";
    String subtext = "";
    bool isIdentified = false;

    authStateAsync.whenData((state) {
      if (state.isAuthenticated) {
        isIdentified = true;
        // Check for Veteran status via Profile or Auth State
        if ((state.hasProfile && profile != null) || (authUiState.hasProfile == true && profile != null)) {
          // VETERAN: Recognition of existing backbone
          greeting = "WELCOME BACK,\n${profile.displayName.toUpperCase()}";
          subtext = "Synchronizing backbone...";
        } else {
          // RECRUIT: Acknowledgement of forging a new identity
          greeting = "PROFILE FORGED";
          subtext = "Establishing your workspace...";
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary900, // THE VOID: Fixed "Flashbang" background
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
                        color: AppColors.accent500, // Gold for high authority
                        height: 1.1,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtext,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.neutral400, // Lightened for dark background contrast
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
