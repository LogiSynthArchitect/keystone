import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../customer_history/data/models/customer_model.dart';

/// A compact dropdown-style customer selector.
///
/// Matches ServicePickerDropdown's visual pattern:
/// icon + label + underline border + value/placeholder row.
/// Tap opens a bottom sheet with customers for selection.
class CustomerPickerDropdown extends StatelessWidget {
  final CustomerModel? selected;
  final List<CustomerModel> customers;
  final ValueChanged<CustomerModel?> onSelected;

  const CustomerPickerDropdown({
    super.key,
    required this.selected,
    required this.customers,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected != null;

    return InkWell(
      onTap: () => _openSheet(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(
              LineAwesomeIcons.user_solid,
              size: 20,
              color: hasSelection
                  ? context.ksc.accent500
                  : context.ksc.neutral500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: hasSelection
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selected!.fullName.toUpperCase(),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: context.ksc.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => onSelected(null),
                                    child: Icon(
                                      LineAwesomeIcons.times_solid,
                                      size: 14,
                                      color: context.ksc.neutral500,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'SELECT CUSTOMER',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: context.ksc.neutral600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LineAwesomeIcons.angle_down_solid,
                        size: 14,
                        color: hasSelection
                            ? context.ksc.accent500
                            : context.ksc.neutral600,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: hasSelection
                      ? context.ksc.accent500
                      : const Color(0xFF2A3A4A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context) {
    if (customers.isEmpty) return;

    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? customers
                : customers
                    .where((c) =>
                        c.fullName.toLowerCase().contains(query) ||
                        c.phoneNumber.toLowerCase().contains(query))
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.ksc.neutral600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("SELECT CUSTOMER",
                              style: AppTextStyles.h2.copyWith(
                                  color: context.ksc.white,
                                  fontWeight: FontWeight.w900)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid,
                              color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: KsSearchBar(
                      hint: "Search customers...",
                      controller: searchCtrl,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Customer list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: KsEmptyState(
                              icon: LineAwesomeIcons.search_solid,
                              title: "No customers found",
                              subtitle: "Try a different search term",
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final customer = filtered[i];
                              final isSelected =
                                  selected?.id == customer.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    onSelected(customer);
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.ksc.accent500
                                            : context.ksc.accent500
                                                .withValues(alpha: 0.25),
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LineAwesomeIcons.user_solid,
                                          size: 20,
                                          color: isSelected
                                              ? context.ksc.accent500
                                              : context.ksc
                                                  .neutral500,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer.fullName
                                                    .toUpperCase(),
                                                style: AppTextStyles
                                                    .bodyMedium
                                                    .copyWith(
                                                  color: isSelected
                                                      ? context.ksc.white
                                                      : context.ksc
                                                          .neutral400,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w900
                                                          : FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                customer.phoneNumber,
                                                style: AppTextStyles
                                                    .caption
                                                    .copyWith(
                                                  color: context
                                                      .ksc.neutral500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                              LineAwesomeIcons
                                                  .check_circle_solid,
                                              size: 18,
                                              color: context
                                                  .ksc.accent500),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
      ),
    ).whenComplete(() => searchCtrl.dispose());
  }
}
