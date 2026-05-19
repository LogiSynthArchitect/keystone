import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class BiometricEnrollSheet extends ConsumerWidget {
  const BiometricEnrollSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);

    Future<void> enrollPin(BuildContext context, WidgetRef ref) async {
      Navigator.of(context).pop();
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PinSetupDialog(),
      );
      if (pin != null) {
        await service.enrollPin(pin);
        if (context.mounted) {
          await ref.read(authStateProvider.notifier).refresh();
          if (context.mounted) context.go(RouteNames.onboarding);
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SECURE YOUR ACCOUNT',
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              letterSpacing: 2.0, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FAST UNLOCK OPTIONS',
            style: AppTextStyles.h2.copyWith(
              color: context.ksc.white, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Skip waiting for SMS every time. Set up a quick unlock method.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.ksc.neutral400, fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _OptionTile(
            icon: LineAwesomeIcons.fingerprint_solid,
            title: 'FINGERPRINT / FACE UNLOCK',
            subtitle: 'Fastest — uses your device biometrics',
            onTap: () async {
              final success = await service.enrollBiometric();
              if (success && context.mounted) {
                Navigator.of(context).pop();
                await ref.read(authStateProvider.notifier).refresh();
                if (context.mounted) context.go(RouteNames.onboarding);
              } else if (context.mounted) {
                await enrollPin(context, ref);
              }
            },
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: LineAwesomeIcons.lock_solid,
            title: 'SET PIN CODE',
            subtitle: '6-digit PIN — works offline, always available',
            onTap: () => enrollPin(context, ref),
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: LineAwesomeIcons.angle_right_solid,
            title: 'SKIP',
            subtitle: 'Password-only login (requires internet)',
            onTap: () {
              Navigator.of(context).pop();
              ref.read(authStateProvider.notifier).refresh().then((_) {
                if (context.mounted) context.go(RouteNames.onboarding);
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.ksc.accent500, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label.copyWith(
                      color: context.ksc.white, fontWeight: FontWeight.w800,
                    )),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral400,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BiometricEnrollPage extends StatelessWidget {
  const BiometricEnrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: const BiometricEnrollSheet(),
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
        style: AppTextStyles.bodyLarge.copyWith(
          color: context.ksc.white, fontSize: 24, letterSpacing: 8,
        ),
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
