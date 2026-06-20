import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/auth_notifier.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';

class UpgradeAccountScreen extends ConsumerStatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  ConsumerState<UpgradeAccountScreen> createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends ConsumerState<UpgradeAccountScreen> {
  String _password = '';
  String _confirmPassword = '';

  String? get _passwordError {
    final pw = _password;
    if (pw.isEmpty) return null;
    if (pw.length < 8) return 'Minimum 8 characters';
    if (!pw.contains(RegExp(r'[A-Za-z]'))) return 'Must include a letter';
    if (!pw.contains(RegExp(r'[0-9]'))) return 'Must include a number';
    return null;
  }

  String? get _confirmError {
    if (_confirmPassword.isEmpty) return null;
    if (_confirmPassword != _password) return 'Passwords do not match';
    return null;
  }

  bool get _canSubmit {
    return _passwordError == null && _confirmError == null
        && _password.isNotEmpty
        && _confirmPassword.isNotEmpty;
  }

  Future<void> _onUpgrade() async {
    if (!_canSubmit) return;
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);

    final pw = _password;
    bool success = false;
    try {
      success = await service.upgradeAccount(pw);
    } catch (e) {
      // "same_password" error from Supabase means password was already set
      // — treat as success since the account is already upgraded.
      if (e is supa.AuthException && e.message.contains('same_password')) {
        success = true;
      } else {
        debugPrint('[KS:UPGRADE] upgradeAccount threw: $e');
      }
    }

    if (!success) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).setError(
          'Password update failed. Try a different password.',
        );
      }
      return;
    }

    if (!mounted) return;
    final authBox = Hive.box('auth');
    authBox.put('password_upgraded', true);
    // Best-effort server sync: save password_created flag to profile.
    // Retry once if the first attempt fails to avoid silent failures.
    try {
      await supabase.from('profiles').update({
        'password_created': true,
      }).eq('user_id', supabase.auth.currentUser!.id);
    } catch (_) {
      try {
        await supabase.from('profiles').update({
          'password_created': true,
        }).eq('user_id', supabase.auth.currentUser!.id);
      } catch (e) {
        debugPrint('[KS:UPGRADE] password_created update failed after retry: $e');
      }
    }
    // Force session + auth state refresh so router sees updated identities
    try {
      await supabase.auth.refreshSession();
    } catch (_) {}
    await ref.read(authStateProvider.notifier).refresh();
    if (!mounted) return;
    context.go(RouteNames.transition);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final errorMessage = authState.errorMessage;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBackButton(context),
                    const SizedBox(height: 48),

                    // Small "REQUIRED" label (11px, 900, red, uppercase)
                    Text(
                      'REQUIRED',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: context.ksc.error500,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 4),

                    Text(
                      'IMPROVE SECURITY',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'Set a password to secure your account.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.ksc.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.ksc.warning500),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LineAwesomeIcons.shield_alt_solid, color: context.ksc.warning500, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SECURITY IMPROVEMENT',
                                  style: AppTextStyles.label.copyWith(
                                    color: context.ksc.warning500,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your account needs a password for improved security. '
                                  'This takes 30 seconds.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: context.ksc.neutral400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 48),
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 24),
                    ],
                    _buildPasswordField(context),
                    const SizedBox(height: 16),
                    _buildConfirmField(context),
                    const SizedBox(height: 20),
                    _buildHintList(context),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) => GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.ksc.primary800.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: context.ksc.primary700.withValues(alpha: 0.3)),
          ),
          child: Icon(LineAwesomeIcons.angle_left_solid, size: 18, color: context.ksc.white),
        ),
      );

  Widget _buildPasswordField(BuildContext context) {
    return FocusSafeTextField(
      label: 'Password',
      hint: 'New password',
      obscureText: true,
      onChanged: (v) => setState(() => _password = v),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildConfirmField(BuildContext context) {
    return FocusSafeTextField(
      label: 'Confirm Password',
      hint: 'Confirm password',
      obscureText: true,
      onChanged: (v) => setState(() => _confirmPassword = v),
      onSubmitted: (_) => _onUpgrade(),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHintList(BuildContext context) {
    final pw = _password;
    final minCharsMet = pw.length >= 8;
    final hasLetterMet = pw.contains(RegExp(r'[A-Za-z]'));
    final hasNumberMet = pw.contains(RegExp(r'[0-9]'));
    final matchMet = _confirmPassword == _password
        && _confirmPassword.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hintItem('At least 8 characters', minCharsMet),
        const SizedBox(height: 4),
        _hintItem('Includes a letter', hasLetterMet),
        const SizedBox(height: 4),
        _hintItem('Includes a number', hasNumberMet),
        const SizedBox(height: 4),
        _hintItem('Passwords match', matchMet),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _hintItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? LineAwesomeIcons.check_circle_solid : Icons.circle,
          size: 12,
          color: met ? context.ksc.success500 : context.ksc.neutral600,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: met ? context.ksc.success500 : context.ksc.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    return KsButton(
      label: _canSubmit ? 'PASSWORD REQUIRED' : 'PASSWORD REQUIRED',
      variant: KsButtonVariant.cta,
      edgeToEdge: true,
      isLoading: isLoading,
      onPressed: _canSubmit ? _onUpgrade : null,
    ).animate().fadeIn(delay: 600.ms);
  }
}