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
          // ── Ambient glow orbs ──
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.ksc.accent500.withValues(alpha: 0.05),
                    context.ksc.accent500.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.ksc.primary500.withValues(alpha: 0.05),
                    context.ksc.primary500.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo ──
                  Row(
                    children: [
                      KsLogo(size: 44, primaryColor: context.ksc.white),
                      const SizedBox(width: 12),
                      Text(
                        'ARCLOCK',
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 700.ms),

                  const Spacer(flex: 2),

                  // ── Asymmetric headline ──
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.display.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: context.ksc.white,
                        height: 0.85,
                        letterSpacing: -1.5,
                      ),
                      children: [
                        const TextSpan(text: 'MASTER\n'),
                        const TextSpan(text: 'YOUR\n'),
                        TextSpan(
                          text: 'WORKFLOW',
                          style: TextStyle(color: context.ksc.accent500),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.08, end: 0),

                  const SizedBox(height: 18),

                  // ── Tagline ──
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.82,
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.body.copyWith(
                          color: context.ksc.neutral400,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        children: [
                          const TextSpan(text: 'The professional tool for '),
                          TextSpan(
                            text: 'independent locksmiths',
                            style: TextStyle(color: context.ksc.white, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' in Ghana.'),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 28),

                  // ── Feature row with icons ──
                  Row(
                    children: [
                      _buildFeature(context, LineAwesomeIcons.cloud_download_alt_solid, 'Offline'),
                      _buildFeature(context, LineAwesomeIcons.clipboard_list_solid, 'Jobs'),
                      _buildFeature(context, LineAwesomeIcons.file_invoice_solid, 'Invoices'),
                    ],
                  ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 20),

                  // ── Gradient divider ──
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.ksc.primary700,
                          context.ksc.primary700.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── CTA card ──
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(RouteNames.phoneEntry),
                      borderRadius: BorderRadius.circular(12),
                      splashColor: context.ksc.accent500.withValues(alpha: 0.08),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: Stack(
                          children: [
                            // Gold left accent bar
                            Positioned(
                              left: -24,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: context.ksc.accent500,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'GET STARTED',
                                      style: AppTextStyles.h3.copyWith(
                                        color: context.ksc.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: context.ksc.accent500,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LineAwesomeIcons.angle_right_solid,
                                        size: 16,
                                        color: Color(0xFF0A1628),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: AppTextStyles.caption.copyWith(
                                        color: context.ksc.neutral400,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => context.push(RouteNames.phoneEntry),
                                      child: Text(
                                        'SIGN IN',
                                        style: AppTextStyles.caption.copyWith(
                                          color: context.ksc.accent500,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1050.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: context.ksc.accent500, size: 22),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral300,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
