import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/constants/app_enums.dart';
import '../providers/job_providers.dart';
import '../../domain/entities/correction_request_entity.dart';

import '../../../../core/providers/auth_provider.dart';

class AdminRequestsScreen extends ConsumerWidget {
  const AdminRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(adminRequestsProvider);

    return userAsync.when(
      loading: () => Scaffold(backgroundColor: context.ksc.primary900, body: const Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(backgroundColor: context.ksc.primary900, body: const Center(child: Text("AUTH ERROR"))),
      data: (user) {
        if (user == null || !user.isAdmin) {
          return Scaffold(backgroundColor: context.ksc.primary900, body: const Center(child: Text("UNAUTHORIZED")));
        }

        return Scaffold(
          backgroundColor: context.ksc.primary900,
          appBar: const KsAppBar(
            title: "PENDING CORRECTIONS",
            showBack: true,
          ),
          body: requestsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
            error: (err, _) => Center(child: Text("ERROR LOADING REQUESTS", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LineAwesomeIcons.check_circle, size: 64, color: context.ksc.primary800),
                      const SizedBox(height: 16),
                      Text("NO PENDING REQUESTS", style: AppTextStyles.h2.copyWith(color: context.ksc.neutral500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return _RequestCard(request: request);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final CorrectionRequestEntity request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "JOB ID: ${request.jobId.substring(0, 8).toUpperCase()}",
                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800),
              ),
              Text(
                DateFormatter.short(request.createdAt).toUpperCase(),
                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.reason,
            style: AppTextStyles.body.copyWith(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.ksc.error500),
                    foregroundColor: context.ksc.error500,
                  ),
                  onPressed: () => _showRejectDialog(context, ref),
                  child: Text("REJECT", style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: context.ksc.accent500),
                  onPressed: () => _showApproveDialog(context, ref),
                  child: Text("APPROVE", style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text("REJECT REQUEST", style: AppTextStyles.h2.copyWith(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 2,
          style: AppTextStyles.body.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Reason for rejection...",
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: context.ksc.primary900,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(
            onPressed: () async {
              await ref.read(adminRequestsActionProvider.notifier).reject(request.id, adminNotes: controller.text.trim());
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text("REJECT", style: AppTextStyles.label.copyWith(color: context.ksc.error500)),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, WidgetRef ref) {
    ServiceType selectedType = ServiceType.doorLockInstallation;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: context.ksc.primary800,
          title: Text("APPROVE & UPDATE", style: AppTextStyles.h2.copyWith(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ServiceType>(
                initialValue: selectedType,
                dropdownColor: context.ksc.primary800,
                decoration: const InputDecoration(labelText: "SERVICE TYPE"),
                items: ServiceType.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase(), style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text("JOB DATE", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                subtitle: Text(DateFormatter.short(selectedDate), style: const TextStyle(color: Colors.white)),
                trailing: Icon(LineAwesomeIcons.calendar, color: context.ksc.accent500),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
            TextButton(
              onPressed: () async {
                await ref.read(adminRequestsActionProvider.notifier).approve(
                  request.id,
                  request.jobId,
                  {
                    'service_type': selectedType.name,
                    'job_date': selectedDate.toIso8601String(),
                  }
                );
                if (context.mounted) Navigator.pop(ctx);
              },
              child: Text("APPROVE", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
            ),
          ],
        ),
      ),
    );
  }
}
