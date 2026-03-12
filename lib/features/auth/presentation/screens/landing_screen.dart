import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ks_logo.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoSlide;
  late Animation<double> _textFade;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _logoSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.3, 0.65, curve: Curves.easeOut)),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: Column(
        children: [

          // ── TOP light section ──────────────────────────────
          Expanded(
            flex: 62,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Logo
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Opacity(
                          opacity: _logoFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _logoSlide.value),
                            child: child,
                          ),
                        ),
                        child: const KsLogo(size: 110),
                      ),

                      const SizedBox(height: 24),

                      // Text
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Opacity(
                          opacity: _textFade.value,
                          child: child,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'LOCKSMITH MANAGEMENT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'BarlowSemiCondensed',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF9A825),
                                letterSpacing: 3.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keystone',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'BarlowSemiCondensed',
                                fontSize: 54,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary700,
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Built for Ghana's professional locksmiths",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'BarlowSemiCondensed',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF757575),
                                height: 1.5,
                                letterSpacing: 0.2,
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

          // ── BOTTOM navy section ────────────────────────────
          Expanded(
            flex: 38,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _buttonFade.value,
                child: child,
              ),
              child: Container(
                width: double.infinity,
                color: AppColors.primary700,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => context.push(RouteNames.phoneEntry),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9A825),
                            foregroundColor: AppColors.primary700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontFamily: 'BarlowSemiCondensed',
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => context.push(RouteNames.phoneEntry),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'BarlowSemiCondensed',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  color: Color(0xFFF9A825),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
