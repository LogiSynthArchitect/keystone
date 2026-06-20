import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:hive_flutter/hive_flutter.dart';
import '../config/dev_mode.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../router/app_router.dart';
import '../router/route_names.dart';
import '../services/internal_auth/secure_vault_service.dart';
import '../storage/hive_service.dart';
import '../../features/auth/presentation/providers/dev_auth_provider.dart';
import '../../features/auth/presentation/providers/dev_state_provider.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

/// Floating dev-mode auth toolbox — full bottom-sheet with tabs.
///
/// Visible only when `DEV_MODE=true`. Tap the amber pill to open.
/// Collapse to pill with the X button.
class DevAuthPanel extends ConsumerStatefulWidget {
  const DevAuthPanel({super.key});

  @override
  ConsumerState<DevAuthPanel> createState() => _DevAuthPanelState();
}

class _DevAuthPanelState extends ConsumerState<DevAuthPanel>
    with SingleTickerProviderStateMixin {
  bool _showPanel = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDevMode) return const SizedBox.shrink();

    return Stack(
      children: [
        if (_showPanel)
          GestureDetector(
            onTap: () => setState(() => _showPanel = false),
            child: Container(color: Colors.black26),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          right: 8,
          child: _showPanel ? _buildPill(true) : _buildPill(false),
        ),
        if (_showPanel) _buildSheet(),
      ],
    );
  }

  Widget _buildPill(bool expanded) {
    return GestureDetector(
      onTap: () => setState(() => _showPanel = !expanded),
      child: Container(
        height: 24,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expanded) const Icon(Icons.arrow_back_ios, size: 8, color: Colors.white),
            if (expanded) const SizedBox(width: 4),
            const Text(
              'DEV',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.2),
            ),
            if (!expanded) const SizedBox(width: 4),
            if (!expanded) const Icon(Icons.arrow_forward_ios, size: 8, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet() {
    final bottom = MediaQuery.of(context).padding.bottom + 8;
    return Positioned(
      left: 8,
      right: 8,
      bottom: bottom,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A2E),
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _StateTab(),
                    _FlowTab(),
                    _buildAuditTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: Colors.amber.shade300,
        unselectedLabelColor: Colors.white38,
        indicatorColor: Colors.amber.shade300,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'STATE'),
          Tab(text: 'FLOW'),
          Tab(text: 'AUDIT'),
        ],
      ),
    );
  }

  // ── Audit tab ──

  Widget _buildAuditTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Flow Consistency Check & Unused Dependencies',
            style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _auditBtn('Walk Auth Flow', _walkAuthFlow),
          const SizedBox(height: 6),
          _auditBtn('Check Unused Imports', _checkUnusedImports),
          const SizedBox(height: 12),
          const Text(
            'Tap each button to print results to debug console.',
            style: TextStyle(fontSize: 9, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _auditBtn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  void _walkAuthFlow() {
    debugPrint('===== DEV AUTH FLOW WALK =====');
    final routes = [
      'Splash → /',
      'Landing → ${RouteNames.phoneEntry}',
      'Phone → ${RouteNames.otpVerify}',
      'OTP → ${RouteNames.createPassword}',
      'Create PW → ${RouteNames.passwordEntry}',
      'PW Entry → ${RouteNames.pinEntry}',
      'PIN → ${RouteNames.biometricEnroll}',
      'Biometric → ${RouteNames.dashboard}',
    ];
    for (final step in routes) {
      debugPrint('  [ROUTE] $step');
    }
    debugPrint('  Current route not available via GoRouter API in this version');
    debugPrint('================================');
  }

  void _checkUnusedImports() {
    debugPrint('===== UNUSED IMPORT CHECK =====');
    debugPrint('  Run: flutter analyze | grep unused_import');
    debugPrint('  Or: dart analyze lib/ 2>&1 | grep unused');
    debugPrint('================================');
  }
}

// ── State Tab ──

class _StateTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dev = ref.watch(devAuthOverrideProvider);
    final realAuth = ref.watch(authStateProvider).valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoRow('Real session', realAuth?.session != null),
          _infoRow('Real profile', realAuth?.hasProfile == true),
          const SizedBox(height: 8),
          const Text('OVERRIDES', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 4),
          _toggle('Enabled', dev.enabled, (v) => ref.read(devAuthOverrideProvider.notifier).setEnabled(v)),
          if (dev.enabled) ...[
            _toggle('Simulate Authenticated', dev.simulateAuthenticated, (v) => ref.read(devAuthOverrideProvider.notifier).setSimulateAuthenticated(v)),
            _toggle('Has Profile', dev.hasProfile, (v) => ref.read(devAuthOverrideProvider.notifier).setHasProfile(v)),
            _toggle('Needs Password Upgrade', dev.needsPasswordUpgrade, (v) => ref.read(devAuthOverrideProvider.notifier).setNeedsPasswordUpgrade(v)),
            _toggle('Has Password', dev.hasPassword, (v) => ref.read(devAuthOverrideProvider.notifier).setHasPassword(v)),
            _toggle('Locally Unlocked', dev.isLocallyUnlocked, (v) => ref.read(devAuthOverrideProvider.notifier).setIsLocallyUnlocked(v)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: value ? Colors.green : Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const Spacer(),
          Text(value ? 'YES' : 'NO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: value ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
          const Spacer(),
          SizedBox(
            height: 22,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.amber,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flow Tab ──

class _FlowTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dev = ref.watch(devAuthOverrideProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('STEP COMPLETION', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 6),
          _stepBtn('Mark OTP Verified',
              dev.otpVerified, Icons.check_circle_outline,
              () {
            ref.read(devAuthOverrideProvider.notifier).markOtpVerified();
            ref.read(routerProvider).go(
              dev.hasPassword ? RouteNames.passwordEntry : RouteNames.createPassword,
            );
          }),
          _stepBtn('Mark Password Created',
              dev.passwordCreated, Icons.lock_outline,
              () {
            ref.read(devAuthOverrideProvider.notifier).markPasswordCreated();
            ref.read(routerProvider).go(RouteNames.pinEntry);
          }),
          _stepBtn('Mark PIN Created',
              dev.pinCreated, Icons.pin_outlined,
              () {
            ref.read(devAuthOverrideProvider.notifier).markPinCreated();
            ref.read(routerProvider).go(RouteNames.biometricEnroll);
          }),
          _stepBtn('Mark Biometric Enrolled',
              dev.biometricEnrolled, Icons.fingerprint,
              () {
            ref.read(devAuthOverrideProvider.notifier).markBiometricEnrolled();
            ref.read(routerProvider).go(RouteNames.termsAccept);
          }),
          _stepBtn('Mark Onboarding Done',
              dev.onboardingDone, Icons.person_outline,
              () {
            ref.read(devAuthOverrideProvider.notifier).markOnboardingDone();
            ref.read(routerProvider).go(RouteNames.initialSync);
          }),
          _stepBtn('Mark Initial Sync Done',
              dev.initialSyncDone, Icons.sync,
              () {
            ref.read(devAuthOverrideProvider.notifier).markInitialSyncDone();
            ref.read(routerProvider).go(RouteNames.dashboard);
          }),
          const SizedBox(height: 10),
          const Text('PRESETS', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 6),
          _presetBtn('Fully Authenticated', DevAuthOverride.authenticatedFull, ref),
          _presetBtn('OTP Done (no profile)', DevAuthOverride.otpDone, ref),
          _presetBtn('Needs Password Upgrade', DevAuthOverride.needsPasswordUpgradeState, ref),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade300,
                side: BorderSide(color: Colors.red.shade800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ref.read(devAuthOverrideProvider.notifier).reset();
                ref.read(authStateProvider.notifier).refresh();
                ref.read(routerProvider).go(RouteNames.landing);
              },
              child: const Text('Reset All Overrides', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _navBtn('Auto-fill Phone', () {
                  ref.read(devAutoFillPhoneProvider.notifier).state = '30823904';
                  ref.read(routerProvider).go(RouteNames.phoneEntry);
                }),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _navBtn('Skip to Home', () {
                  ref.read(devAuthOverrideProvider.notifier).applyPreset(DevAuthOverride.authenticatedFull);
                  ref.read(routerProvider).go(RouteNames.dashboard);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _navBtn('Reset & Restart', () => _resetAndRestart(ref), color: Colors.red.shade700),
        ],
      ),
    );
  }

  Widget _stepBtn(String label, bool done, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 34,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: done ? Colors.green.shade800 : const Color(0xFF2A2A3E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          icon: Icon(done ? Icons.check_circle : icon, size: 14),
          label: Text(label),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _presetBtn(String label, DevAuthOverride preset, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade900,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            ref.read(devAuthOverrideProvider.notifier).applyPreset(preset);
            ref.read(routerProvider).go(RouteNames.dashboard);
          },
          child: Text(label),
        ),
      ),
    );
  }

  Widget _navBtn(String label, VoidCallback onTap, {Color? color}) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.amber.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  Future<void> _resetAndRestart(WidgetRef ref) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final session = supabase.auth.currentSession;
      if (session?.user.id != null) {
        try {
          await supabase.functions.invoke('dev-reset', method: supa.HttpMethod.post);
        } catch (_) {}
      }
      final vault = SecureVaultService();
      await vault.clearAll();
      try { Hive.box('auth').delete(HiveService.lastOnlineSyncKey); } catch (_) {}
      try { await HiveService.clearAll(); } catch (_) {}
      try { await supabase.auth.signOut(); } catch (_) {}
      ref.invalidate(authStateProvider);
      ref.read(devAuthOverrideProvider.notifier).reset();
      ref.read(routerProvider).go(RouteNames.landing);
    } catch (e) {
      debugPrint('[KS:DEV] Reset failed: $e');
    }
  }
}
