import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  int _step = 0;
  String _phoneNumber = '';
  bool _isLoading = false;
  bool _confirmed = false;

  static const _warnings = [
    'This will permanently delete ALL your data including customers, jobs, and notes.',
    'You will lose access to your account immediately and cannot undo this.',
    'Make sure you have exported any data you want to keep before proceeding.',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Delete Account', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            if (_step < 3) ..._buildWarningSteps(),
            if (_step == 3) _buildConfirmation(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWarningSteps() {
    return [
      Text(
        _warnings[_step],
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      if (_step == 2)
        CheckboxListTile(
          title: const Text('I understand and want to proceed'),
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _step < 2
              ? () => setState(() => _step++)
              : _confirmed
                  ? () => setState(() => _step++)
                  : null,
          child: Text(_step < 2 ? 'Continue' : 'Proceed'),
        ),
      ),
      if (_step > 0)
        TextButton(
          onPressed: () => setState(() => _step--),
          child: const Text('Back'),
        ),
    ];
  }

  Widget _buildConfirmation() {
    return Column(
      children: [
        FocusSafeTextField(
          onChanged: (v) => _phoneNumber = v,
          hint: '+233 20 147 0790',
          label: 'Enter your phone number to confirm',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _deleteAccount,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Permanently Delete My Account'),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final authId = supabase.auth.currentUser?.id;
      final userPhone = supabase.auth.currentUser?.phone ?? '';

      // Verify phone matches
      String normalize(String s) => s
          .trim()
          .replaceAll(RegExp(r'[\s\+\-\(\)]'), '')
          .toLowerCase();
      final normalizedUserPhone = normalize(userPhone);
      final normalizedEnteredPhone = normalize(_phoneNumber);
      if (normalizedUserPhone != normalizedEnteredPhone) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number does not match. Deletion cancelled.')),
          );
        }
        return;
      }

      // Call edge function to delete account
      final response = await supabase.functions.invoke('delete-account', body: {
        'user_id': authId,
      });
      final data = response.data as Map<String, dynamic>?;

      if (data?['success'] != true) {
        throw Exception(data?['error'] ?? 'Delete account failed');
      }

      await supabase.auth.signOut();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
