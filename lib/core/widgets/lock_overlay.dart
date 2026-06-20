import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/lock_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../router/route_names.dart';
import '../services/internal_auth/internal_auth_service.dart';
import '../services/internal_auth/secure_vault_service.dart';

import '../services/internal_auth/models/unlock_result.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import 'ks_logo.dart';
import 'ks_numpad.dart';

/// Full-screen lock overlay triggered by inactivity.
///
/// Sits in a [Stack] above all other content. Shows a custom PIN numpad when
/// PIN is the enrolled method, or device-auth / password buttons otherwise.
class LockOverlay extends ConsumerStatefulWidget {
  const LockOverlay({super.key});

  @override
  ConsumerState<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends ConsumerState<LockOverlay>
    with WidgetsBindingObserver {
  bool _hasBiometric = false;
  bool _hasPin = false;
  bool _showPinEntry = false;
  KsNumpadControls? _controls;
  int _remainingAttempts = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCredentials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final vault = SecureVaultService();
    final hasBio = await vault.getHasBiometric();
    final pinHash = await vault.getPinHash();
    final remaining = await vault.getPinFailedAttempts();
    if (mounted) {
      setState(() {
        _hasBiometric = hasBio;
        _hasPin = pinHash != null && pinHash.isNotEmpty;
        _remainingAttempts = 5 - remaining;
      });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _onDeviceUnlock() async {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final matched = await service.unlockWithDeviceAuth();
    if (matched && mounted) {
      HapticFeedback.heavyImpact();
      ref.read(lockProvider.notifier).hide(isUnlocked: true);
    }
  }

  Future<void> _onSignOut() async {
    // Sign out first (clears data, invalidates router), then hide overlay.
    // This prevents flash of dashboard content.
    await ref.read(authStateProvider.notifier).signOut();
    if (mounted) ref.read(lockProvider.notifier).hide(isUnlocked: false);
  }

  void _onUsePassword() {
    // Get phone from current session so password entry knows who's signing in
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    final phone = session?.user.phone ?? '';
    if (phone.isNotEmpty) {
      ref.read(authNotifierProvider.notifier).setPhoneNumber(phone);
    }
    // Navigate first while overlay is still visible, then hide overlay.
    // This prevents a flash of the dashboard content between hide and navigate.
    context.go(RouteNames.passwordEntry);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(lockProvider.notifier).hide(isUnlocked: false);
    });
  }

  void _onShowPinEntry() {
    setState(() => _showPinEntry = true);
  }

  Future<void> _onPinEntered(String code) async {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final result = await service.unlockWithPin(code);

    if (!mounted) return;

    if (result is UnlockSuccess) {
      HapticFeedback.heavyImpact();
      ref.read(lockProvider.notifier).hide(isUnlocked: true);
    } else if (result is UnlockLocked) {
      setState(() => _remainingAttempts--);
      _controls?.shakeAndClear();
    } else {
      // Wiped — redirect to password
      ref.read(lockProvider.notifier).hide(isUnlocked: false);
      if (mounted) context.go(RouteNames.passwordEntry);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(lockProvider);
    if (!isLocked) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: PopScope(
        canPop: false,
        child: Container(
          color: context.ksc.primary900,
          child: SafeArea(
            child: _showPinEntry ? _buildPinPage() : _buildLockPage(),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
      begin: const Offset(1.02, 1.02),
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
    );
  }

  Widget _buildPinPage() {
    final wiped = _remainingAttempts <= 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: KsNumpad(
          onReady: (c) => _controls = c,
          title: 'ENTER PIN',
          subtitle: wiped
              ? 'PIN has been wiped. Use your password.'
              : _remainingAttempts <= 3 && _remainingAttempts > 0
                  ? '$_remainingAttempts attempt(s) remaining'
                  : null,
          onCompleted: _onPinEntered,
        ),
      ),
    );
  }

  Widget _buildLockPage() {
    return Center(
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
              'Verify your identity to continue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.neutral400,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 48),
            if (_hasBiometric) ...[
              _ActionButton(
                label: 'UNLOCK WITH DEVICE',
                icon: LineAwesomeIcons.fingerprint_solid,
                onTap: _onDeviceUnlock,
              ),
              const SizedBox(height: 16),
            ],
            if (_hasPin) ...[
              _ActionButton(
                label: 'UNLOCK WITH PIN',
                icon: LineAwesomeIcons.lock_solid,
                onTap: _onShowPinEntry,
              ),
              const SizedBox(height: 16),
            ],
            _ActionButton(
              label: 'USE PASSWORD',
              icon: LineAwesomeIcons.key_solid,
              onTap: _onUsePassword,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _onSignOut,
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
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.ksc.accent500,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: context.ksc.primary900),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: context.ksc.primary900,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}