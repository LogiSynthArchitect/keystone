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

class StaleDataScreen extends ConsumerStatefulWidget {
  final UnlockNeedsOnline result;
  const StaleDataScreen({super.key, required this.result});

  @override
  ConsumerState<StaleDataScreen> createState() => _StaleDataScreenState();
}

class _StaleDataScreenState extends ConsumerState<StaleDataScreen> {
  bool _isVerifying = false;
  bool _isOffline = false;

  String get _ageText {
    final ls = widget.result.lastSync;
    if (ls == null) return 'never';
    final diff = DateTime.now().difference(ls);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}';
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
                  _isOffline ? LineAwesomeIcons.wifi_solid : LineAwesomeIcons.shield_alt_solid,
                  size: 56,
                  color: _isOffline ? context.ksc.warning500 : context.ksc.accent500,
                ).animate().fadeIn().scaleY(begin: 0, end: 1),
                const SizedBox(height: 32),
                Text(
                  'VERIFY IDENTITY',
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.accent500,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  'SESSION EXPIRED',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  _isOffline
                      ? 'Unable to reach the server. Your cached data may be outdated since $_ageText.'
                      : 'Last server connection was $_ageText ago.\nReconnect to confirm your identity.',
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
                    onTap: _isVerifying ? null : _verify,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isOffline ? context.ksc.warning500 : context.ksc.accent500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _isVerifying
                            ? SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.primary900),
                              )
                            : Text(
                                _isOffline ? 'RETRY CONNECTION' : 'VERIFY & CONTINUE',
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
                if (_isOffline) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _skipProceed,
                    child: Text(
                      'PROCEED WITH CACHED DATA',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
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
