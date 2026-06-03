import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart'
    show RouteNames;
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../providers/auth_notifier.dart';

/// Standalone T&C acceptance screen for existing users on app upgrade.
/// Uses scroll-to-accept pattern (no checkbox), matching HTML prototype.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _termsScrolledToBottom = false;
  bool _isLoading = true;
  String _termsContent = '';
  ScrollController? _termsScrollController;
  int get _termsVersion => RouteNames.currentTermsVersion;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  void _onTermsScroll() {
    final ctrl = _termsScrollController;
    if (ctrl == null || !ctrl.hasClients) return;
    final scrolled = ctrl.position.pixels >=
        ctrl.position.maxScrollExtent * 0.98;
    if (scrolled != _termsScrolledToBottom) {
      setState(() => _termsScrolledToBottom = scrolled);
    }
  }

  Future<void> _loadTerms() async {
    try {
      final content = await rootBundle.loadString('assets/legal/terms.md');
      if (mounted) setState(() => _termsContent = content);
    } catch (_) {
      if (mounted) setState(() => _termsContent = 'Terms & Conditions could not be loaded.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAccept() async {
    if (!_termsScrolledToBottom) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).updateTermsAcceptance(
        termsAcceptedAt: DateTime.now(),
        termsVersion: _termsVersion,
      );

      if (mounted) {
        await ref.read(authStateProvider.notifier).refresh();
        if (mounted) context.go(RouteNames.transition);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _termsScrollController?.removeListener(_onTermsScroll);
    _termsScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final errorMessage = authState.errorMessage;

    _termsScrollController ??= ScrollController()..addListener(_onTermsScroll);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const SizedBox(height: 48),

                    Text(
                      'UPDATED TERMS',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 24),
                    Text(
                      'Read and scroll to accept.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 28),

                    // Error banner
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 16),
                    ],

                    // Scrollable T&C — max-height 190px per HTML
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Markdown(
                                controller: _termsScrollController,
                                data: _termsContent,
                                styleSheet: MarkdownStyleSheet(
                                  h1: AppTextStyles.h3.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800),
                                  h2: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                  p: AppTextStyles.caption.copyWith(color: context.ksc.neutral300, fontSize: 11, height: 1.6),
                                  listBullet: AppTextStyles.caption.copyWith(color: context.ksc.neutral400),
                                  strong: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                      ).animate().fadeIn(delay: 200.ms),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Edge-to-edge CTA button
            KsButton(
              label: 'I ACCEPT',
              variant: KsButtonVariant.cta,
              edgeToEdge: true,
              isLoading: _isLoading,
              onPressed: _termsScrolledToBottom && !_isLoading ? _onAccept : null,
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
