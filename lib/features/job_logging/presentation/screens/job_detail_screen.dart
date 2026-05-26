import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:printing/printing.dart';
import 'package:keystone/core/services/invoice_pdf_generator.dart';
import 'package:keystone/core/services/receipt_pdf_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/utils/date_formatter.dart';
import 'package:keystone/core/utils/currency_formatter.dart';
import 'package:keystone/core/widgets/ks_app_bar.dart';
import 'package:keystone/core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_badge.dart';
import 'package:keystone/core/widgets/ks_button.dart';
import 'package:keystone/core/widgets/ks_confirm_dialog.dart';
import 'package:keystone/core/widgets/sync_status_indicator.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import 'package:keystone/core/router/route_names.dart';
import 'package:keystone/core/providers/auth_provider.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_photo_entity.dart';
import 'package:keystone/features/job_logging/domain/entities/job_audit_entry_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/customer_history/presentation/providers/customer_providers.dart';
import 'package:keystone/features/knowledge_base/presentation/providers/notes_providers.dart';
import 'package:keystone/features/note_links/presentation/providers/note_link_provider.dart';
import 'package:keystone/features/whatsapp_followup/presentation/widgets/follow_up_button.dart';
import 'package:keystone/features/whatsapp_followup/presentation/widgets/follow_up_message_preview.dart';
import 'package:keystone/core/providers/permissions_provider.dart';

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
                  await ref.read(jobListProvider.notifier).archive(jobId);
                  if (!context.mounted) return;
                  final error = ref.read(jobListProvider).errorMessage;
                  if (error != null && error.isNotEmpty) {
                    KsSlidingNotification.show(context, message: error, type: KsNotificationType.error);
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
                      const SizedBox(height: 12),
                      _buildInvoiceShareButton(context, ref, job),
                      if (job.isPaid) ...[
                        const SizedBox(height: 12),
                        _buildReceiptButton(context, ref, job),
                      ],
                      const SizedBox(height: 32),

                      _buildSectionHeader(context, "CUSTOMER"),
                      _buildCustomerModule(context, ref, job.customerId),
                      const SizedBox(height: 32),

                      _buildServicesSection(context, ref, job),
                      const SizedBox(height: 32),

                      _buildHardwareSection(context, ref, job),
                      const SizedBox(height: 32),

                      _buildPartsSection(context, ref, job),
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
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
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
                color: context.ksc.accent500,
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
          borderRadius: BorderRadius.circular(4),
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
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
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

  Widget _buildHardwareSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final hwAsync = ref.watch(jobHardwareProvider(job.id));
    return hwAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "HARDWARE ITEMS"),
            ...items.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                        Text(
                          (h.brand ?? "UNKNOWN").toUpperCase(),
                          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
                        ),
                        if (h.model != null) ...[
                          const SizedBox(width: 8),
                          Text(h.model!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400)),
                        ],
                        const Spacer(),
                        Text("${h.quantity}x", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
                      ],
                    ),
                    if (h.keySpec != null || h.domain != null || h.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (h.category != null) h.category!.replaceAll('_', ' ').toUpperCase(),
                          if (h.domain != null) h.domain!.replaceAll('_', ' ').toUpperCase(),
                          if (h.keySpec != null) "KEY: ${h.keySpec}",
                        ].join(" · "),
                        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10),
                      ),
                    ],
                    if (h.finish != null || h.material != null || h.dimensions != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [h.finish, h.material, h.dimensions].where((x) => x != null).join(" · "),
                        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9),
                      ),
                    ],
                    if (h.unitSalePrice != null || h.unitCostPrice != null) ...[
                      const SizedBox(height: 8),
                      Divider(color: context.ksc.primary700, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (h.unitSalePrice != null)
                            Text("SALE: ${CurrencyFormatter.formatShort(h.totalSalePrice)}", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800)),
                          if (h.unitCostPrice != null)
                            Text("COST: ${CurrencyFormatter.formatShort(h.totalCostPrice)}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                          if (h.hasCost)
                            Text("PROFIT: ${CurrencyFormatter.formatShort(h.grossProfit)}", style: AppTextStyles.caption.copyWith(color: h.grossProfit >= 0 ? context.ksc.success500 : context.ksc.error500, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                    if (h.notes != null && h.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(h.notes!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 9)),
                    ],
                  ],
                ),
              ),
            )),
          ],
        );
      },
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

  Widget _buildExpensesSection(BuildContext context, WidgetRef ref, JobEntity job) {
    final partsAsync = ref.watch(jobPartsProvider(jobId));
    final expensesAsync = ref.watch(jobExpensesProvider(jobId));
    final bothLoaded = partsAsync.hasValue && expensesAsync.hasValue;
    if (!bothLoaded) return const SizedBox.shrink();

    final parts = partsAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];
    if (expenses.isEmpty) return const SizedBox.shrink();

    final totalExpenses = expenses.fold<int>(0, (s, e) => s + e.amount);
    final partsCost = parts.fold<int>(0, (s, p) => s + p.totalCost);
    final revenue = job.amountCharged ?? 0;
    final netProfit = revenue - partsCost - totalExpenses;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "EXPENSES"),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: Column(
                children: [
                  ...expenses.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _expenseCategoryBadge(context, e.category),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.categoryLabel.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 10)),
                                Text(e.description, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
                        Text(CurrencyFormatter.formatShort(e.amount), style: AppTextStyles.body.copyWith(color: context.ksc.error500, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  Divider(color: context.ksc.primary700, height: 1),
                  const SizedBox(height: 12),
                  _financialRow(context, "TOTAL EXPENSES", CurrencyFormatter.formatShort(totalExpenses)),
                  const SizedBox(height: 8),
                  _financialRow(context, "NET PROFIT", CurrencyFormatter.formatShort(netProfit), isBold: true),
                ],
              ),
            ),
          ],
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
    final permissions = ref.watch(permissionsProvider);
    final isAdmin = ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    final canModify = permissions.canDeleteJobs || isAdmin;
    return photosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (photos) {
        if (photos.isEmpty && !canModify) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "PHOTOS"),
            if (photos.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5
                ),
                itemCount: photos.length,
                itemBuilder: (ctx, i) => _buildPhotoCard(context, ref, photos[i]),
              ),
              const SizedBox(height: 12),
            ],
            if (canModify)
              KsButton(
                label: "ADD PHOTO",
                variant: KsButtonVariant.secondary,
                size: KsButtonSize.small,
                fullWidth: false,
                leadingIcon: LineAwesomeIcons.camera_solid,
                onPressed: () => _addPhoto(context, ref, job),
              ),
          ],
        );
      }
    );
  }

  Widget _buildPhotoCard(BuildContext context, WidgetRef ref, JobPhotoEntity photo) {
    final permissions = ref.watch(permissionsProvider);
    final isAdmin = ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    final canModify = permissions.canDeleteJobs || isAdmin;
    final isVideo = photo.mediaType == 'video';
    final isAudio = photo.mediaType == 'audio';
    return Stack(
      children: [
        GestureDetector(
          onTap: isVideo || isAudio ? () => _playMedia(context, photo) : null,
          child: Container(
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.ksc.primary700),
              image: !isVideo && !isAudio
                  ? DecorationImage(image: NetworkImage(photo.storagePath), fit: BoxFit.cover)
                  : null,
            ),
            child: Center(
              child: isVideo
                  ? Icon(LineAwesomeIcons.play_circle_solid, color: context.ksc.accent500, size: 40)
                  : isAudio
                      ? Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.accent500, size: 40)
                      : null,
            ),
          ),
        ),
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
        if (canModify)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _deletePhoto(context, ref, photo),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref, JobEntity job) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked == null) return;

    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;

    try {
      final remote = ref.read(jobPhotosRemoteDatasourceProvider);
      final publicUrl = await remote.uploadMedia(
        jobId: job.id,
        userId: userId,
        file: File(picked.path),
        label: 'after',
        mediaType: 'image',
      );
      await remote.createPhotoRecord({
        'id': const Uuid().v4(),
        'job_id': job.id,
        'storage_path': publicUrl,
        'label': 'after',
        'media_type': 'image',
        'created_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(jobPhotosProvider(jobId));
      if (context.mounted) {
        KsSlidingNotification.show(context, message: "Photo added", type: KsNotificationType.success);
      }
    } catch (_) {
      if (context.mounted) {
        KsSlidingNotification.show(context, message: "Could not add photo", type: KsNotificationType.error);
      }
    }
  }

  Future<void> _deletePhoto(BuildContext context, WidgetRef ref, JobPhotoEntity photo) async {
    final confirmed = await KsConfirmDialog.show(
      context,
      title: 'DELETE PHOTO',
      message: 'Remove this photo from the job record?',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      isDanger: true,
      onConfirm: () {},
    );
    if (confirmed != true) return;

    try {
      final remote = ref.read(jobPhotosRemoteDatasourceProvider);
      await remote.deletePhoto(photo.id, photo.storagePath);
      ref.invalidate(jobPhotosProvider(jobId));
      if (context.mounted) {
        KsSlidingNotification.show(context, message: "Photo deleted", type: KsNotificationType.success);
      }
    } catch (_) {
      if (context.mounted) {
        KsSlidingNotification.show(context, message: "Could not delete photo", type: KsNotificationType.error);
      }
    }
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
    final permissions = ref.read(permissionsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ksc.primary800,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(opt.$2, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: () async {
              if (opt.$1 == 'completed' && permissions.requireAfterPhoto) {
                final photos = await ref.read(jobPhotosProvider(job.id).future);
                final hasAfterPhoto = photos.any((p) => p.label == 'after');
                if (!hasAfterPhoto && context.mounted) {
                  Navigator.pop(ctx);
                  KsSlidingNotification.show(context, message: "An after-photo is required before marking as completed", type: KsNotificationType.error);
                  return;
                }
              }
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
    final statuses = ['unpaid', 'partial', 'paid'];
    final methods = ['cash', 'mobile_money', 'bank_transfer', 'other'];
    String? selectedStatus;
    String? selectedMethod;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.ksc.primary800,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PAYMENT STATUS", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: statuses.map((s) => GestureDetector(
                    onTap: () => setSheetState(() => selectedStatus = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedStatus == s ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary700,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: selectedStatus == s ? context.ksc.accent500 : context.ksc.primary600),
                      ),
                      child: Text(s.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: selectedStatus == s ? context.ksc.accent500 : context.ksc.neutral400,
                          fontWeight: FontWeight.w900,
                        )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                Text("PAYMENT METHOD", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: methods.map((m) => GestureDetector(
                    onTap: () => setSheetState(() => selectedMethod = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedMethod == m ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary700,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: selectedMethod == m ? context.ksc.accent500 : context.ksc.primary600),
                      ),
                      child: Text(
                        m == 'mobile_money' ? 'MOBILE MONEY' : m.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: selectedMethod == m ? context.ksc.accent500 : context.ksc.neutral400,
                          fontWeight: FontWeight.w900,
                        )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.ksc.accent500,
                      foregroundColor: context.ksc.primary900,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: selectedStatus == null ? null : () async {
                      final user = await ref.read(currentUserProvider.future);
                      if (user != null) {
                        await ref.read(jobRepositoryProvider).updatePaymentStatus(job.id, selectedStatus!, selectedMethod, user.id);
                        ref.invalidate(jobDetailProvider(job.id));
                        if (context.mounted) Navigator.pop(ctx);
                      }
                    },
                    child: Text("UPDATE PAYMENT", style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playMedia(BuildContext context, JobPhotoEntity photo) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(photo.storagePath));
    await controller.initialize();
    if (!context.mounted) { controller.dispose(); return; }
    controller.play();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: photo.mediaType == 'audio' ? context.ksc.primary800 : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photo.mediaType == 'video')
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              if (photo.mediaType == 'audio') ...[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.accent500, size: 48),
                      const SizedBox(height: 16),
                      Text("AUDIO RECORDING", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(photo.label?.toUpperCase() ?? "RECORDING", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400)),
                      const SizedBox(height: 20),
                      _AudioPlayerWidget(controller: controller),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () { controller.dispose(); Navigator.of(ctx).pop(); },
                child: const Text("CLOSE"),
              ),
            ],
          ),
        ),
      );
    }
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
