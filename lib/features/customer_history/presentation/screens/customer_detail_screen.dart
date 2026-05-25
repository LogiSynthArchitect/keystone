import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_card.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_content_drawer.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/router/route_names.dart';
import '../../../job_logging/presentation/screens/log_job_screen.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../../../key_codes/presentation/providers/key_code_provider.dart';
import '../../../key_codes/presentation/screens/edit_key_code_screen.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';
import '../widgets/merge_customer_sheet.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {

  void _confirmDelete(BuildContext context) {
    KsConfirmDialog.show(
      context,
      title: "DELETE CUSTOMER",
      message: "This customer will be removed from your list. Their job history will be preserved but the customer name will no longer be linked to past jobs.",
      confirmLabel: "DELETE",
      cancelLabel: "CANCEL",
      isDanger: true,
      onConfirm: () async {
        try {
          await ref.read(customerRepositoryProvider).deleteCustomer(widget.customerId);
          ref.invalidate(customerListProvider);
          if (context.mounted) {
            context.pop();
            KsSnackbar.show(context, message: "Customer deleted", type: KsSnackbarType.success);
          }
        } catch (_) {
          if (context.mounted) {
            KsSnackbar.show(context, message: "Delete failed", type: KsSnackbarType.error);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final allJobsState = ref.watch(jobListProvider);

    final customerJobs = allJobsState.activeJobs
        .where((j) => j.customerId == widget.customerId)
        .toList()
      ..sort((a, b) => b.jobDate.compareTo(a.jobDate));

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "CUSTOMER DETAILS",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.accent500, size: 22),
            onPressed: () => context.push(RouteNames.editCustomer(widget.customerId)),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.compress_solid, color: context.ksc.neutral200, size: 22),
            onPressed: () {
              final customer = customerAsync.valueOrNull;
              if (customer == null) return;
              KsContentDrawer.show(
                context,
                icon: LineAwesomeIcons.compress_solid,
                title: "MERGE CUSTOMER",
                child: MergeCustomerSheet(
                  targetCustomer: customer,
                  onMerged: () {
                    ref.invalidate(customerListProvider);
                    context.pop();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.trash_alt_solid, color: context.ksc.error500, size: 22),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: customerAsync.when(
              loading: () => const Center(child: KsLoadingIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 48, color: context.ksc.error500),
                    const SizedBox(height: 16),
                    Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text("Could not load customer.", style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
                    const SizedBox(height: 24),
                    KsButton(
                      label: "TAP TO RETRY",
                      onPressed: () => ref.invalidate(customerDetailProvider(widget.customerId)),
                      size: KsButtonSize.small,
                      fullWidth: false,
                    ),
                  ],
                ),
              ),
              data: (customer) {
                if (customer == null) {
                  return const Center(child: KsEmptyState(icon: LineAwesomeIcons.user_slash_solid, title: "CUSTOMER NOT FOUND"));
                }

                final lifetimeRevenue = customerJobs.fold<int>(0, (sum, j) => sum + (j.amountCharged ?? 0));

                final frequentBrands = customerJobs
                    .where((j) => j.hardwareBrand != null && j.hardwareBrand!.isNotEmpty)
                    .map((j) => j.hardwareBrand!)
                    .toSet()
                    .toList()
                  ..sort();

                final frequentParts = <String>{};
                for (final j in customerJobs) {
                  final parts = ref.watch(jobPartsProvider(j.id)).valueOrNull ?? [];
                  for (final p in parts) {
                    if (p.partName.isNotEmpty) frequentParts.add(p.partName);
                  }
                }
                final sortedParts = frequentParts.toList()..sort();

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      // Header section
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildProfileModule(context, customer),
                            const SizedBox(height: 16),
                            _buildStatsRow(context, customer, customerJobs.length, lifetimeRevenue),
                            if (frequentBrands.isNotEmpty || sortedParts.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildFrequentPartsChips(frequentBrands, sortedParts),
                            ],
                          ],
                        ),
                      ),
                      // Hub action tiles
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _buildActionTiles(context, customer, customerJobs),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        color: context.ksc.accent500,
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => LogJobScreen.show(context, preSelectedCustomerId: widget.customerId),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LOG NEW JOB', style: AppTextStyles.h2.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    Icon(LineAwesomeIcons.plus_circle_solid, color: context.ksc.primary900, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Hub action tiles
  // ──────────────────────────────────────────────────────────────

  Widget _buildActionTiles(BuildContext context, CustomerEntity customer, List<JobEntity> customerJobs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                iconPath: 'assets/icons/3d/transparent/778c78-key.png',
                label: "KEY CODES",
                subtitle: "Gates, remotes, safes",
                onTap: () => _showKeyCodesSheet(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                iconPath: 'assets/icons/3d/transparent/8ef1fa-clock.png',
                label: "SERVICE HISTORY",
                subtitle: "${customerJobs.length} visit${customerJobs.length == 1 ? '' : 's'}",
                onTap: () => _showServiceHistorySheet(context, customer, customerJobs),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                iconPath: 'assets/icons/3d/transparent/628100-notebook.png',
                label: "NOTES",
                subtitle: customer.notes?.isNotEmpty == true ? "Tap to view" : "Add notes",
                onTap: () => _showNotesSheet(context, customer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                iconPath: 'assets/icons/3d/transparent/f32794-calendar.png',
                label: "SCHEDULE",
                subtitle: "Recurring visits",
                onTap: () => _showScheduleSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Bottom sheets
  // ──────────────────────────────────────────────────────────────

  void _showKeyCodesSheet(BuildContext context) {
    KsContentDrawer.show(
      context,
      icon: LineAwesomeIcons.key_solid,
      title: "KEY CODES",
      child: Consumer(
        builder: (context, ref, _) {
          final sheetState = ref.watch(keyCodeProvider(widget.customerId));
          return _KeyCodesTab(customerId: widget.customerId, keyCodeState: sheetState);
        },
      ),
      bottomLabel: "ADD KEY CODE",
      bottomIcon: LineAwesomeIcons.plus_solid,
      bottomOnPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EditKeyCodeScreen(customerId: widget.customerId),
      )),
    );
  }

  void _showServiceHistorySheet(BuildContext context, CustomerEntity customer, List<JobEntity> jobs) {
    KsContentDrawer.show(
      context,
      icon: LineAwesomeIcons.history_solid,
      title: "SERVICE HISTORY",
      child: _ServiceHistoryTab(customer: customer, jobs: jobs),
    );
  }

  void _showNotesSheet(BuildContext context, CustomerEntity customer) {
    final controller = TextEditingController(text: customer.notes ?? '');
    KsContentDrawer.show(
      context,
      icon: LineAwesomeIcons.sticky_note_solid,
      title: "NOTES",
      heightFactor: 0.55,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: AppTextStyles.body.copyWith(color: context.ksc.white),
          decoration: InputDecoration(
            hintText: "Add notes about this customer...",
            hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral600),
            filled: false,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.accent500, width: 1.5),
            ),
          ),
        ),
      ),
      bottomLabel: "SAVE NOTES",
      bottomIcon: LineAwesomeIcons.check_solid,
      bottomOnPressed: () async {
        try {
          await ref.read(customerRepositoryProvider).updateCustomer(
            customer.copyWith(notes: controller.text.trim()),
          );
          ref.invalidate(customerDetailProvider(widget.customerId));
          if (context.mounted) Navigator.pop(context);
        } catch (_) {
          if (context.mounted) {
            KsSnackbar.show(context, message: "Failed to save notes", type: KsSnackbarType.error);
          }
        }
      },
    );
  }

  void _showScheduleSheet(BuildContext context) {
    KsContentDrawer.show(
      context,
      icon: LineAwesomeIcons.calendar_solid,
      title: "RECURRING SCHEDULE",
      heightFactor: 0.45,
      child: KsEmptyState(
        icon: LineAwesomeIcons.calendar_solid,
        title: "COMING SOON",
        subtitle: "Schedule recurring maintenance visits.",
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Header widgets
  // ──────────────────────────────────────────────────────────────

  Widget _buildProfileModule(BuildContext context, CustomerEntity customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: context.ksc.primary900, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: Center(child: Text(customer.fullName[0].toUpperCase(), style: AppTextStyles.h1.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(customer.fullName.toUpperCase(), style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                    if (customer.propertyType != null)
                      _PropertyBadge(type: customer.propertyType!),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => WhatsAppLauncher.openChat(
                    phoneNumber: customer.phoneNumber,
                    message: "Hello ${customer.fullName.split(' ').first},",
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(customer.phoneNumber, style: AppTextStyles.body.copyWith(color: context.ksc.neutral200, fontWeight: FontWeight.w600))),
                      Icon(LineAwesomeIcons.whatsapp, size: 14, color: context.ksc.success500),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                if (customer.leadSource != null) ...[
                  const SizedBox(height: 2),
                  Text("Via: ${_leadSourceLabel(customer.leadSource!)}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200, fontSize: 10)),
                ],
                if (customer.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LineAwesomeIcons.map_marker_solid, size: 12, color: context.ksc.accent500),
                      const SizedBox(width: 4),
                      Expanded(child: Text(customer.location!.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200, fontWeight: FontWeight.w800, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
                if (customer.notes != null && customer.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(LineAwesomeIcons.sticky_note_solid, size: 12, color: context.ksc.neutral200),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(customer.notes!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200), maxLines: 3, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, CustomerEntity customer, int jobCount, int lifetimeRevenue) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(color: context.ksc.primary800.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(context, "TOTAL JOBS", jobCount.toString().padLeft(2, '0')),
          Container(width: 1, height: 20, color: context.ksc.primary700),
          _stat(context, "LAST VISIT", customer.lastJobAt != null ? DateFormatter.relative(customer.lastJobAt!).toUpperCase() : "NONE"),
          Container(width: 1, height: 20, color: context.ksc.primary700),
          _statValue(context, "LIFETIME REVENUE", CurrencyFormatter.formatShort(lifetimeRevenue)),
        ],
      ),
    );
  }

  Widget _statValue(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    ],
  );

  Widget _stat(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    ],
  );

  Widget _buildFrequentPartsChips(List<String> brands, List<String> parts) {
    if (brands.isEmpty && parts.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.ksc.accent500.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineAwesomeIcons.tools_solid, size: 14, color: context.ksc.accent500),
              const SizedBox(width: 8),
              Text("COMMONLY USED", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          if (brands.isNotEmpty) ...[
            Text("BRANDS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200, fontWeight: FontWeight.w800, fontSize: 9)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: brands.map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: context.ksc.accent500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3))),
                child: Text(b.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 9)),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (parts.isNotEmpty) ...[
            Text("PARTS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200, fontWeight: FontWeight.w800, fontSize: 9)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: parts.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: context.ksc.accent500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3))),
                child: Text(p.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 9)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _leadSourceLabel(String key) {
    const map = {
      'word_of_mouth': 'Word of Mouth', 'google_maps': 'Google Maps',
      'referral': 'Referral', 'physical_card': 'Physical Card',
      'whatsapp': 'WhatsApp', 'other': 'Other',
    };
    return map[key] ?? key;
  }
}

// ──────────────────────────────────────────────────────────────
// Property badge
// ──────────────────────────────────────────────────────────────

class _PropertyBadge extends StatelessWidget {
  final String type;
  const _PropertyBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'residential' => ('RESIDENTIAL', context.ksc.success500),
      'commercial'  => ('COMMERCIAL',  context.ksc.warning500),
      _             => ('AUTOMOTIVE',  context.ksc.neutral500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Key Codes tab content (used inside bottom sheet)
// ──────────────────────────────────────────────────────────────

class _KeyCodesTab extends ConsumerWidget {
  final String customerId;
  final KeyCodeState keyCodeState;
  const _KeyCodesTab({required this.customerId, required this.keyCodeState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (keyCodeState.isLoading) {
      return const Center(child: KsLoadingIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: keyCodeState.entries.isEmpty
              ? const Center(
                  child: KsEmptyState(
                    icon: LineAwesomeIcons.key_solid,
                    title: "NO KEY CODES YET",
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keyCodeState.entries.length,
                  itemBuilder: (context, i) {
                    final entry = keyCodeState.entries[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: KsCard(
                        variant: KsCardVariant.flat,
                        backgroundColor: context.ksc.primary800,
                        padding: const EdgeInsets.all(12),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => EditKeyCodeScreen(customerId: customerId, existing: entry),
                        )),
                        child: Row(
                          children: [
                            Icon(LineAwesomeIcons.key_solid, size: 16, color: context.ksc.accent500),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.keyCode.toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (entry.keyType != null)
                                        _buildBadge(context, entry.keyType!, context.ksc.accent500),
                                      if (entry.bitting != null) ...[
                                        const SizedBox(width: 6),
                                        _buildBadge(context, entry.bitting!, context.ksc.neutral400),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral500, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Service History tab content (used inside bottom sheet)
// ──────────────────────────────────────────────────────────────

class _ServiceHistoryTab extends StatelessWidget {
  final CustomerEntity customer;
  final List<JobEntity> jobs;
  const _ServiceHistoryTab({required this.customer, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final totalAmount = jobs.fold<int>(0, (sum, j) => sum + (j.amountCharged ?? 0));

    return Column(
      children: [
        if (jobs.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: context.ksc.primary800.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("TOTAL VISITS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10, fontWeight: FontWeight.w800)),
                  Text("${jobs.length}", style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("TOTAL SPENT", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10, fontWeight: FontWeight.w800)),
                  Text(CurrencyFormatter.formatShort(totalAmount), style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                ]),
              ],
            ),
          ),
        Expanded(
          child: jobs.isEmpty
              ? const Center(
                  child: KsEmptyState(
                    icon: LineAwesomeIcons.history_solid,
                    title: "NO SERVICE RECORDS",
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, i) => _buildTimelineItem(context, jobs[i], i == 0, i == jobs.length - 1),
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, JobEntity job, bool isFirst, bool isLast) {
    final statusColor = switch (job.status) {
      'completed' || 'invoiced' => context.ksc.success500,
      'in_progress' => context.ksc.accent500,
      _ => context.ksc.neutral500,
    };
    final paymentColor = switch (job.paymentStatus) {
      'paid' => context.ksc.success500,
      'partial' => context.ksc.warning500,
      _ => context.ksc.error500,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: context.ksc.primary700))
                else
                  const Expanded(child: SizedBox.shrink()),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, border: Border.all(color: context.ksc.primary800, width: 2)),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: context.ksc.primary700))
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(RouteNames.jobDetail(job.id)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(DateFormatter.relative(job.jobDate).toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: paymentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
                                child: Text(job.paymentStatus.toUpperCase(), style: AppTextStyles.caption.copyWith(color: paymentColor, fontWeight: FontWeight.w900, fontSize: 7, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(job.serviceType.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    if (job.hasAmount)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(CurrencyFormatter.formatShort(job.amountCharged!), style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontFeatures: [const FontFeature.tabularFigures()])),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Hub action tile widget
// ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.iconPath,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 56,
                child: Image.asset(iconPath, height: 48, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              Text(label, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
