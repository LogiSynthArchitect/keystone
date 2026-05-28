import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:printing/printing.dart';
import 'package:keystone/core/services/invoice_pdf_generator.dart';
import 'package:keystone/core/services/receipt_pdf_generator.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/utils/date_formatter.dart';
import 'package:keystone/core/utils/currency_formatter.dart';
import 'package:keystone/core/widgets/ks_app_bar.dart';
import 'package:keystone/core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_badge.dart';
import 'package:keystone/core/widgets/ks_confirm_dialog.dart';
import 'package:keystone/core/widgets/ks_bottom_sheet_scaffold.dart';
import 'package:keystone/core/widgets/sync_status_indicator.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import 'package:keystone/core/router/route_names.dart';
import 'package:keystone/core/providers/auth_provider.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_photo_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_part_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_hardware_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_expense_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/job_logging/presentation/screens/edit_job_screen.dart';
import 'package:keystone/features/customer_history/presentation/providers/customer_providers.dart';
import 'package:keystone/features/knowledge_base/presentation/providers/notes_providers.dart';
import 'package:keystone/features/note_links/presentation/providers/note_link_provider.dart';
import 'package:keystone/features/whatsapp_followup/presentation/widgets/follow_up_button.dart';
import 'package:keystone/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart';
import 'package:keystone/core/providers/permissions_provider.dart';
import 'package:keystone/core/utils/whatsapp_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tracks customer IDs that have been warned about WhatsApp registration.
/// Prevents showing the info toast more than once per customer per session.
final Set<String> _warnedWhatsAppCustomers = {};

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
                    onPressed: () => EditJobScreen.show(context, jobId),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (permissions.canDeleteJobs || isAdmin)
            IconButton(
              icon: Icon(LineAwesomeIcons.archive_solid, color: context.ksc.neutral400, size: 22),
              onPressed: () async {
                final confirmed = await KsConfirmDialog.show(
                  context,
                  title: 'ARCHIVE RECORD',
                  message: 'This job will be moved to history. It cannot be permanently deleted.',
                  confirmLabel: 'ARCHIVE',
                  cancelLabel: 'CANCEL',
                  isDanger: true,
                  onConfirm: () {},
                );
                if (confirmed == true) {
                  try {
                    await ref.read(jobListProvider.notifier).archive(jobId);
                    if (!context.mounted) return;
                    final error = ref.read(jobListProvider).errorMessage;
                    if (error != null && error.isNotEmpty) {
                      KsSlidingNotification.show(context, message: error, type: KsNotificationType.error);
                    } else {
                      Navigator.pop(context);
                    }
                  } catch (_) {
                    if (context.mounted) {
                      KsSlidingNotification.show(context, message: "Could not archive job", type: KsNotificationType.error);
                    }
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
                      const SizedBox(height: 24),
                      _buildMetaRow(context, job),
                      const SizedBox(height: 16),

                      // ✅ 1. Summary strip — instant overview
                      _SummaryStrip(jobId: job.id, notes: job.notes),
                      const SizedBox(height: 24),

                      // ✅ 2. Financials with gross profit
                      _buildSectionHeader(context, "FINANCIALS"),
                      _buildFinancialsModule(context, ref, job),
                      const SizedBox(height: 12),
                      _buildInvoiceShareButton(context, ref, job),
                      if (job.isPaid) ...[
                        const SizedBox(height: 12),
                        _buildReceiptButton(context, ref, job),
                      ],
                      const SizedBox(height: 32),

                      _buildSectionHeader(context, "CUSTOMER"),
                      // ✅ 4. Customer card + quick actions
                      _buildCustomerModule(context, ref, job.customerId, job),
                      const SizedBox(height: 32),

                      _buildServicesSection(context, ref, job),
                      const SizedBox(height: 32),

                      // ✅ 3. Unified Items Used (parts + hardware merged)
                      _buildItemsUsedSection(context, ref, job),
                      const SizedBox(height: 32),

                      _buildExpensesSection(context, ref, job),
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
                      const SizedBox(height: 240),
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
        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JobEntity job) {
    final accentColor = _statusColor(job.status);
    final serviceIcon = _inferIcon(job.serviceType);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service icon box — consistent with JobCard
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(serviceIcon, size: 20, color: accentColor),
        ),
        const SizedBox(width: 14),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'quoted':       return const Color(0xFFC8A84E);
      case 'in_progress':  return const Color(0xFF6BB5FF);
      case 'completed':    return const Color(0xFF4CAF50);
      case 'invoiced':     return const Color(0xFFB388FF);
      default:             return const Color(0xFF4A5A6A);
    }
  }

  /// Map service type slug to an appropriate icon (mirrors JobCard._inferIcon).
  IconData _inferIcon(String type) {
    switch (type) {
      case 'cctv_installation':
      case 'cctv':
        return LineAwesomeIcons.video_solid;
      case 'electric_fence_installation':
      case 'electric_fence':
        return LineAwesomeIcons.bolt_solid;
      case 'intercom_systems':
      case 'intercom':
        return LineAwesomeIcons.phone_volume_solid;
      case 'eviction_services':
      case 'eviction':
        return LineAwesomeIcons.shield_alt_solid;
      case 'ignition_repair':
      case 'ignition':
        return LineAwesomeIcons.car_solid;
      case 'burglar_alarms':
      case 'alarm':
        return LineAwesomeIcons.bell_solid;
      case 'car_lock_programming':
      case 'key_programming':
        return LineAwesomeIcons.key_solid;
      case 'door_lock_installation':
      case 'door_installation':
        return LineAwesomeIcons.door_closed_solid;
      case 'door_lock_repair':
      case 'door_repair':
        return LineAwesomeIcons.tools_solid;
      case 'smart_lock_installation':
      case 'smart_lock':
        return LineAwesomeIcons.lock_solid;
      default:
        return LineAwesomeIcons.tools_solid;
    }
  }

  Widget _buildMetaRow(BuildContext context, JobEntity job) {
    final items = <Widget>[];
    if (job.hasLocation) {
      items.add(_metaChip(context, LineAwesomeIcons.map_marker_solid, job.location!));
    }
    if (job.leadSource != null && job.leadSource!.isNotEmpty) {
      items.add(_metaChip(context, LineAwesomeIcons.link_solid, job.leadSource!.replaceAll('_', ' ').toUpperCase()));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: items,
    );
  }

  Widget _metaChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.ksc.neutral500),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(
            color: context.ksc.neutral400,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, WidgetRef ref, JobEntity job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if (job.currentStatusTimestamp != null) ...[
          const SizedBox(height: 6),
          Text(
            "${job.status.replaceAll('_', ' ').toUpperCase()} · ${DateFormatter.display(job.currentStatusTimestamp!).toUpperCase()}",
            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
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
    final partsAsync = ref.watch(jobPartsProvider(jobId));
    final hwAsync = ref.watch(jobHardwareProvider(jobId));
    final expensesAsync = ref.watch(jobExpensesProvider(jobId));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          // Gross profit — computed from parts, hardware, expenses
          if (job.hasAmount) ...[
            const SizedBox(height: 16),
            Divider(color: context.ksc.primary700, height: 1),
            const SizedBox(height: 12),
            _buildGrossProfitRow(context, ref, job, partsAsync, hwAsync, expensesAsync),
          ],
        ],
      ),
    );
  }

  Widget _buildGrossProfitRow(BuildContext context, WidgetRef ref, JobEntity job,
      AsyncValue<List<JobPartEntity>> partsAsync,
      AsyncValue<List<JobHardwareEntity>> hwAsync,
      AsyncValue<List<JobExpenseEntity>> expensesAsync) {
    final partsData = partsAsync.valueOrNull ?? [];
    final hwData = hwAsync.valueOrNull ?? [];
    final expensesData = expensesAsync.valueOrNull ?? [];

    final partsCost = partsData.fold<int>(0, (s, p) => s + p.totalCost);
    final hwCost = hwData.fold<int>(0, (s, h) => s + h.totalSalePrice);
    final totalExpenses = expensesData.fold<int>(0, (s, e) => s + e.amount);
    final totalCost = partsCost + hwCost + totalExpenses;
    final revenue = job.amountCharged ?? 0;
    final grossProfit = revenue - totalCost;
    final margin = revenue > 0 ? (grossProfit / revenue * 100) : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("GROSS PROFIT", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            Text(
              CurrencyFormatter.formatShort(grossProfit),
              style: AppTextStyles.h2.copyWith(
                color: grossProfit >= 0 ? context.ksc.success500 : context.ksc.error500,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Margin bar
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 6,
            decoration: BoxDecoration(color: context.ksc.primary700, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: margin.clamp(0.0, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: grossProfit >= 0 ? context.ksc.success500 : context.ksc.error500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Margin pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: grossProfit >= 0 ? context.ksc.success500.withValues(alpha: 0.15) : context.ksc.error500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: grossProfit >= 0 ? context.ksc.success500.withValues(alpha: 0.4) : context.ksc.error500.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                "${margin.toStringAsFixed(0)}% MARGIN",
                style: AppTextStyles.caption.copyWith(
                  color: grossProfit >= 0 ? context.ksc.success500 : context.ksc.error500,
                  fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Revenue / Cost breakdown pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.ksc.primary700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Rev: ${CurrencyFormatter.formatShort(revenue)}  ·  Cost: ${CurrencyFormatter.formatShort(totalCost)}",
                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildInvoiceShareButton(BuildContext context, WidgetRef ref, JobEntity job) {
    return GestureDetector(
      onTap: () async {
        final customer = await ref.read(customerDetailProvider(job.customerId).future);
        final parts = await ref.read(jobPartsProvider(job.id).future);
        final services = await ref.read(jobServicesProvider(job.id).future);
        final hardwareItems = await ref.read(jobHardwareProvider(job.id).future);

        final data = InvoiceData(
          invoiceNumber: job.id.substring(0, 8).toUpperCase(),
          date: job.jobDate,
          customerName: customer?.fullName ?? 'N/A',
          customerPhone: customer?.phoneNumber ?? '',
          customerLocation: customer?.location,
          serviceType: job.serviceType,
          status: job.status,
          paymentStatus: job.paymentStatus,
          paymentMethod: job.paymentMethod,
          amountCharged: job.amountCharged,
          quotedPrice: job.quotedPrice != null ? (job.quotedPrice! * 100).round() : null,
          hardwareBrand: job.hardwareBrand,
          hardwareKeyway: job.hardwareKeyway,
          services: services.map((s) => InvoiceService(
            name: s.serviceType,
            quantity: s.quantity,
            unitPrice: s.unitPrice,
          )).toList(),
          parts: parts.map((p) => InvoicePart(
            name: p.partName,
            quantity: p.quantity ?? 1,
            unitPrice: p.unitPrice,
          )).toList(),
          hardwareItems: hardwareItems.map((h) => InvoiceHardware(
            name: h.brand ?? h.model ?? h.category ?? 'Hardware',
            brand: h.brand,
            quantity: h.quantity,
            unitPrice: h.unitSalePrice,
          )).toList(),
        );

        final file = await InvoicePdfGenerator.generate(data);
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: 'keystone_invoice_${job.id.substring(0, 8)}.pdf',
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.file_pdf_solid, size: 16, color: context.ksc.accent500),
            const SizedBox(width: 8),
            Text(
              "SHARE INVOICE PDF",
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptButton(BuildContext context, WidgetRef ref, JobEntity job) {
    return GestureDetector(
      onTap: () async {
        final customer = await ref.read(customerDetailProvider(job.customerId).future);
        final data = ReceiptData(
          receiptNumber: job.id.substring(0, 8).toUpperCase(),
          date: DateTime.now(),
          customerName: customer?.fullName ?? 'N/A',
          customerPhone: customer?.phoneNumber ?? '',
          serviceType: job.serviceType,
          paymentMethod: job.paymentMethod ?? 'cash',
          amountPaid: job.amountCharged ?? 0,
          notes: job.notes,
        );
        final file = await ReceiptPdfGenerator.generate(data);
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: 'keystone_receipt_${job.id.substring(0, 8)}.pdf',
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.ksc.success600.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.ksc.success600.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.file_invoice_solid, size: 16, color: context.ksc.success500),
            const SizedBox(width: 8),
            Text(
              "GENERATE RECEIPT",
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.success500,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerModule(BuildContext context, WidgetRef ref, String customerId, JobEntity job) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    return customerAsync.when(
      loading: () => Container(height: 80).animate().shimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (customer) {
        if (customer == null) return const SizedBox.shrink();
        return Column(
          children: [
            GestureDetector(
              onTap: () => context.push(RouteNames.customerDetail(customerId)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.ksc.primary700),
                      ),
                      child: Center(
                        child: Text(
                          customer.fullName[0].toUpperCase(),
                          style: AppTextStyles.h2.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.fullName.toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(customer.phoneNumber ?? "NO CONTACT", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral400, size: 16),
                  ],
                ),
              ),
            ),
            // Quick actions row
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _quickActionBtn(context, LineAwesomeIcons.phone_solid, "CALL", context.ksc.success500, () async {
                    final phone = customer.phoneNumber;
                    if (phone != null && phone.isNotEmpty) {
                      final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                      final uri = Uri.parse('tel:$cleaned');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _quickActionBtn(context, LineAwesomeIcons.whatsapp, "WHATSAPP", const Color(0xFF25D366), () async {
                    final phone = customer.phoneNumber;
                    if (phone != null && phone.isNotEmpty) {
                      // Show one-time info toast before redirecting to WhatsApp
                      if (!_warnedWhatsAppCustomers.contains(customer.id)) {
                        _warnedWhatsAppCustomers.add(customer.id);
                        if (context.mounted) {
                          KsSlidingNotification.show(
                            context,
                            message: "If this person doesn't appear in WhatsApp, they may not be on WhatsApp.",
                            type: KsNotificationType.info,
                          );
                        }
                      }
                      try {
                        await WhatsAppLauncher.openChat(
                          phoneNumber: phone,
                          message: 'Hello from Keystone Services.',
                        );
                      } catch (_) {
                        // WhatsApp not installed — handled by WhatsAppLauncher
                      }
                    }
                  }),
                ),
                if (customer.location != null && customer.location!.isNotEmpty || job.hasCoordinates) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _quickActionBtn(context, LineAwesomeIcons.map_marker_solid, "NAVIGATE", context.ksc.accent500, () async {
                      if (job.hasCoordinates) {
                        final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${job.latitude},${job.longitude}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      } else if (customer.location != null && customer.location!.isNotEmpty) {
                        final query = Uri.encodeComponent(customer.location!);
                        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    }),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _quickActionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final servicesAsync = ref.watch(jobServicesProvider(job.id));
    return servicesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (services) {
        if (services.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "SERVICES"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: Column(
                children: services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${s.quantity}x ${s.serviceType.replaceAll('_', ' ').toUpperCase()}",
                          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (s.unitPrice != null)
                        Text(
                          CurrencyFormatter.formatShort(s.totalPrice),
                          style: AppTextStyles.body.copyWith(color: context.ksc.neutral400),
                        ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemsUsedSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final partsAsync = ref.watch(jobPartsProvider(jobId));
    final hwAsync = ref.watch(jobHardwareProvider(jobId));

    return partsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (parts) => hwAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (hardwareItems) {
          if (parts.isEmpty && hardwareItems.isEmpty) return const SizedBox.shrink();
          final totalItemsCost = parts.fold<int>(0, (s, p) => s + p.totalCost) +
              hardwareItems.fold<int>(0, (s, h) => s + (h.totalSalePrice));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, "ITEMS USED"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Column(
                  children: [
                    // Hardware items
                    ...hardwareItems.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: context.ksc.accent500, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (h.brand ?? h.model ?? "HARDWARE").toUpperCase(),
                              style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text("${h.quantity}x", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                          const SizedBox(width: 8),
                          Text(CurrencyFormatter.formatShort(h.totalSalePrice), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 11)),
                        ],
                      ),
                    )),
                    // Parts
                    ...parts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF6BB5FF), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${p.quantity}x ${p.partName.toUpperCase()}",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(CurrencyFormatter.formatShort(p.totalCost), style: AppTextStyles.caption.copyWith(color: const Color(0xFF6BB5FF), fontWeight: FontWeight.w800, fontSize: 11)),
                        ],
                      ),
                    )),
                    if (parts.isNotEmpty || hardwareItems.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Divider(color: context.ksc.primary700, height: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("TOTAL COST", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          Text(CurrencyFormatter.formatShort(totalItemsCost), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpensesSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final expensesAsync = ref.watch(jobExpensesProvider(jobId));
    // Optional — compute net profit only if parts data is also available
    final partsAsync = ref.watch(jobPartsProvider(jobId));

    return expensesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (expenses) {
        if (expenses.isEmpty) return const SizedBox.shrink();

        final totalExpenses = expenses.fold<int>(0, (s, e) => s + e.amount);
        final revenue = job.amountCharged ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "EXPENSES"),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: Column(
                children: [
                  ...expenses.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _expenseCategoryBadge(context, e.category),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.categoryLabel.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 10)),
                                    Text(e.description, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(CurrencyFormatter.formatShort(e.amount), style: AppTextStyles.body.copyWith(color: context.ksc.error500, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  Divider(color: context.ksc.primary700, height: 1),
                  const SizedBox(height: 12),
                  _financialRow(context, "TOTAL EXPENSES", CurrencyFormatter.formatShort(totalExpenses)),
                  // Net profit shown only if parts data is available
                  if (partsAsync.hasValue && partsAsync.value!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _financialRow(context, "NET PROFIT", CurrencyFormatter.formatShort(
                      revenue - partsAsync.value!.fold<int>(0, (s, p) => s + p.totalCost) - totalExpenses,
                    ), isBold: true),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _expenseCategoryBadge(BuildContext context, String category) {
    Color color;
    switch (category) {
      case 'transport':     color = context.ksc.accent500; break;
      case 'parking':       color = context.ksc.warning500; break;
      case 'subcontractor': color = context.ksc.primary500; break;
      case 'supplies':      color = context.ksc.success500; break;
      default:              color = context.ksc.neutral500;
    }
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
            _buildSectionHeader(context, "MEDIA"),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (ctx, i) => _buildPhotoCard(context, ref, photos, i),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildPhotoCard(BuildContext context, WidgetRef ref, List<JobPhotoEntity> photos, int index) {
    final photo = photos[index];
    final isVideo = photo.mediaType == 'video';
    final isAudio = photo.mediaType == 'audio';
    return GestureDetector(
      onTap: () => _openMediaViewer(context, photos, index),
      child: Container(
        width: 120,
        height: 140,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image thumbnail or media placeholder
              if (isVideo || isAudio)
                Container(
                  color: context.ksc.primary800,
                  child: Center(
                    child: Icon(
                      isVideo ? LineAwesomeIcons.play_circle_solid : LineAwesomeIcons.microphone_solid,
                      color: context.ksc.accent500,
                      size: 36,
                    ),
                  ),
                )
              else
                Image.network(
                  photo.storagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: context.ksc.primary800,
                      child: const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (ctx, error, stack) => Container(
                    color: context.ksc.primary800,
                    child: Icon(LineAwesomeIcons.image_solid, color: context.ksc.neutral500, size: 28),
                  ),
                ),
              // Label overlay at bottom
              if (photo.label != null)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    color: Colors.black54,
                    child: Text(
                      photo.label!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              // Media type badge — top-left
              Positioned(
                top: 4, left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVideo
                        ? const Color(0xFF6BB5FF).withValues(alpha: 0.85)
                        : isAudio
                            ? const Color(0xFFB388FF).withValues(alpha: 0.85)
                            : context.ksc.accent500.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isVideo ? "VIDEO" : isAudio ? "AUDIO" : "PHOTO",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.primary900,
                      fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
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
            _buildSectionHeader(context, "JOB TIMELINE"),
            const SizedBox(height: 8),
            ...logs.asMap().entries.map((entry) {
              final log = entry.value;
              final isFirst = entry.key == 0;
              return _buildTimelineEntry(context, log, isFirst);
            }),
          ],
        );
      }
    );
  }

  Widget _buildTimelineEntry(BuildContext context, JobAuditEntryEntity log, bool isFirst) {
    final iconData = _timelineIcon(context, log.action);
    final color = _timelineColor(context, log.action);
    final label = _timelineLabel(log.action, log.newValues);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 8, color: context.ksc.primary700),
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, size: 14, color: color),
                ),
                Expanded(
                  child: Container(width: 2, color: context.ksc.primary700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.white, fontWeight: FontWeight.w800, fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormatter.short(log.createdAt).toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500, fontWeight: FontWeight.w600, fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  if (log.newValues != null && log.action == 'updated')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatChanges(log.newValues!),
                        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _timelineIcon(BuildContext context, String action) {
    switch (action) {
      case 'created':              return LineAwesomeIcons.plus_circle_solid;
      case 'updated':
      case 'status_changed':       return LineAwesomeIcons.edit_solid;
      case 'archived':             return LineAwesomeIcons.archive_solid;
      case 'correction_requested': return LineAwesomeIcons.question_circle_solid;
      case 'correction_approved':  return LineAwesomeIcons.check_circle_solid;
      case 'correction_rejected':  return LineAwesomeIcons.times_circle_solid;
      default:                     return LineAwesomeIcons.circle_solid;
    }
  }

  Color _timelineColor(BuildContext context, String action) {
    switch (action) {
      case 'created':              return context.ksc.success500;
      case 'updated':
      case 'status_changed':       return context.ksc.accent500;
      case 'archived':             return context.ksc.neutral500;
      case 'correction_requested': return context.ksc.warning500;
      case 'correction_approved':  return context.ksc.success500;
      case 'correction_rejected':  return context.ksc.error500;
      default:                     return context.ksc.neutral500;
    }
  }

  String _timelineLabel(String action, Map<String, dynamic>? newValues) {
    switch (action) {
      case 'created':              return 'JOB LOGGED';
      case 'archived':             return 'JOB ARCHIVED';
      case 'correction_requested': return 'CORRECTION REQUESTED';
      case 'correction_approved':  return 'CORRECTION APPROVED';
      case 'correction_rejected':  return 'CORRECTION REJECTED';
      case 'status_changed':
        final newStatus = newValues?['status'] as String? ?? '';
        return 'STATUS → ${newStatus.replaceAll('_', ' ').toUpperCase()}';
      case 'updated':
        if (newValues?.containsKey('payment_status') == true) {
          final ps = newValues!['payment_status'] as String? ?? '';
          return 'PAYMENT → ${ps.toUpperCase()}';
        }
        return 'JOB UPDATED';
      default:                     return action.toUpperCase();
    }
  }

  String _formatChanges(Map<String, dynamic> changes) {
    return changes.entries.map((e) {
      final key = e.key.replaceAll('_', ' ').toUpperCase();
      final val = e.value?.toString() ?? '';
      return '$key: $val';
    }).join(' · ');
  }

  Widget _buildNotesModule(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineAwesomeIcons.sticky_note_solid, size: 14, color: context.ksc.accent500),
              const SizedBox(width: 8),
              Text("NOTES", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes,
            style: AppTextStyles.body.copyWith(color: context.ksc.neutral400, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, JobEntity job) {
    final permissions = ref.read(permissionsProvider);
    final validOptions = JobEntity.validStatuses.where((s) {
      return JobEntity.validateStatusTransition(job.status, s) == null;
    }).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? context.ksc.neutral100 : context.ksc.neutral800;

    final nonCurrentOptions = validOptions.where((s) => s != job.status).toList();
    if (nonCurrentOptions.isEmpty) {
      KsSlidingNotification.show(context, message: "No further status transitions available", type: KsNotificationType.info);
      return;
    }

    String? selectedStatus;
    bool isUpdating = false;
    StateSetter? sheetSetState;

    KsBottomSheetScaffold.show(
      context,
      title: "CHANGE STATUS",
      subtitle: "Current: ${job.status.replaceAll('_', ' ').toUpperCase()}",
      bottomLabel: isUpdating ? "UPDATING..." : "UPDATE STATUS",
      canPop: () => false,
      onDone: () {
        if (selectedStatus == null) {
          KsSlidingNotification.show(context, message: "Select a status first", type: KsNotificationType.info);
          return;
        }
        isUpdating = true;
        sheetSetState?.call(() {});
        _executeStatusUpdate(context, ref, job, selectedStatus!, permissions);
      },
      contentBuilder: (ctx, setSheetState) {
        sheetSetState = setSheetState;
        return Column(
          children: validOptions.map((st) {
            final label = st.replaceAll('_', ' ').toUpperCase();
            final isCurrent = st == job.status;
            final isSelected = selectedStatus == st;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: (isCurrent || isUpdating) ? null : () => setSheetState(() => selectedStatus = st),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.ksc.accent500.withValues(alpha: 0.15)
                        : (isCurrent ? context.ksc.primary700 : context.ksc.primary700),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected || isCurrent ? context.ksc.accent500 : context.ksc.primary600,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.body.copyWith(
                            color: isSelected || isCurrent ? context.ksc.accent500 : textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Icon(LineAwesomeIcons.check_circle_solid, color: context.ksc.accent500, size: 16),
                      if (isSelected && !isCurrent)
                        Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 16),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _executeStatusUpdate(BuildContext context, WidgetRef ref, JobEntity job, String newStatus, dynamic permissions) async {
    // After-photo check for completed
    if (newStatus == 'completed' && permissions.requireAfterPhoto) {
      final photos = await ref.read(jobPhotosProvider(job.id).future);
      final hasAfterPhoto = photos.any((p) => p.label == 'after');
      if (!hasAfterPhoto && context.mounted) {
        KsSlidingNotification.show(context, message: "An after-photo is required before marking as completed", type: KsNotificationType.error);
        return;
      }
    }
    // Confirm irreversible transitions
    if (newStatus == 'completed' || newStatus == 'invoiced') {
      final confirmed = await KsConfirmDialog.show(
        context,
        title: newStatus == 'completed' ? 'MARK AS COMPLETED?' : 'MARK AS INVOICED?',
        message: newStatus == 'completed'
            ? 'This will move the job to completed status. No further edits to service items will be allowed.'
            : 'This will mark the job as invoiced. This action affects your financial records.',
        confirmLabel: 'CONFIRM',
        isDanger: newStatus == 'invoiced',
        onConfirm: () {},
      );
      if (confirmed != true) return;
    }
    final user = await ref.read(currentUserProvider.future);
    if (user != null && context.mounted) {
      try {
        await ref.read(jobRepositoryProvider).updateJobStatus(job.id, newStatus, user.id);
        ref.invalidate(jobDetailProvider(job.id));
        // Pop the status sheet — use Navigator.of with rootContext
        if (context.mounted) {
          Navigator.of(context).pop();
          KsSlidingNotification.show(context, message: "Status updated to ${newStatus.replaceAll('_', ' ')}", type: KsNotificationType.success);
        }
      } catch (_) {
        if (context.mounted) {
          KsSlidingNotification.show(context, message: "Could not update status", type: KsNotificationType.error);
        }
      }
    }
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref, JobEntity job) {
    final allowedByStatus = JobEntity.allowedPaymentStatuses(job.status);
    final validStatuses = JobEntity.validPaymentStatuses.where((s) {
      return allowedByStatus.contains(s) &&
          JobEntity.validatePaymentTransition(job.paymentStatus, s) == null;
    }).toList();
    final methods = ['cash', 'mobile_money', 'bank_transfer', 'other'];

    final nonCurrent = validStatuses.where((s) => s != job.paymentStatus).toList();
    if (nonCurrent.isEmpty) {
      KsSlidingNotification.show(context,
        message: job.paymentStatus == 'paid'
            ? "Payment status is already 'paid' and cannot be changed"
            : "No other payment statuses available",
        type: KsNotificationType.info);
      return;
    }

    String? selectedStatus;
    String? selectedMethod;
    bool isUpdating = false;
    StateSetter? sheetSetState;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? context.ksc.neutral100 : context.ksc.neutral800;

    KsBottomSheetScaffold.show(
      context,
      title: "PAYMENT",
      subtitle: "Update payment status and method",
      bottomLabel: isUpdating ? "UPDATING..." : "UPDATE PAYMENT",
      canPop: () => false,
      onDone: () {
        if (selectedStatus == null) {
          KsSlidingNotification.show(context, message: "Select a payment status first", type: KsNotificationType.info);
          return;
        }
        isUpdating = true;
        sheetSetState?.call(() {});
        _executePaymentUpdate(context, ref, job, selectedStatus!, selectedMethod);
      },
      contentBuilder: (ctx, setSheetState) {
        sheetSetState = setSheetState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("STATUS", style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: validStatuses.map((s) {
                final isCurrent = s == job.paymentStatus;
                final isSelected = selectedStatus == s;
                return GestureDetector(
                  onTap: (isCurrent || isUpdating) ? null : () => setSheetState(() => selectedStatus = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.ksc.accent500.withValues(alpha: 0.15)
                          : context.ksc.primary700,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected || isCurrent
                            ? context.ksc.accent500
                            : context.ksc.primary600,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.replaceAll('_', ' ').toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected || isCurrent ? context.ksc.accent500 : textColor,
                            fontWeight: FontWeight.w900,
                          )),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 10),
                        ],
                        if (isSelected && !isCurrent) ...[
                          const SizedBox(width: 6),
                          Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 10),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text("PAYMENT METHOD", style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: methods.map((m) => GestureDetector(
                onTap: isUpdating ? null : () => setSheetState(() => selectedMethod = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedMethod == m ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary700,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selectedMethod == m ? context.ksc.accent500 : context.ksc.primary600),
                  ),
                  child: Text(
                    m == 'mobile_money' ? 'MOBILE MONEY' : m.replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: selectedMethod == m ? context.ksc.accent500 : textColor,
                      fontWeight: FontWeight.w900,
                    )),
                ),
              )).toList(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executePaymentUpdate(BuildContext context, WidgetRef ref, JobEntity job, String newStatus, String? method) async {
    if (context.mounted) {
      final transitionError = JobEntity.validatePaymentTransition(job.paymentStatus, newStatus);
      if (transitionError != null) {
        KsSlidingNotification.show(context, message: transitionError, type: KsNotificationType.error);
        return;
      }
      final statusError = JobEntity.validatePaymentForStatus(job.status, newStatus);
      if (statusError != null) {
        KsSlidingNotification.show(context, message: statusError, type: KsNotificationType.error);
        return;
      }
      final confirmed = await KsConfirmDialog.show(
        context,
        title: 'UPDATE PAYMENT?',
        message: 'Mark as ${newStatus.toUpperCase()} '
            'via ${method?.toUpperCase() ?? 'NONE'}?\n\n'
            'Current: ${job.paymentStatus?.toUpperCase() ?? 'UNPAID'}',
        confirmLabel: 'UPDATE',
        isDanger: newStatus == 'paid',
        onConfirm: () {},
      );
      if (confirmed != true) return;
      final user = await ref.read(currentUserProvider.future);
      if (user != null && context.mounted) {
        try {
          await ref.read(jobRepositoryProvider).updatePaymentStatus(job.id, newStatus, method, user.id);
          ref.invalidate(jobDetailProvider(job.id));
          if (context.mounted) {
            Navigator.of(context).pop();
            KsSlidingNotification.show(context,
              message: "Payment updated to ${newStatus.toUpperCase()}",
              type: KsNotificationType.success);
          }
        } catch (_) {
          if (context.mounted) {
            KsSlidingNotification.show(context,
              message: "Could not update payment", type: KsNotificationType.error);
          }
        }
      }
    }
  }

  void _openMediaViewer(BuildContext context, List<JobPhotoEntity> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenMediaViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Summary strip showing counts of items, expenses, photos, notes, linked notes.
class _SummaryStrip extends ConsumerWidget {
  final String jobId;
  final String? notes;
  const _SummaryStrip({required this.jobId, this.notes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(jobPartsProvider(jobId));
    final hwAsync = ref.watch(jobHardwareProvider(jobId));
    final expensesAsync = ref.watch(jobExpensesProvider(jobId));
    final photosAsync = ref.watch(jobPhotosProvider(jobId));
    final linkedNotesAsync = ref.watch(noteLinkByJobProvider(jobId));

    final partsCount = partsAsync.valueOrNull?.length ?? 0;
    final hwCount = hwAsync.valueOrNull?.length ?? 0;
    final expensesCount = expensesAsync.valueOrNull?.length ?? 0;
    final photosCount = photosAsync.valueOrNull?.length ?? 0;
    final linkedCount = linkedNotesAsync.valueOrNull?.length ?? 0;
    final hasNotes = notes != null && notes!.isNotEmpty;

    final totalItems = partsCount + hwCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (totalItems > 0)
            _chip(context, LineAwesomeIcons.box_solid, "$totalItems item${totalItems > 1 ? 's' : ''}"),
          if (expensesCount > 0)
            _chip(context, LineAwesomeIcons.wallet_solid, "$expensesCount expense${expensesCount > 1 ? 's' : ''}"),
          if (photosCount > 0)
            _chip(context, LineAwesomeIcons.camera_solid, "$photosCount photo${photosCount > 1 ? 's' : ''}"),
          if (hasNotes)
            _chip(context, LineAwesomeIcons.sticky_note_solid, "1 note"),
          if (linkedCount > 0)
            _chip(context, LineAwesomeIcons.link_solid, "$linkedCount linked"),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: context.ksc.accent500),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral300, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  const _AudioPlayerWidget({required this.controller});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: context.ksc.accent500, size: 48),
          onPressed: () {
            if (isPlaying) {
              widget.controller.pause();
            } else {
              widget.controller.play();
            }
          },
        ),
        const SizedBox(width: 12),
        Text(
          widget.controller.value.isInitialized
              ? _formatDuration(widget.controller.value.position)
              : "Loading...",
          style: AppTextStyles.body.copyWith(color: context.ksc.white),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
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
              borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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

/// Full-screen media viewer with swipe navigation, pinch-to-zoom for images,
/// and native video playback controls.
class _FullScreenMediaViewer extends StatefulWidget {
  final List<JobPhotoEntity> photos;
  final int initialIndex;

  const _FullScreenMediaViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<_FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initVideoForIndex(_currentIndex);
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initVideoForIndex(int index) async {
    final photo = widget.photos[index];
    if (photo.mediaType != 'video') return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(photo.storagePath));
    try {
      await controller.initialize();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) { controller.dispose(); return; }
    controller.play();
    controller.addListener(_onVideoUpdate);
    if (mounted) {
      setState(() { _videoController = controller; });
    }
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  void _onPageChanged(int index) {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _videoController = null;
    _currentIndex = index;
    _initVideoForIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${_currentIndex + 1} / ${widget.photos.length}",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          if (photo.label != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    photo.label!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (ctx, i) => _buildMediaItem(widget.photos[i]),
      ),
    );
  }

  Widget _buildMediaItem(JobPhotoEntity photo) {
    switch (photo.mediaType) {
      case 'video':
        if (_videoController != null && _videoController!.value.isInitialized) {
          return GestureDetector(
            onTap: () => setState(() { _showControls = !_showControls; }),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: () {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                      setState(() { _showControls = false; });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.play_circle, color: Colors.white70, size: 72),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator(color: Colors.white));

      case 'audio':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LineAwesomeIcons.microphone_solid, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                photo.label?.toUpperCase() ?? "AUDIO RECORDING",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

      default: // image
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              photo.storagePath,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (ctx, error, stack) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LineAwesomeIcons.image_solid, color: Colors.white38, size: 48),
                  SizedBox(height: 8),
                  Text(
                    "Could not load image",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
