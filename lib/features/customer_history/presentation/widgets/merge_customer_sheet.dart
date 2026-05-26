import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_card.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customer_providers.dart';
import '../../domain/usecases/merge_customers_usecase.dart';

class MergeCustomerSheet extends ConsumerStatefulWidget {
  final CustomerEntity targetCustomer;
  final VoidCallback onMerged;
  const MergeCustomerSheet({super.key, required this.targetCustomer, required this.onMerged});

  @override
  ConsumerState<MergeCustomerSheet> createState() => _MergeCustomerSheetState();
}

class _MergeCustomerSheetState extends ConsumerState<MergeCustomerSheet> {
  final _searchController = TextEditingController();
  List<CustomerEntity> _allCustomers = [];
  List<CustomerEntity> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      final all = await repo.getCustomers();
      setState(() {
        _allCustomers = all.where((c) => c.id != widget.targetCustomer.id).toList();
        _filtered = _allCustomers;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _allCustomers;
      } else {
        final q = query.toLowerCase();
        _filtered = _allCustomers.where((c) =>
          c.fullName.toLowerCase().contains(q) || c.phoneNumber.contains(q),
        ).toList();
      }
    });
  }

  void _selectSource(CustomerEntity source) {
    KsConfirmDialog.show(
      context,
      title: "MERGE CUSTOMERS",
      message: "Merge \"${source.fullName}\" into \"${widget.targetCustomer.fullName}\"?\n\n"
          "All jobs from ${source.fullName} will be reassigned to ${widget.targetCustomer.fullName}. "
          "${source.fullName} will be removed.",
      confirmLabel: "MERGE",
      cancelLabel: "CANCEL",
      isDanger: true,
      onConfirm: () async {
        try {
          await ref.read(mergeCustomersUsecaseProvider).call(MergeCustomersParams(
            targetId: widget.targetCustomer.id,
            sourceId: source.id,
          ));
          if (mounted) {
            Navigator.of(context).pop();
            widget.onMerged();
          }
        } catch (e) {
          if (mounted) {
            KsSlidingNotification.show(context, message: "Merge failed: $e", type: KsNotificationType.error);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.ksc.primary900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Select a customer to merge into ${widget.targetCustomer.fullName}.",
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200),
            ),
          ),
          const SizedBox(height: 16),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: "Search customers...",
                hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
                prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral500, size: 18),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: KsLoadingIndicator())
                : _filtered.isEmpty
                    ? const KsEmptyState(icon: LineAwesomeIcons.search_solid, title: "NO CUSTOMERS FOUND", subtitle: "No other customers to merge.")
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final customer = _filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: KsCard(
                            variant: KsCardVariant.flat,
                            backgroundColor: context.ksc.primary800,
                            onTap: () => _selectSource(customer),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: context.ksc.primary900,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : "?",
                                      style: AppTextStyles.h3.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customer.fullName.toUpperCase(),
                                        style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
                                      ),
                                      Text(customer.phoneNumber,
                                        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral200),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral200, size: 16),
                              ],
                            ),
                          ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
