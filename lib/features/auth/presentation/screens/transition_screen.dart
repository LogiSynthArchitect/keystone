import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/ks_logo_animated.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';

class TransitionScreen extends ConsumerStatefulWidget {
  const TransitionScreen({super.key});

  @override
  ConsumerState<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends ConsumerState<TransitionScreen> {
  String _milestone = "SECURELY INITIALIZING VAULT...";
  double _progress = 0.1;

  @override
  void initState() {
    super.initState();
    _startCommissioning();
  }

  void _startCommissioning() async {
    // INCREASED DELAYS FOR TESTING
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() { _milestone = "SYNCING PROFESSIONAL PROFILE..."; _progress = 0.4; });
    
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() { _milestone = "OPTIMIZING FOR OFFLINE ACCESS..."; _progress = 0.8; });

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() { _milestone = "WORKSHOP READY."; _progress = 1.0; });
  }

  void _onComplete() {
    // Delay the exit after the logo finishes its pulse
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) context.go(RouteNames.jobs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).profile;
    final name = profile?.displayName.toUpperCase() ?? "LOCKSMITH";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: Column(
        children: [
          Expanded(
            flex: 62,
            child: Center(
              child: KsLogoAnimated(size: 220, onComplete: _onComplete),
            ),
          ),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.transparent,
            color: const Color(0xFFF9A825),
            minHeight: 2,
          ),
          Expanded(
            flex: 38,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1A237E),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "WELCOME,",
                    style: TextStyle(
                      fontFamily: 'BarlowSemiCondensed',
                      color: Color(0xFFF9A825),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'BarlowSemiCondensed',
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _milestone,
                        style: const TextStyle(
                          fontFamily: 'BarlowSemiCondensed',
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
