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
      backgroundColor: AppColors.primary900,
      body: Stack(
        children: [
          // 01. THE VOID TEXTURE (With light lift for logo contrast)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.8), // Lift exactly behind the logo
                radius: 1.5,
                colors: [
                  Color(0xFF1E3F7A), 
                  AppColors.primary900,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 02. SIGNATURE (Sized and lifted for contrast)
                  const KsLogo(size: 48, primaryColor: AppColors.white)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: -0.2, end: 0),
                  
                  const Spacer(flex: 2),
                  
                  // 03. EYEBROW
                  Text(
                    'LOCKSMITH  M G M T.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent400,
                      letterSpacing: 4.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // 04. ASYMMETRIC DISPLAY (Scaled for mobile widths)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KEY',
                        style: AppTextStyles.display.copyWith(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          height: 0.85,
                          letterSpacing: -2,
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Text(
                          'STONE',
                          style: AppTextStyles.display.copyWith(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent500,
                            height: 0.85,
                            letterSpacing: -2,
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutBack),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 05. SUPPORT
                  Text(
                    "Built for Ghana's professional locksmiths.",
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.neutral300,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                  
                  const Spacer(flex: 3),
                  
                  // 06. THE COMMAND SURFACE (Flexible Layout Fix)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary700,
                      borderRadius: BorderRadius.circular(4), 
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 40,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(RouteNames.phoneEntry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'BUILD YOUR BACKBONE',
                                      style: AppTextStyles.h2.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: AppColors.accent500),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: AppColors.primary900, thickness: 1),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => context.push(RouteNames.phoneEntry),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutral300,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Already have an account?  '),
                                      TextSpan(
                                        text: 'SIGN IN',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.accent500,
                                          fontWeight: FontWeight.w800,
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
                  ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
