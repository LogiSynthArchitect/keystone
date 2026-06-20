import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';

/// Dedicated password unlock screen from LockedScreen.
/// Back arrow returns to LockedScreen. On success: unlock → Dashboard.
class PasswordUnlockScreen extends ConsumerStatefulWidget {
  const PasswordUnlockScreen({super.key});

  @override
  ConsumerState<PasswordUnlockScreen> createState() =>
      _PasswordUnlockScreenState();
}

class _PasswordUnlockScreenState extends ConsumerState<PasswordUnlockScreen> {
  String _password = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _onSubmit() async {
    if (_password.length < 8 || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final service = InternalAuthService(supabase);

      final user = supabase.auth.currentUser;
      final phone = user?.phone ?? '';

      final session = await service.verifyPassword(phone, _password);
      if (session != null && mounted) {
        await ref.read(authStateProvider.notifier).refresh();
        if (!mounted) return;
        ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
        HapticFeedback.heavyImpact();
        await KsSuccessMoment.show(context, title: 'WELCOME BACK');
        if (mounted) context.go(RouteNames.transition);
      } else if (mounted) {
        setState(() => _error = 'Invalid password. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'An error occurred. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: 20),

                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: context.ksc.accent500, width: 3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          LineAwesomeIcons.key_solid,
                          color: context.ksc.accent500,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'ENTER PASSWORD',
                        style: TextStyle(
                          fontFamily: 'BarlowSemiCondensed',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 8),

                    const Center(
                      child: Text(
                        'Sign in with your cloud password',
                        style: TextStyle(
                          fontFamily: 'BarlowSemiCondensed',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8B949E),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 28),

                    // Error banner — only shown when set, triggers rebuild only on error
                    if (_error != null && _error!.isNotEmpty) ...[
                      KsBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],

                    // Wrap text field in RepaintBoundary to isolate it from parent rebuilds
                    RepaintBoundary(
                      child: _PasswordField(
                        onChanged: (v) => _password = v,
                        onSubmit: _onSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Keep button reactive without rebuilding the text field
            _UnlockButton(
              isLoading: _isLoading,
              onSubmit: _onSubmit,
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) => GestureDetector(
        onTap: () => context.go(RouteNames.locked),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.ksc.primary800.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border:
                Border.all(color: context.ksc.primary700.withValues(alpha: 0.3)),
          ),
          child: Icon(LineAwesomeIcons.angle_left_solid,
              size: 18, color: context.ksc.white),
        ),
      );
}

/// Separate widget for the password field — isolates it from parent rebuilds.
class _PasswordField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  const _PasswordField({required this.onChanged, required this.onSubmit});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  @override
  Widget build(BuildContext context) {
    return FocusSafeTextField(
      label: 'PASSWORD',
      hint: 'Enter your password',
      obscureText: true,
      autofocus: true,
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmit(),
    );
  }
}

/// Separate widget for the UNLOCK button — only this rebuilds on isLoading change.
class _UnlockButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  const _UnlockButton({required this.isLoading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: KsButton(
        label: 'UNLOCK',
        variant: KsButtonVariant.cta,
        onPressed: isLoading ? null : onSubmit,
        isLoading: isLoading,
      ),
    );
  }
}
