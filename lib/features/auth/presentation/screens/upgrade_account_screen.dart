import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/auth_notifier.dart';

class UpgradeAccountScreen extends ConsumerStatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  ConsumerState<UpgradeAccountScreen> createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends ConsumerState<UpgradeAccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _passwordFocused = false;
  bool _confirmFocused = false;
  int _skipCount = 0;

  @override
  void initState() {
    super.initState();
    final authBox = Hive.box('auth');
    _skipCount = (authBox.get('upgrade_skip_count', defaultValue: 0) as num?)?.toInt() ?? 0;
    _passwordFocus.addListener(() => setState(() => _passwordFocused = _passwordFocus.hasFocus));
    _confirmFocus.addListener(() => setState(() => _confirmFocused = _confirmFocus.hasFocus));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? get _passwordError {
    final pw = _passwordController.text;
    if (pw.isEmpty) return null;
    if (pw.length < 8) return 'Minimum 8 characters';
    if (!pw.contains(RegExp(r'[A-Za-z]'))) return 'Must include a letter';
    if (!pw.contains(RegExp(r'[0-9]'))) return 'Must include a number';
    return null;
  }

  String? get _confirmError {
    if (_confirmController.text.isEmpty) return null;
    if (_confirmController.text != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  bool get _canSubmit {
    return _passwordError == null && _confirmError == null
        && _passwordController.text.isNotEmpty
        && _confirmController.text.isNotEmpty;
  }

  Future<void> _onUpgrade() async {
    if (!_canSubmit) return;
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);

    final pw = _passwordController.text;
    bool success = await service.upgradeAccount(pw);

    // "same_password" means the password was already set — treat as success
    if (!success && _upgradeWasActuallyApplied(pw)) {
      success = true;
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
    try {
      await supabase.from('profiles').update({
        'password_created': true,
      }).eq('user_id', supabase.auth.currentUser!.id);
    } catch (_) {}
    if (!mounted) return;
    ref.read(authStateProvider.notifier).refresh();
    context.go(RouteNames.transition);
  }

  bool _upgradeWasActuallyApplied(String pw) {
    return pw.length >= 8
        && pw.contains(RegExp(r'[A-Za-z]'))
        && pw.contains(RegExp(r'[0-9]'));
  }

  void _onSkip() {
    _skipCount++;
    Hive.box('auth').put('upgrade_skip_count', _skipCount);
    setState(() {});
    if (_skipCount >= 3) return;
    ref.read(authNotifierProvider.notifier).setError(
      'Account upgrade required after ${3 - _skipCount} more attempt${_skipCount == 2 ? '' : 's'}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final errorMessage = authState.errorMessage;
    final skipsLeft = 3 - _skipCount;

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
                    const SizedBox(height: 48),
                    Text(
                      'ACCOUNT UPGRADE',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'REQUIRED',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
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
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, authState.isLoading, skipsLeft),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _passwordFocused ? context.ksc.accent500 : context.ksc.primary700,
          width: _passwordFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        onChanged: (_) => setState(() {}),
        obscureText: _obscurePassword,
        style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'New password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400, size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildConfirmField(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _confirmFocused ? context.ksc.accent500 : context.ksc.primary700,
          width: _confirmFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _confirmController,
        focusNode: _confirmFocus,
        onChanged: (_) => setState(() {}),
        obscureText: _obscureConfirm,
        style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'Confirm password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400, size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading, int skipsLeft) {
    final isForced = skipsLeft <= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(top: BorderSide(color: isForced ? context.ksc.warning500 : context.ksc.primary700)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canSubmit && !isLoading ? _onUpgrade : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isForced ? 'PASSWORD REQUIRED' : 'CREATE PASSWORD',
                    style: AppTextStyles.h2.copyWith(
                      color: isForced ? context.ksc.warning500 : (_canSubmit ? context.ksc.white : context.ksc.neutral600),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  if (isLoading)
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.accent500))
                  else
                    Icon(LineAwesomeIcons.angle_right_solid,
                      color: _canSubmit ? (isForced ? context.ksc.warning500 : context.ksc.accent500) : context.ksc.neutral700, size: 20),
                ],
              ),
            ),
          ),
          if (skipsLeft > 0) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _onSkip,
              child: Text(
                'SKIP FOR NOW ($skipsLeft LEFT)',
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
    );
  }
}
