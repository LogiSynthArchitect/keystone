import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _complete() {
    HiveService.settings.put('setup_complete', true);
    context.go(RouteNames.logJob);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: 'SETUP',
        showBack: true,
        actions: [
          TextButton(
            onPressed: () {
              HiveService.settings.put('setup_complete', true);
              context.go(RouteNames.jobs);
            },
            child: Text('SKIP', style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, letterSpacing: 1.0)),
          ),
        ],
      ),
      body: Column(
        children: [
          _StepIndicator(currentPage: _currentPage),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _StepView(
                  phase: '01',
                  title: 'YOUR PROFILE',
                  body: 'Make sure your profile name and contact are set up so customers can find you.',
                  icon: LineAwesomeIcons.user_circle_solid,
                  actionLabel: 'EDIT PROFILE',
                  onAction: () => context.push(RouteNames.editProfile),
                  onNext: _next,
                  nextLabel: 'CONTINUE',
                ),
                _StepView(
                  phase: '02',
                  title: 'SERVICE TYPES',
                  body: 'Configure the service types you offer. These appear on job cards and reports.',
                  icon: LineAwesomeIcons.tools_solid,
                  actionLabel: 'MANAGE SERVICES',
                  onAction: () => context.push(RouteNames.serviceTypes),
                  onNext: _next,
                  nextLabel: 'CONTINUE',
                ),
                _StepView(
                  phase: '03',
                  title: 'LOG YOUR FIRST JOB',
                  body: "You're all set. Head to the job logger and record your first job.",
                  icon: LineAwesomeIcons.briefcase_solid,
                  actionLabel: null,
                  onAction: null,
                  onNext: _complete,
                  nextLabel: 'LOG FIRST JOB',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentPage;
  const _StepIndicator({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: active ? context.ksc.accent500 : context.ksc.primary800,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  final String phase;
  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onNext;
  final String nextLabel;

  const _StepView({
    required this.phase,
    required this.title,
    required this.body,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.onNext,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'SETUP PHASE $phase',
            style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, letterSpacing: 2.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.h1.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 32, color: context.ksc.accent500),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(body, style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, height: 1.6)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel!, style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(width: 8),
                    Icon(LineAwesomeIcons.angle_right_solid, size: 16, color: context.ksc.accent500),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.ksc.primary800,
                border: Border(top: BorderSide(color: context.ksc.primary700)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(nextLabel, style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
                  Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.accent500, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
