import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/auth_notifier.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  ConsumerState<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    final success = await service.enrollPassword(phone, _passwordController.text);
    if (success && mounted) {
      await authNotifier.setPasswordCreated();
      context.push(RouteNames.biometricEnroll);
    }
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
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: Icon(LineAwesomeIcons.angle_left_solid, size: 20, color: context.ksc.white),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'SECURE ACCESS',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'CREATE PASSWORD',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    Text(
                      'Create a strong password to secure your account.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 48),
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 24),
                    ],
                    _buildPasswordField(context),
                    const SizedBox(height: 16),
                    _buildConfirmField(context),
                    const SizedBox(height: 12),
                    _buildPasswordHint(context),
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
        style: AppTextStyles.bodyLarge.copyWith(
          color: context.ksc.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'Enter password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        onSubmitted: (_) => _confirmFocus.requestFocus(),
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
        style: AppTextStyles.bodyLarge.copyWith(
          color: context.ksc.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'Confirm password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPasswordHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintRow(context, 'Minimum 8 characters', _passwordController.text.length >= 8),
          const SizedBox(height: 4),
          _hintRow(context, 'At least 1 letter', _passwordController.text.contains(RegExp(r'[A-Za-z]'))),
          const SizedBox(height: 4),
          _hintRow(context, 'At least 1 number', _passwordController.text.contains(RegExp(r'[0-9]'))),
          if (_confirmError != null) ...[
            const SizedBox(height: 4),
            _hintRow(context, _confirmError!, false),
          ],
        ],
      ),
    );
  }

  Widget _hintRow(BuildContext context, String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? LineAwesomeIcons.check_circle_solid : LineAwesomeIcons.times_circle_solid,
          size: 14,
          color: valid ? context.ksc.success500 : context.ksc.neutral500,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: valid ? context.ksc.success500 : context.ksc.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(top: BorderSide(color: context.ksc.primary700)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSubmit && !isLoading ? _onSubmit : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONTINUE',
                style: AppTextStyles.h2.copyWith(
                  color: _canSubmit ? context.ksc.white : context.ksc.neutral600,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              if (isLoading)
                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.accent500))
              else
                Icon(
                  LineAwesomeIcons.angle_right_solid,
                  color: _canSubmit ? context.ksc.accent500 : context.ksc.neutral700,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
