import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/utils/date_formatter.dart';
import 'package:keystone/core/utils/currency_formatter.dart';
import 'package:keystone/core/widgets/ks_app_bar.dart';
import 'package:keystone/core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_badge.dart';
import 'package:keystone/core/widgets/sync_status_indicator.dart';
import 'package:keystone/core/widgets/ks_snackbar.dart';
import 'package:keystone/core/router/route_names.dart';
import 'package:keystone/core/providers/auth_provider.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_photo_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/customer_history/presentation/providers/customer_providers.dart';
import 'package:keystone/features/knowledge_base/presentation/providers/notes_providers.dart';
import 'package:keystone/features/note_links/presentation/providers/note_link_provider.dart';
import '../widgets/follow_up_button.dart';
import '../widgets/follow_up_message_preview.dart';
import '../../../../core/providers/permissions_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final permissions = ref.watch(permissionsProvider);
    final isAdmin = ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "JOB RECORD",
        showBack: true,
        actions: [
          jobAsync.when(
            data: (job) => job == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(LineAwesomeIcons.edit, color: context.ksc.accent500, size: 22),
                    onPressed: () => context.push(RouteNames.editJob(jobId)),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (permissions.canDeleteJobs || isAdmin)
            IconButton(
              icon: Icon(LineAwesomeIcons.archive_solid, color: context.ksc.neutral400, size: 22),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: ctx.ksc.primary800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    title: Text("ARCHIVE RECORD?", style: AppTextStyles.h2.copyWith(color: ctx.ksc.white)),
                    content: Text("This job will be moved to history. It cannot be permanently deleted.", style: AppTextStyles.body.copyWith(color: ctx.ksc.neutral400)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: ctx.ksc.neutral400))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("ARCHIVE", style: AppTextStyles.label.copyWith(color: ctx.ksc.error500))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(jobListProvider.notifier).archive(jobId);
                  if (!context.mounted) return;
                  final error = ref.read(jobListProvider).errorMessage;
                  if (error != null && error.isNotEmpty) {
                    KsSnackbar.show(context, message: error, type: KsSnackbarType.error);
                  } else {
                    Navigator.pop(context);
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: jobAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
              error: (err, _) => Center(child: Text("COULD NOT LOAD JOB", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
              data: (job) {
                if (job == null) return Center(child: Text("JOB RECORD NOT FOUND", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, job),
                      const SizedBox(height: 24),
                      
                      _buildStatusRow(context, ref, job),
                      const SizedBox(height: 32),

                      _buildSectionHeader(context, "FINANCIALS"),
                      _buildFinancialsModule(context, ref, job),
                      const SizedBox(height: 32),

                      _buildSectionHeader(context, "CUSTOMER"),
                      _buildCustomerModule(context, ref, job.customerId),
                      const SizedBox(height: 32),

                      if (job.hardwareBrand != null || job.hardwareKeyway != null) ...[
                        _buildSectionHeader(context, "HARDWARE"),
                        _buildHardwareModule(context, job),
                        const SizedBox(height: 32),
                      ],

                      _buildPartsSection(context, ref, job),
                      const SizedBox(height: 32),

                      _buildPhotosSection(context, ref, job),
                      const SizedBox(height: 32),

                      if (job.notes != null && job.notes!.isNotEmpty) ...[
                        _buildSectionHeader(context, "NOTES"),
                        _buildNotesModule(context, job.notes!),
                        const SizedBox(height: 32),
                      ],

                      _buildSectionHeader(context, "COMMUNICATION STATUS"),
                      FollowUpMessagePreview(job: job),
                      const SizedBox(height: 32),

                      _buildSectionHeader(context, "LINKED NOTES"),
                      _LinkedNotesList(jobId: job.id),
                      const SizedBox(height: 32),

                      _buildAuditLogSection(context, ref, job),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: jobAsync.when(
        data: (job) => job != null ? FollowUpButton(job: job) : const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JobEntity job) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.h1.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.display(job.jobDate).toUpperCase(),
                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        SyncStatusIndicator(status: job.syncStatus, size: 24),
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, WidgetRef ref, JobEntity job) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showStatusSheet(context, ref, job),
          child: _statusBadge(job.status),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showPaymentSheet(context, ref, job),
          child: _paymentBadge(job.paymentStatus),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    String label = status.replaceAll('_', ' ').toUpperCase();
    KsBadgeVariant variant = KsBadgeVariant.neutral;
    if (status == 'completed' || status == 'invoiced') variant = KsBadgeVariant.success;
    if (status == 'quoted') variant = KsBadgeVariant.info;
    return KsBadge(label: label, variant: variant, icon: LineAwesomeIcons.info_circle_solid);
  }

  Widget _paymentBadge(String status) {
    String label = status.toUpperCase();
    KsBadgeVariant variant = KsBadgeVariant.error;
    if (status == 'paid') variant = KsBadgeVariant.success;
    if (status == 'partial') variant = KsBadgeVariant.warning;
    return KsBadge(label: label, variant: variant, icon: LineAwesomeIcons.wallet_solid);
  }

  Widget _buildFinancialsModule(BuildContext context, WidgetRef ref, JobEntity job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        children: [
          if (job.quotedPrice != null) ...[
            _financialRow(context, "QUOTED", CurrencyFormatter.format((job.quotedPrice! * 100).round()), isDimmed: true),
            const SizedBox(height: 12),
            Divider(color: context.ksc.primary700, height: 1),
            const SizedBox(height: 12),
          ],
          _financialRow(context, "FINAL CHARGE", job.hasAmount ? CurrencyFormatter.formatShort(job.amountCharged!) : "GHS 0.00", isBold: true),
          if (job.paymentMethod != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "VIA ${job.paymentMethod!.replaceAll('_', ' ').toUpperCase()}",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _financialRow(BuildContext context, String label, String value, {bool isBold = false, bool isDimmed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: isDimmed ? context.ksc.neutral600 : context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        Text(
          value,
          style: isBold 
            ? AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)
            : AppTextStyles.body.copyWith(color: isDimmed ? context.ksc.neutral500 : context.ksc.white, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildCustomerModule(BuildContext context, WidgetRef ref, String customerId) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    return customerAsync.when(
      loading: () => Container(height: 80, color: context.ksc.primary800).animate().shimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (customer) => GestureDetector(
        onTap: () => context.push(RouteNames.customerDetail(customerId)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.ksc.primary900,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Center(
                  child: Text(
                    customer?.fullName[0].toUpperCase() ?? "?",
                    style: AppTextStyles.h2.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer?.fullName.toUpperCase() ?? "UNKNOWN CUSTOMER", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(customer?.phoneNumber ?? "NO CONTACT", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.primary700, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareModule(BuildContext context, JobEntity job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        children: [
          if (job.hardwareBrand != null)
            _financialRow(context, "BRAND", job.hardwareBrand!.toUpperCase()),
          if (job.hardwareBrand != null && job.hardwareKeyway != null)
            const SizedBox(height: 12),
          if (job.hardwareKeyway != null)
            _financialRow(context, "KEYWAY", job.hardwareKeyway!.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildPartsSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final partsAsync = ref.watch(jobPartsProvider(jobId));
    return partsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (parts) {
        final revenue   = job.amountCharged ?? 0;
        final totalCost = parts.fold<int>(0, (sum, p) => sum + p.totalCost);
        final profit    = revenue - totalCost;

        // Hide if there's nothing to show
        if (revenue == 0 && parts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "PARTS & PROFIT"),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: Column(
                children: [
                  if (parts.isNotEmpty) ...[
                    ...parts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${p.quantity}x ${p.partName.toUpperCase()}", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600)),
                          Text(CurrencyFormatter.formatShort(p.totalCost), style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                    Divider(color: context.ksc.primary700, height: 1),
                    const SizedBox(height: 12),
                  ],
                  _financialRow(context, "REVENUE", CurrencyFormatter.formatShort(revenue)),
                  const SizedBox(height: 8),
                  _financialRow(context, "PARTS COST", CurrencyFormatter.formatShort(totalCost)),
                  const SizedBox(height: 8),
                  Divider(color: context.ksc.primary700, height: 1),
                  const SizedBox(height: 8),
                  _financialRow(context, "GROSS PROFIT", CurrencyFormatter.formatShort(profit.round()), isBold: true),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotosSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final photosAsync = ref.watch(jobPhotosProvider(jobId));
    return photosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (photos) {
        if (photos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "PHOTOS"),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5
              ),
              itemCount: photos.length,
              itemBuilder: (ctx, i) => _buildPhotoCard(context, photos[i]),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPhotoCard(BuildContext context, JobPhotoEntity photo) {
    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
        image: DecorationImage(image: NetworkImage(photo.storagePath), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          if (photo.label != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black54,
                child: Text(
                  photo.label!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuditLogSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final auditAsync = ref.watch(jobAuditLogProvider(jobId));
    return auditAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (logs) {
        if (logs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "EDIT HISTORY"),
            ...logs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: context.ksc.accent500, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${log.action.toUpperCase()} · ${DateFormatter.short(log.createdAt).toUpperCase()}",
                          style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                        if (log.newValues != null)
                          Text(
                            log.newValues!.entries.map((e) => "${e.key}: ${e.value}").join(", "),
                            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        );
      }
    );
  }

  Widget _buildNotesModule(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
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
            children: [
              Icon(LineAwesomeIcons.sticky_note_solid, size: 14, color: context.ksc.accent500),
              const SizedBox(width: 8),
              Text("NOTES", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes,
            style: AppTextStyles.body.copyWith(color: context.ksc.neutral200, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, JobEntity job) {
    final options = [
      ('quoted', 'QUOTED'),
      ('in_progress', 'IN PROGRESS'),
      ('completed', 'COMPLETED'),
      ('invoiced', 'INVOICED'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ksc.primary800,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(opt.$2, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () async {
              final user = await ref.read(currentUserProvider.future);
              if (user != null) {
                await ref.read(jobRepositoryProvider).updateJobStatus(job.id, opt.$1, user.id);
                ref.invalidate(jobDetailProvider(job.id));
                if (context.mounted) Navigator.pop(ctx);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref, JobEntity job) {
    final options = [('unpaid', 'UNPAID'), ('partial', 'PARTIAL'), ('paid', 'PAID')];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ksc.primary800,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(opt.$2, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () async {
              final user = await ref.read(currentUserProvider.future);
              if (user != null) {
                await ref.read(jobRepositoryProvider).updatePaymentStatus(job.id, opt.$1, null, user.id);
                ref.invalidate(jobDetailProvider(job.id));
                if (context.mounted) Navigator.pop(ctx);
              }
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _LinkedNotesList extends ConsumerWidget {
  final String jobId;
  const _LinkedNotesList({required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(noteLinkByJobProvider(jobId));
    final noteState  = ref.watch(notesListProvider);

    return linksAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: context.ksc.accent500, strokeWidth: 2)),
      ),
      error: (_, __) => Text("Could not load linked notes.", style: AppTextStyles.caption.copyWith(color: context.ksc.error500)),
      data: (links) {
        if (links.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.ksc.primary700),
            ),
            child: Text(
              "No notes linked to this job.",
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: links.map((link) {
            final note = noteState.notes.where((n) => n.id == link.noteId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Row(
                  children: [
                    Icon(LineAwesomeIcons.sticky_note, size: 14, color: context.ksc.accent500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note != null ? note.title.toUpperCase() : 'NOTE #${link.noteId.substring(0, 8)}',
                            style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (note != null && note.hasTags) ...[
                            const SizedBox(height: 2),
                            Text(
                              note.tags.map((t) => '#$t').join(' '),
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
