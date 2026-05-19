import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import 'ks_logo.dart';

class PrivacyOverlay extends StatefulWidget {
  final Widget child;
  const PrivacyOverlay({super.key, required this.child});

  @override
  State<PrivacyOverlay> createState() => _PrivacyOverlayState();
}

class _PrivacyOverlayState extends State<PrivacyOverlay> with WidgetsBindingObserver {
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isOverlayVisible = state == AppLifecycleState.inactive || state == AppLifecycleState.paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOverlayVisible)
          Container(
            color: context.ksc.primary900,
            child: Center(
              child: KsLogo(size: 120, primaryColor: context.ksc.neutral500),
            ),
          ),
      ],
    );
  }
}
