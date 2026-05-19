import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/models/auth_method.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/auth_notifier.dart';

class PasswordEntryScreen extends ConsumerStatefulWidget {
  const PasswordEntryScreen({super.key});

  @override
  ConsumerState<PasswordEntryScreen> createState() => _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends ConsumerState<PasswordEntryScreen> {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _passwordController.text.length >= 8;

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    final session = await service.verifyPassword(phone, _passwordController.text);
    if (session != null && mounted) {
      await ref.read(authStateProvider.notifier).refresh();
      if (!mounted) return;
      final method = await service.getEnrolledMethod();
      if (method == AuthMethod.none) {
        await _promptFastUnlock(service);
        if (!mounted) return;
        await ref.read(authStateProvider.notifier).refresh();
      }
      if (mounted) context.go(RouteNames.transition);
    } else if (mounted) {
      authNotifier.setError('Invalid password. Please try again.');
    }
  }

  Future<void> _promptFastUnlock(InternalAuthService service) async {
    final shouldEnroll = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: context.ksc.primary700),
        ),
        title: Text('FAST UNLOCK', style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
        content: Text(
          'Set up fingerprint or PIN for faster logins on this device?',
          style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('SKIP', style: TextStyle(color: context.ksc.neutral500, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.ksc.accent500),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('SET UP', style: TextStyle(color: context.ksc.primary900, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (shouldEnroll != true || !mounted) return;

    final enrolled = await service.enrollBiometric();
    if (enrolled || !mounted) return;

    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinSetupDialog(),
    );
    if (pin != null) {
      await service.enrollPin(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';
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
                      'ENTER PASSWORD',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    Text(
                      'Sign in for $phone.',
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
                    _buildForgotLink(context),
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
          color: _isFocused ? context.ksc.accent500 : context.ksc.primary700,
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _focusNode,
        onChanged: (_) => setState(() {}),
        obscureText: _obscure,
        style: AppTextStyles.bodyLarge.copyWith(
          color: context.ksc.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        onSubmitted: (_) => _onSubmit(),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildForgotLink(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => context.push(RouteNames.forgotAccess),
            child: Text(
              'FORGOT ACCESS?',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.accent500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => context.go(RouteNames.phoneEntry),
            child: Text(
              'NOT YOU? SIGN IN AS DIFFERENT USER',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
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
                'SIGN IN',
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

class _PinSetupDialog extends StatefulWidget {
  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  int _step = 0;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.ksc.primary900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.ksc.primary700),
      ),
      title: Text(
        _step == 0 ? 'SET YOUR PIN' : 'CONFIRM PIN',
        style: AppTextStyles.h2.copyWith(color: context.ksc.white),
      ),
      content: TextField(
        controller: _step == 0 ? _pinController : _confirmController,
        maxLength: 6,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        obscureText: true,
        style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontSize: 24, letterSpacing: 8),
        decoration: InputDecoration(
          hintText: '• • • • • •',
          hintStyle: TextStyle(color: context.ksc.neutral600, letterSpacing: 8),
          counterText: '',
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.ksc.accent500)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: context.ksc.neutral400)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: context.ksc.accent500),
          onPressed: () {
            if (_step == 0) {
              if (_pinController.text.length == 6) setState(() => _step = 1);
            } else {
              if (_confirmController.text == _pinController.text) {
                Navigator.of(context).pop(_pinController.text);
              }
            }
          },
          child: Text('NEXT', style: TextStyle(color: context.ksc.primary900, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
