import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/models/unlock_result.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/widgets/ks_button.dart';

class StaleDataScreen extends ConsumerStatefulWidget {
  final UnlockNeedsOnline result;
  const StaleDataScreen({super.key, required this.result});

  @override
  ConsumerState<StaleDataScreen> createState() => _StaleDataScreenState();
}

class _StaleDataScreenState extends ConsumerState<StaleDataScreen> {
  bool _isVerifying = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Check connectivity immediately to avoid requiring a failed network
    // call before showing the cached-data escape hatch.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnectivityFirst());
  }

  Future<void> _checkConnectivityFirst() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      // Quick connectivity probe via lightweight HEAD
      await supabase.auth.refreshSession().timeout(const Duration(seconds: 3));
      if (mounted) {
        await InternalAuthService.markSync();
        context.go(RouteNames.dashboard);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOffline = true);
      }
    }
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.auth.refreshSession();
      await InternalAuthService.markSync();
      if (mounted) context.go(RouteNames.dashboard);
    } catch (_) {
      if (mounted) setState(() => _isOffline = true);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _skipProceed() {
    context.go(RouteNames.dashboard);
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
                Icon(
                  _isOffline ? LineAwesomeIcons.exclamation_triangle_solid : LineAwesomeIcons.shield_alt_solid,
                  size: 56,
                  color: _isOffline ? context.ksc.warning500 : context.ksc.accent500,
                ).animate().fadeIn().scaleY(begin: 0, end: 1),
                const SizedBox(height: 32),
                Text(
                  _isOffline ? 'OFFLINE' : 'SESSION EXPIRED',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  _isOffline
                      ? 'Your session expired while offline.\nYou can view cached data, but changes will not sync until you reconnect.'
                      : 'Your login session has expired.\nConnect to refresh and continue.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),
                if (!_isOffline)
                  KsButton(
                    label: 'VERIFY & CONTINUE',
                    onPressed: _isVerifying ? null : _verify,
                    isLoading: _isVerifying,
                    variant: KsButtonVariant.primary,
                  ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                // Cached data option always visible — no failed network call required
                GestureDetector(
                  onTap: _skipProceed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'PROCEED WITH CACHED DATA',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                if (_isOffline) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _verify,
                    child: Text(
                      'RETRY CONNECTION',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
