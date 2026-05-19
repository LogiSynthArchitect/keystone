import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/job_template_provider.dart';
import '../../domain/entities/job_template_entity.dart';

class JobTemplatesScreen extends ConsumerStatefulWidget {
  final void Function(JobTemplateEntity template)? onSelectTemplate;
  const JobTemplatesScreen({super.key, this.onSelectTemplate});

  @override
  ConsumerState<JobTemplatesScreen> createState() => _JobTemplatesScreenState();
}

class _JobTemplatesScreenState extends ConsumerState<JobTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserProvider).valueOrNull?.id;
      if (userId != null) {
        ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
      }
    });
  }

  void _showSaveDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text('SAVE AS TEMPLATE', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: AppTextStyles.body.copyWith(color: context.ksc.white),
          decoration: InputDecoration(
            hintText: "Template name",
            hintStyle: TextStyle(color: context.ksc.neutral500),
            border: OutlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(onPressed: () {
            if (nameCtrl.text.trim().isNotEmpty) {
              Navigator.pop(ctx, nameCtrl.text.trim());
            }
          }, child: Text('SAVE', style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(jobTemplateProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "JOB TEMPLATES",
        showBack: true,
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: itemsAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LineAwesomeIcons.exclamation_triangle_solid, color: context.ksc.error500, size: 48),
              const SizedBox(height: 16),
              Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  final userId = ref.read(currentUserProvider).valueOrNull?.id;
                  if (userId != null) ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
                },
                child: Text("TAP TO RETRY", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
              ),
            ],
          ),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return const KsEmptyState(
              icon: LineAwesomeIcons.clipboard_list_solid,
              title: "NO TEMPLATES",
              subtitle: "Save a job as template to reuse later",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              final serviceCount = t.services.length;
              final partCount = t.parts.length;
              final hwCount = t.hardwareItems.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSelectTemplate != null
                        ? () => widget.onSelectTemplate!(t)
                        : null,
                    onLongPress: () {
                      KsConfirmDialog.show(
                        context,
                        title: "DELETE TEMPLATE",
                        message: "Remove \"${t.name}\"?",
                        confirmLabel: "DELETE",
                        cancelLabel: "CANCEL",
                        isDanger: true,
                        onConfirm: () => ref.read(jobTemplateProvider.notifier).deleteTemplate(t.id),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: context.ksc.accent500.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(LineAwesomeIcons.clipboard_list_solid, color: context.ksc.accent500, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name.toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  "${t.serviceType.replaceAll('_', ' ').toUpperCase()} · $serviceCount services · $partCount parts · $hwCount hardware",
                                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onSelectTemplate != null)
                            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral500, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSaveDialog,
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
    );
  }
}
