import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: Stack(
        children: [
          // 01. THE INDUSTRIAL CANVAS
          Positioned(
            top: -100,
            right: -100,
            child: Icon(
              LineAwesomeIcons.tools_solid,
              size: 400,
              color: context.ksc.primary800.withValues(alpha: 0.3),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 02. LOGO ANCHOR
                  KsLogo(size: 56, primaryColor: context.ksc.white)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: -0.2, end: 0),

                  const Spacer(flex: 2),

                  // 03. EYEBROW - INDUSTRIAL CAPTION
                  Text(
                    'LOCKSMITH OPERATING SYSTEM',
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),

                  const SizedBox(height: 12),

                  // 04. ASYMMETRIC DISPLAY
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.display.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: context.ksc.white,
                        height: 0.9,
                        letterSpacing: -1,
                      ),
                      children: [
                        const TextSpan(text: 'KEY\n'),
                        TextSpan(
                          text: 'STONE',
                          style: TextStyle(color: context.ksc.accent500),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 24),

                  // 05. SUPPORTING STATEMENT
                  Text(
                    "The professional tool for independent locksmiths in Ghana.",
                    style: AppTextStyles.h2.copyWith(
                      color: context.ksc.neutral300,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const Spacer(flex: 3),

                  // 06. THE COMMAND SURFACE (Bottom Action Pattern)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        top: BorderSide(color: context.ksc.primary700, width: 1),
                        bottom: BorderSide(color: context.ksc.primary700, width: 1),
                        left: BorderSide(color: context.ksc.primary700, width: 1),
                        right: BorderSide(color: context.ksc.primary700, width: 1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(RouteNames.phoneEntry),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                 Text(
                                   'GET STARTED',
                                   style: AppTextStyles.h2.copyWith(
                                     color: context.ksc.white,
                                     fontWeight: FontWeight.w700,
                                     letterSpacing: 1.5,
                                   ),
                                 ),
                                  Icon(
                                    LineAwesomeIcons.angle_right_solid,
                                    color: context.ksc.accent500,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 2,
                                width: 40,
                                color: context.ksc.accent500,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    'Already have an account?',
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.ksc.neutral400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SIGN IN',
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.ksc.accent500,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
