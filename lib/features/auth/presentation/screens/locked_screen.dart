import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_logo.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LockedScreen extends StatefulWidget {
  const LockedScreen({super.key});

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  bool _isChecking = false;

  Future<void> _retryConnection() async {
    setState(() => _isChecking = true);
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi)) {
      if (mounted) context.go(RouteNames.phoneEntry);
    } else {
      setState(() => _isChecking = false);
    }
  }

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
                KsLogo(size: 120, primaryColor: context.ksc.neutral600),
                const SizedBox(height: 48),
                Text(
                  'KEYSECURE LOCKED',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Your device identity needs to be verified.\nConnect to the internet to unlock your account.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isChecking ? null : _retryConnection,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.ksc.accent500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _isChecking
                            ? SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.primary900),
                              )
                            : Text(
                                'RETRY CONNECTION',
                                style: AppTextStyles.label.copyWith(
                                  color: context.ksc.primary900,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
