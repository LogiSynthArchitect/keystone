import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/icon_helpers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../domain/entities/job_template_entity.dart';
import '../providers/job_template_provider.dart';

class TemplatePickerSheet extends ConsumerWidget {
  const TemplatePickerSheet({super.key});

  /// Show the template picker bottom sheet. Returns the selected [JobTemplateEntity]
  /// or null if dismissed without selection.
  static Future<JobTemplateEntity?> show(BuildContext context) {
    return showModalBottomSheet<JobTemplateEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TemplatePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider).valueOrNull?.id;
    if (userId != null) {
      ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
    }
    final templatesAsync = ref.watch(jobTemplateProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: context.ksc.neutral600,
              borderRadius: BorderRadius.circular(2),
            )),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'SELECT TEMPLATE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: context.ksc.accent500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 18),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF163060), height: 1),
          const SizedBox(height: 8),
          // Template grid
          Expanded(
            child: templatesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.ksc.accent500, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text('FAILED TO LOAD', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: context.ksc.neutral500,
                )),
              ),
              data: (templates) {
                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LineAwesomeIcons.clipboard_list_solid, color: context.ksc.neutral600, size: 32),
                        const SizedBox(height: 12),
                        Text('NO TEMPLATES', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: context.ksc.neutral500,
                        )),
                        const SizedBox(height: 4),
                        Text('Save a job as template first', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: context.ksc.neutral600,
                        )),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (_, i) => _TemplateCard(template: templates[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final JobTemplateEntity template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final serviceCount = template.services.length;
    final hwCount = template.hardwareItems.length;
    final partCount = template.parts.length;
    final countParts = [if (serviceCount > 0) '$serviceCount svc', if (hwCount > 0) '$hwCount hw', if (partCount > 0) '$partCount parts'].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.pop(context, template),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.ksc.primary900,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: context.ksc.accent500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                getLineAwesomeIcon(template.name),
                color: context.ksc.accent500, size: 14,
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              template.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: context.ksc.white,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Category
            Text(
              template.serviceType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w600, color: context.ksc.neutral500,
              ),
            ),
            const Spacer(),
            // Counts
            Text(
              countParts,
              style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700, color: context.ksc.accent500,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
