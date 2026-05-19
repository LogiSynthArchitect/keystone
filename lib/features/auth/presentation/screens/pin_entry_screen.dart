import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> with SingleTickerProviderStateMixin {
  final _pin = <String>[];
  int _failedAttempts = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).chain(CurveTween(curve: Curves.easeInOut)).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() => _pin.add(digit));
    HapticFeedback.lightImpact();
    if (_pin.length == 6) _verifyPin();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _verifyPin() async {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final valid = await service.unlockWithPin(_pin.join());

    if (valid && mounted) {
      HapticFeedback.heavyImpact();
      await ref.read(authStateProvider.notifier).refresh();
      context.go(RouteNames.transition);
    } else {
      _failedAttempts++;
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() => _pin.clear());
      if (_failedAttempts >= 3 && mounted) {
        context.go(RouteNames.passwordEntry);
      }
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ENTER PIN',
                    style: AppTextStyles.h1.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 48),
                  _buildPinDots(context),
                  if (_failedAttempts > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${3 - _failedAttempts} attempts remaining',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.error500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => context.go(RouteNames.passwordEntry),
                    child: Text(
                      'USE PASSWORD INSTEAD',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
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
                ],
              ),
            ),
            _buildNumpad(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child ?? const SizedBox(),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? context.ksc.accent500 : context.ksc.neutral700,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildRow(context, ['1', '2', '3']),
          _buildRow(context, ['4', '5', '6']),
          _buildRow(context, ['7', '8', '9']),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _buildKey(context, '0'),
              GestureDetector(
                onTap: _onDelete,
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  child: Icon(LineAwesomeIcons.backspace_solid, color: context.ksc.neutral400, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKey(context, d)).toList(),
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    return GestureDetector(
      onTap: () => _onDigit(digit),
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Text(
          digit,
          style: AppTextStyles.h1.copyWith(
            color: context.ksc.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
