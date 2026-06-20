import 'package:flutter/material.dart';

/// No-op wrapper — privacy overlay was causing interference with keyboard input
/// on certain Android devices (Infinix/Transsion) where IME triggers
/// AppLifecycleState.inactive during typing.
class PrivacyOverlay extends StatelessWidget {
  final Widget child;
  const PrivacyOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
