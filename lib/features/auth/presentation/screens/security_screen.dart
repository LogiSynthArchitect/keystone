import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

// ─── Security Tab ──────────────────────────────────────────────
class _SecurityTab extends StatelessWidget {
  final VoidCallback onChangePassword;
  const _SecurityTab({required this.onChangePassword});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Password'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: onChangePassword,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Quick Unlock'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.fingerprint,
          title: 'Biometric Unlock',
          subtitle: 'Fingerprint or Face ID to unlock app',
          trailing: Switch(value: false, onChanged: (_) {}),
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.pin_outlined,
          title: 'Change PIN',
          subtitle: 'Update your 6-digit unlock PIN',
          onTap: () {},
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

// ─── Account Tab ───────────────────────────────────────────────
class _AccountTab extends ConsumerWidget {
  final VoidCallback onChangePhone;
  const _AccountTab({required this.onChangePhone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Account Info'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.phone,
          title: 'Phone Number',
          subtitle: '+233 20 147 0790',
          onTap: onChangePhone,
        ),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.calendar_today,
          title: 'Account Created',
          subtitle: 'Fetching...',
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Data'),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.download,
          title: 'Export My Data',
          subtitle: 'Download all your data as JSON',
          onTap: () {},
        ),
      ],
    );
  }
}

// ─── Sessions Tab ──────────────────────────────────────────────
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
                    Text('Infinix X6532 • Last active: now',
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
                // supabase.auth.signOut(scope: SignOutScope.others)
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

// ─── Shared Widgets ────────────────────────────────────────────
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
