import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary900, // The Void
      body: Stack(
        children: [
          // 01. TEXTURE (Simulated Grain via subtle gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white10,
                  Colors.transparent,
                ],
                stops: [0.0, 0.3],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 02. SIGNATURE
                  const KsLogo(size: 48).animate().fadeIn(duration: 800.ms),
                  
                  const Spacer(flex: 2),
                  
                  // 03. EYEBROW (Tracked out, Gold)
                  Text(
                    'LOCKSMITH  M G M T.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent500,
                      letterSpacing: 4.0,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),
                  
                  const SizedBox(height: 12),
                  
                  // 04. THE DISPLAY (Massive, Left Aligned)
                  Text(
                    'KEYSTONE',
                    style: AppTextStyles.display.copyWith(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: -1.5,
                      height: 0.9,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart, duration: 800.ms),
                  
                  const SizedBox(height: 24),
                  
                  // 05. THE SUPPORT
                  Text(
                    "Built for Ghana's\nprofessional locksmiths.",
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.neutral400,
                      height: 1.4,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms),
                  
                  const Spacer(flex: 3),
                  
                  // 06. THE ACTION CARD (Floating Surface)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary700,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_rounded, color: AppColors.accent500),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(height: 1, color: AppColors.primary900), // The Cut
                              const SizedBox(height: 20),
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                                  children: [
                                    const TextSpan(text: 'Already have an account?  '),
                                    TextSpan(
                                      text: 'Sign in.',
                                      style: AppTextStyles.label.copyWith(color: AppColors.accent500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack, duration: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
