import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';
import '../providers/auth_notifier.dart';

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  String _currentPwd = '';
  String _newPwd = '';
  String _confirmPwd = '';
  String? _step2Error;
  bool _isLoading = false;
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _step == 1 ? 'Enter your current password' : 'Enter a new password',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (_step == 1) _buildStep1(),
          if (_step == 2) _buildStep2(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        FocusSafeTextField(
          obscureText: true,
          onChanged: (v) => _currentPwd = v,
          label: 'Current password',
          validator: (v) => v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (_currentPwd.isEmpty) return;
              setState(() => _step = 2);
            },
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        FocusSafeTextField(
          obscureText: true,
          onChanged: (v) => _newPwd = v,
          label: 'New password',
          validator: (v) {
            if (v.isEmpty) return 'Required';
            if (v.length < 8) return 'At least 8 characters';
            if (!v.contains(RegExp(r'[A-Za-z]'))) return 'Must contain a letter';
            if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
            return null;
          },
        ),
        const SizedBox(height: 12),
        FocusSafeTextField(
          obscureText: true,
          onChanged: (v) => _confirmPwd = v,
          label: 'Confirm new password',
          validator: (v) {
            if (v != _newPwd) return 'Passwords do not match';
            return null;
          },
        ),
        if (_step2Error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _step2Error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _changePassword,
            child: _isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Password'),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_newPwd.isEmpty || _confirmPwd.isEmpty) return;
    if (_newPwd != _confirmPwd) {
      setState(() => _step2Error = 'Passwords do not match');
      return;
    }
    if (_newPwd.length < 8) {
      setState(() => _step2Error = 'At least 8 characters');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authNotifierProvider.notifier)
          .changePassword(_currentPwd, _newPwd);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      } else {
        setState(() => _step2Error = 'Current password is incorrect');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step2Error = '$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
