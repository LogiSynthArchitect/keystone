import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';

class MinVersionGateScreen extends StatelessWidget {
  const MinVersionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LineAwesomeIcons.exclamation_triangle_solid,
                  size: 56,
                  color: Colors.orange,
                ).animate().fadeIn().scaleY(begin: 0, end: 1),
                const SizedBox(height: 32),
                Text(
                  'UPDATE REQUIRED',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  'Your app version is no longer supported.\nPlease update to continue.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      const storeUrl = 'https://play.google.com/store/apps/details?id=com.keystone.app';
                      final uri = Uri.parse(storeUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.ksc.accent500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          'CHECK FOR UPDATE',
                          style: AppTextStyles.label.copyWith(
                            color: context.ksc.primary900,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
