import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../../core/services/internal_auth/models/auth_method.dart';
import '../../../../core/services/internal_auth/secure_vault_service.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show SignOutScope;
import 'change_password_sheet.dart';
import 'delete_account_screen.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Security'),
            Tab(text: 'Account'),
            Tab(text: 'Sessions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SecurityTab(onChangePassword: () => _showChangePassword(context)),
          _AccountTab(onChangePhone: () => _showChangePhone(context)),
          const _SessionsTab(),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangePasswordSheet(),
    );
  }

  void _showChangePhone(BuildContext context) {
    context.push('/profile/change-phone');
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECURITY TAB — fully wired
// ═══════════════════════════════════════════════════════════════════

class _SecurityTab extends ConsumerStatefulWidget {
  final VoidCallback onChangePassword;
  const _SecurityTab({required this.onChangePassword});

  @override
  ConsumerState<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<_SecurityTab> {
  bool _hasBiometric = false;
  bool _hasPin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMethod();
  }

  Future<void> _loadMethod() async {
    final vault = SecureVaultService();
    final hasBio = await vault.getHasBiometric();
    final pinHash = await vault.getPinHash();
    if (mounted) {
      setState(() {
        _hasBiometric = hasBio;
        _hasPin = pinHash != null && pinHash.isNotEmpty;
        _loading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool wantEnabled) async {
    if (wantEnabled) {
      // Enroll biometric
      final supabase = ref.read(supabaseClientProvider);
      final service = InternalAuthService(supabase);
      try {
        final enrolled = await service.enrollBiometric();
        if (mounted) {
          if (enrolled) {
            _loadMethod();
          } else {
            // User cancelled or biometric not available
            if (mounted) {
              // Only push to PIN setup if user has no PIN yet
              final vault = SecureVaultService();
              final pinHash = await vault.getPinHash();
              if (pinHash == null || pinHash.isEmpty) {
                if (mounted) context.push(RouteNames.pinSetup);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric enrollment failed. Your PIN is still active.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
              _loadMethod();
            }
          }
        }
      } on BiometricAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.userMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      // Disable biometric ONLY — preserve PIN
      final supabase = ref.read(supabaseClientProvider);
      final service = InternalAuthService(supabase);
      await service.clearBiometricOnly();
      if (mounted) _loadMethod();
    }
  }

  Future<void> _setupPin() async {
    final vault = SecureVaultService();
    final pinHash = await vault.getPinHash();

    if (pinHash != null && pinHash.isNotEmpty) {
      // PIN already exists — open PIN entry for verification
      if (mounted) context.push(RouteNames.pinEntry);
    } else {
      // No PIN — open setup
      if (mounted) context.push(RouteNames.pinSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Check actual credential existence, not just enrolled_method
    final hasBiometric = _hasBiometric;
    final hasPin = _hasPin;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Password'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: widget.onChangePassword,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Quick Unlock'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.fingerprint,
          title: 'Biometric Unlock',
          subtitle: _loading
              ? 'Loading...'
              : hasBiometric
                  ? 'Fingerprint or Face ID enabled'
                  : 'Not set up — tap to enable',
          trailing: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Switch(
                  value: hasBiometric,
                  onChanged: _toggleBiometric,
                ),
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.pin_outlined,
          title: 'PIN Unlock',
          subtitle: _loading
              ? 'Loading...'
              : hasPin
                  ? 'PIN is set up'
                  : 'Not set up — tap to create',
          onTap: _setupPin,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Danger Zone'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.error.withOpacity(0.05),
          ),
          child: _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete all data and sign out',
            iconColor: theme.colorScheme.error,
            titleColor: theme.colorScheme.error,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DeleteAccountScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACCOUNT TAB — Export My Data wired
// ═══════════════════════════════════════════════════════════════════

class _AccountTab extends ConsumerWidget {
  final VoidCallback onChangePhone;
  const _AccountTab({required this.onChangePhone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    final phone = currentUser?.phone ?? 'Unknown';
    final createdAt = currentUser?.createdAt != null
        ? () {
            final dt = DateTime.parse(currentUser!.createdAt!);
            return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          }()
        : 'Unknown';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Account Info'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.phone,
          title: 'Phone Number',
          subtitle: phone,
          onTap: onChangePhone,
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.calendar_today,
          title: 'Account Created',
          subtitle: createdAt,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Data'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.download,
          title: 'Export My Data',
          subtitle: 'Download all your data as JSON',
          onTap: () async {
            try {
              await DataExportService.exportAsJson();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SESSIONS TAB — Sign out others wired
// ═══════════════════════════════════════════════════════════════════

class _SessionsTab extends ConsumerWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Active Sessions'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Device',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text('Current session',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign out of other devices?'),
                  content: const Text('This will sign out all other sessions except this device.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirmed == true) {
                final supabase = ref.read(supabaseClientProvider);
                await supabase.auth.signOut(scope: SignOutScope.others);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out of all other devices')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out of all other devices'),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Shared Widgets
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: titleColor != null ? TextStyle(color: titleColor) : null),
        subtitle: Text(subtitle),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}
