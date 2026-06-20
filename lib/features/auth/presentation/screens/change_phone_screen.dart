import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';
import '../providers/auth_notifier.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  String _phoneNumber = '';
  String _otpCode = '';
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${ref.read(supabaseClientProvider).auth.currentUser?.phone ?? 'unknown'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FocusSafeTextField(
              onChanged: (v) => _phoneNumber = v,
              keyboardType: TextInputType.phone,
              hint: '020 000 0000',
              label: 'New phone number',
            ),
            const SizedBox(height: 20),
            if (!_otpSent)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send Verification Code'),
                ),
              ),
            if (_otpSent) ..._buildOtpSection(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOtpSection() {
    return [
      FocusSafeTextField(
        onChanged: (v) => _otpCode = v,
        keyboardType: TextInputType.number,
        hint: '000000',
        label: 'Verification code',
        maxLength: 6,
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verify & Update'),
        ),
      ),
    ];
  }

  Future<void> _sendOtp() async {
    final phone = _phoneNumber.trim();
    if (phone.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOtp(
        phone: phone,
      );
      setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send code: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneNumber.trim();
    final otp = _otpCode.trim();
    if (otp.length != 6) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).verifyOtpAndChangePhone(phone, otp);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
