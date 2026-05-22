import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../../core/widgets/ks_step_indicator.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/inventory_providers.dart';
import '../../domain/entities/inventory_item_entity.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _filter = 'all';
  String _locationFilter = 'all';
  bool _showArchived = false;
  bool _groupByLocation = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  void _loadItems() {
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId != null) {
      ref.read(inventoryProvider.notifier).loadItems(userId, includeArchived: _showArchived);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _locations(List<InventoryItemEntity> items) {
    final locs = items.map((i) => i.location).whereType<String>().toSet().toList()..sort();
    return locs;
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final currentType = _filter;
    final currentLocation = _locationFilter;
    final allItems = ref.read(inventoryProvider).maybeWhen(
      data: (d) => d,
      orElse: () => <InventoryItemEntity>[],
    );
    final locs = _locations(allItems);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        var draftType = currentType;
        var draftLocation = currentLocation;
        return StatefulBuilder(
          builder: (context, setInnerState) => KsFilterSheet(
            title: "FILTER INVENTORY",
            onApply: () {
              setState(() {
                _filter = draftType;
                _locationFilter = draftLocation;
              });
            },
            onClear: () {
              draftType = 'all';
              draftLocation = 'all';
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "TYPE",
                selected: draftType,
                onSelect: (v) => setInnerState(() { if (v != null) draftType = v; }),
                options: const [
                  KsFilterOption(value: 'all', display: 'ALL'),
                  KsFilterOption(value: 'part', display: 'PARTS'),
                  KsFilterOption(value: 'hardware', display: 'HARDWARE'),
                ],
              ),
              if (locs.isNotEmpty)
                KsFilterChipGroup(
                  label: "LOCATION",
                  selected: draftLocation,
                  onSelect: (v) => setInnerState(() { if (v != null) draftLocation = v; }),
                  options: [
                    const KsFilterOption(value: 'all', display: 'ALL LOCATIONS'),
                    ...locs.map((l) => KsFilterOption(value: l, display: l.toUpperCase())),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  List<InventoryItemEntity> _filtered(List<InventoryItemEntity> items) {
    var result = items;
    if (_filter == 'part') {
      result = result.where((i) => i.itemType == 'part').toList();
    } else if (_filter == 'hardware') {
      result = result.where((i) => i.itemType == 'hardware').toList();
    }
    if (_locationFilter != 'all') {
      result = result.where((i) => i.location == _locationFilter).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((i) =>
        i.name.toLowerCase().contains(query) ||
        (i.brand?.toLowerCase().contains(query) ?? false) ||
        (i.category?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    if (!_showArchived) {
      result = result.where((i) => !i.isArchived).toList();
    }
    return result;
  }

  void _showStockDialog(InventoryItemEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        final qtyCtrl = TextEditingController();
        final reasonCtrl = TextEditingController();
        String mode = 'add';

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("STOCK: ${item.name.toUpperCase()}", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text("Current: ${item.quantity}", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _stockModeChip(setSheetState, 'add', 'ADD', mode, (v) => mode = v),
                      const SizedBox(width: 8),
                      _stockModeChip(setSheetState, 'remove', 'REMOVE', mode, (v) => mode = v),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sheetField("QUANTITY", qtyCtrl, isNumeric: true),
                  const SizedBox(height: 16),
                  _sheetField("REASON (optional)", reasonCtrl),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mode == 'add' ? context.ksc.accent500 : context.ksc.error500,
                        foregroundColor: context.ksc.primary900,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () async {
                        final qty = int.tryParse(qtyCtrl.text.trim());
                        if (qty == null || qty <= 0) return;
                        final change = mode == 'add' ? qty : -qty;
                        await ref.read(inventoryProvider.notifier).adjustStock(
                          itemId: item.id,
                          quantityChange: change,
                          adjustmentType: mode == 'add' ? 'manual_add' : 'manual_remove',
                          reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          KsSnackbar.show(context, message: "Stock updated", type: KsSnackbarType.success);
                        }
                      },
                      child: Text(
                        mode == 'add' ? "ADD STOCK" : "REMOVE STOCK",
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _stockModeChip(StateSetter setState, String value, String label, String current, ValueChanged<String> onChanged) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => setState(() => onChanged(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (value == 'add' ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.error500.withValues(alpha: 0.1)) : context.ksc.primary700,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? (value == 'add' ? context.ksc.accent500 : context.ksc.error500) : context.ksc.primary700),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(
          color: isSelected ? (value == 'add' ? context.ksc.accent500 : context.ksc.error500) : context.ksc.neutral400,
          fontWeight: FontWeight.w900,
        )),
      ),
    );
  }

  void _showRestockDialog(InventoryItemEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        final qtyCtrl = TextEditingController();
        final costCtrl = TextEditingController();
        final vendorCtrl = TextEditingController();
        final phoneCtrl = TextEditingController();
        final notesCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RESTOCK: ${item.name.toUpperCase()}", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  _sheetField("QUANTITY *", qtyCtrl, isNumeric: true),
                  const SizedBox(height: 16),
                  _sheetField("UNIT COST (GHS) *", costCtrl, isNumeric: true),
                  const SizedBox(height: 16),
                  _sheetField("VENDOR", vendorCtrl),
                  const SizedBox(height: 16),
                  _sheetField("SUPPLIER PHONE", phoneCtrl),
                  const SizedBox(height: 16),
                  _sheetField("NOTES", notesCtrl),
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
                      onPressed: () async {
                        final qty = int.tryParse(qtyCtrl.text.trim());
                        final cost = CurrencyFormatter.parseToPesewas(costCtrl.text.trim());
                        if (qty == null || qty <= 0 || cost == null) return;
                        await ref.read(inventoryProvider.notifier).restockItem(
                          itemId: item.id,
                          quantity: qty,
                          unitCost: cost,
                          vendor: vendorCtrl.text.trim().isEmpty ? null : vendorCtrl.text.trim(),
                          supplierPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          KsSnackbar.show(context, message: "Restock recorded", type: KsSnackbarType.success);
                        }
                      },
                      child: Text(
                        "RECORD RESTOCK",
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showHistoryDialog(InventoryItemEntity item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        return FutureBuilder(
          future: Future.wait([
            ref.read(inventoryProvider.notifier).getStockAdjustments(item.id),
            ref.read(inventoryProvider.notifier).getRestocks(item.id),
          ]),
          builder: (ctx, AsyncSnapshot<List<dynamic>> snapshot) {
            final adjustments = snapshot.data?[0] as List? ?? [];
            final restocks = snapshot.data?[1] as List? ?? [];
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("HISTORY: ${item.name.toUpperCase()}", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: adjustments.isEmpty && restocks.isEmpty
                          ? Center(child: Text("No history yet", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)))
                          : ListView(
                              controller: scrollController,
                              children: [
                                ...restocks.map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: context.ksc.primary700, borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    children: [
                                      Icon(LineAwesomeIcons.truck_solid, color: context.ksc.accent500, size: 16),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("RESTOCK +${r.quantity} @ ${CurrencyFormatter.format(r.unitCost)}/ea", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700)),
                                            if (r.vendor != null) Text("Vendor: ${r.vendor}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                                          ],
                                        ),
                                      ),
                                      Text("Total: ${CurrencyFormatter.format(r.totalCost)}", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500)),
                                    ],
                                  ),
                                )),
                                ...adjustments.map((a) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: context.ksc.primary700, borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    children: [
                                      Icon(
                                        a.quantityChange > 0 ? LineAwesomeIcons.plus_circle_solid : LineAwesomeIcons.minus_circle_solid,
                                        color: a.quantityChange > 0 ? context.ksc.success500 : context.ksc.error500,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("${a.adjustmentType.replaceAll('_', ' ').toUpperCase()} ${a.quantityChange >= 0 ? '+' : ''}${a.quantityChange} → ${a.quantityAfter}", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700)),
                                            if (a.reason != null) Text(a.reason!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MY INVENTORY",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.filter_solid,
              color: _filter != 'all' || _locationFilter != 'all' ? context.ksc.accent500 : context.ksc.neutral400,
              size: 22),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: Icon(_showArchived ? LineAwesomeIcons.archive_solid : LineAwesomeIcons.archive_solid, color: _showArchived ? context.ksc.accent500 : context.ksc.neutral400, size: 20),
            tooltip: "Toggle archived",
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
            },
          ),
          IconButton(
            icon: Icon(_groupByLocation ? LineAwesomeIcons.layer_group_solid : LineAwesomeIcons.layer_group_solid, color: _groupByLocation ? context.ksc.accent500 : context.ksc.neutral400, size: 20),
            tooltip: "Group by location",
            onPressed: () => setState(() => _groupByLocation = !_groupByLocation),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: KsSearchBar(
              hint: "Search items...",
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          ),
        ),
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
                    Text("FAILED TO LOAD", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadItems,
                      child: Text("TAP TO RETRY", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                    ),
                  ],
                ),
              ),
              data: (items) {
                final filtered = _filtered(items);
                if (items.isEmpty) {
                  return const KsEmptyState(
                    icon: LineAwesomeIcons.box_open_solid,
                    title: "NO ITEMS YET",
                    subtitle: "Tap + to add your first item",
                  );
                }
                if (filtered.isEmpty) {
                  return const KsEmptyState(
                    icon: LineAwesomeIcons.search_minus_solid,
                    title: "NO MATCHES",
                    subtitle: "No items match the current filter.",
                  );
                }
                if (_groupByLocation) {
                  final grouped = <String, List<InventoryItemEntity>>{};
                  for (final item in filtered) {
                    final loc = item.location ?? '(No Location)';
                    grouped.putIfAbsent(loc, () => []).add(item);
                  }
                  final sortedKeys = grouped.keys.toList()..sort();
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: sortedKeys.map((loc) {
                      final locItems = grouped[loc]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(LineAwesomeIcons.map_pin_solid, color: context.ksc.accent500, size: 14),
                                const SizedBox(width: 8),
                                Text(loc.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                const Spacer(),
                                Text("${locItems.length} items", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                              ],
                            ),
                          ),
                          ...locItems.map((i) => _buildItemCard(i)),
                        ],
                      );
                    }).toList(),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildItemCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
    );
  }

  Widget _buildItemCard(InventoryItemEntity item) {
    final isPart = item.itemType == 'part';
    final isLow = item.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLow ? context.ksc.warning500.withValues(alpha: 0.5) : context.ksc.primary700,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDialog(item: item),
          onLongPress: () => _confirmDelete(item),
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: Image.network(item.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPart ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isPart ? LineAwesomeIcons.cogs_solid : LineAwesomeIcons.lock_solid,
                        color: isPart ? context.ksc.accent500 : context.ksc.primary500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(item.name.toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                              ),
                              if (item.isArchived)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: context.ksc.neutral500.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                                  child: Text("ARCHIVED", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9, fontWeight: FontWeight.w800)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.brand != null) ...[
                                Text(item.brand!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w600)),
                                if (item.category != null) Text(" · ", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                              ],
                              if (item.category != null) Text(item.category!.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuantityBadge(item.quantity, isLow),
                    if (item.location != null) ...[
                      const SizedBox(width: 8),
                      Icon(LineAwesomeIcons.map_pin_solid, color: context.ksc.neutral500, size: 12),
                      const SizedBox(width: 4),
                      Text(item.location!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                    ],
                    const Spacer(),
                    if (item.isAutoCogs)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: context.ksc.primary500.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                        child: Text("AUTO-COGS", style: AppTextStyles.caption.copyWith(color: context.ksc.primary500, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showStockDialog(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.ksc.accent500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LineAwesomeIcons.plus_solid, color: context.ksc.accent500, size: 12),
                            const SizedBox(width: 4),
                            Text("ADJUST", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showRestockDialog(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.ksc.primary500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LineAwesomeIcons.truck_solid, color: context.ksc.primary500, size: 12),
                            const SizedBox(width: 4),
                            Text("RESTOCK", style: AppTextStyles.caption.copyWith(color: context.ksc.primary500, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showHistoryDialog(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.ksc.neutral500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LineAwesomeIcons.history_solid, color: context.ksc.neutral400, size: 12),
                            const SizedBox(width: 4),
                            Text("HISTORY", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    if (isLow && !item.isLowStockSnoozed) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final now = DateTime.now();
                          final snoozeUntil = DateTime(now.year, now.month, now.day + 3);
                          ref.read(inventoryProvider.notifier).updateItem(
                            item.copyWith(snoozeLowStockUntil: snoozeUntil),
                          );
                          KsSnackbar.show(context, message: "Low stock alert snoozed until ${snoozeUntil.day}/${snoozeUntil.month}", type: KsSnackbarType.success);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.ksc.warning500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LineAwesomeIcons.bell_solid, color: context.ksc.warning500, size: 12),
                              const SizedBox(width: 4),
                              Text("SNOOZE", style: AppTextStyles.caption.copyWith(color: context.ksc.warning500, fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (item.defaultSalePrice != null)
                      Text(CurrencyFormatter.format(item.defaultSalePrice!), style: AppTextStyles.body.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
  );
  }

  Widget _buildQuantityBadge(int qty, bool isLow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLow ? context.ksc.warning500.withValues(alpha: 0.15) : context.ksc.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isLow ? context.ksc.warning500.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? LineAwesomeIcons.exclamation_triangle_solid : LineAwesomeIcons.boxes_solid,
            color: isLow ? context.ksc.warning500 : context.ksc.neutral400,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            "$qty in stock",
            style: AppTextStyles.caption.copyWith(
              color: isLow ? context.ksc.warning500 : context.ksc.neutral400,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(InventoryItemEntity item) {
    KsConfirmDialog.show(
      context,
      title: "DELETE ITEM",
      message: "Remove \"${item.name}\" from your inventory?",
      confirmLabel: "DELETE",
      cancelLabel: "CANCEL",
      isDanger: true,
      onConfirm: () {
        ref.read(inventoryProvider.notifier).deleteItem(item.id);
        KsSnackbar.show(context, message: "Item deleted", type: KsSnackbarType.success);
      },
    );
  }

  void _showItemDialog({InventoryItemEntity? item}) {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final brandCtrl = TextEditingController(text: item?.brand ?? '');
    final modelCtrl = TextEditingController(text: item?.model ?? '');
    final keySpecCtrl = TextEditingController(text: item?.keySpec ?? '');
    final materialCtrl = TextEditingController(text: item?.material ?? '');
    final finishCtrl = TextEditingController(text: item?.finish ?? '');
    final dimsCtrl = TextEditingController(text: item?.dimensions ?? '');
    final costCtrl = TextEditingController(text: item?.defaultCostPrice != null ? (item!.defaultCostPrice! / 100.0).toStringAsFixed(2) : '');
    final saleCtrl = TextEditingController(text: item?.defaultSalePrice != null ? (item!.defaultSalePrice! / 100.0).toStringAsFixed(2) : '');

    String itemType = item?.itemType ?? 'part';
    String? category = item?.category;
    bool isAutoCogs = item?.isAutoCogs ?? false;
    int stockQty = item?.quantity ?? 0;
    int stockThreshold = item?.lowStockThreshold ?? 0;
    String stockLocation = item?.location ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            int currentStep = 0;

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
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(child: Text(isEditing ? "EDIT ITEM" : "ADD ITEM",
                          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900))),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Step indicator
                  KsStepIndicator(
                    currentStep: currentStep,
                    totalSteps: 3,
                    labels: ['GENERAL', 'SPECS', 'STOCK'],
                  ),
                  const SizedBox(height: 4),
                  // Step content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.3, 0), end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                      child: _buildStepContent(currentStep, nameCtrl, brandCtrl, modelCtrl, keySpecCtrl, materialCtrl, finishCtrl, dimsCtrl, costCtrl, saleCtrl, itemType, category, isAutoCogs, setSheetState, stockQty, stockThreshold, stockLocation),
                    ),
                  ),
                  // Bottom navigation bar
                  _buildStepNavBar(currentStep, setSheetState, isEditing, nameCtrl, item, ctx, costCtrl, saleCtrl, stockQty, stockThreshold, stockLocation, itemType, category, isAutoCogs, brandCtrl, modelCtrl, keySpecCtrl, materialCtrl, finishCtrl, dimsCtrl),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepContent(int step, TextEditingController nameCtrl, TextEditingController brandCtrl, TextEditingController modelCtrl, TextEditingController keySpecCtrl, TextEditingController materialCtrl, TextEditingController finishCtrl, TextEditingController dimsCtrl, TextEditingController costCtrl, TextEditingController saleCtrl, String itemType, String? category, bool isAutoCogs, StateSetter setSheetState, int stockQty, int stockThreshold, String stockLocation) {
    switch (step) {
      case 0:
        return SingleChildScrollView(
          key: const ValueKey('general'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetField("NAME *", nameCtrl),
              const SizedBox(height: 16),
              // AUTO-COGS toggle row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("AUTO-COGS", style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
                          const SizedBox(height: 2),
                          Text("Auto-deduct from job revenue", style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral600, fontSize: 9)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAutoCogs,
                      onChanged: (v) => setSheetState(() => isAutoCogs = v),
                      activeThumbColor: context.ksc.accent500,
                      activeTrackColor: context.ksc.accent500.withValues(alpha: 0.3),
                      inactiveThumbColor: context.ksc.neutral500,
                      inactiveTrackColor: context.ksc.primary700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // TYPE chips
              Text("TYPE", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Row(children: [
                _buildTabChip(setSheetState, 'part', 'PART', itemType, (v) => itemType = v),
                const SizedBox(width: 8),
                _buildTabChip(setSheetState, 'hardware', 'HARDWARE', itemType, (v) => itemType = v),
              ]),
              const SizedBox(height: 16),
              // CATEGORY
              Text("CATEGORY", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: category,
                    dropdownColor: context.ksc.primary800,
                    isExpanded: true,
                    hint: Text("Select category", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
                    icon: Icon(LineAwesomeIcons.angle_down_solid, color: context.ksc.neutral500, size: 14),
                    items: ['deadbolt', 'knob_lock', 'cylinder', 'key_blank', 'remote_fob', 'transponder', 'padlock', 'smart_lock', 'mortise_lock', 'panic_bar', 'kik_cylinder', 'door_closer', 'cabinet_lock', 'safe_lock', 'screw', 'spring', 'misc'].map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.replaceAll('_', ' ').toUpperCase(),
                        style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600)),
                    )).toList(),
                    onChanged: (v) => setSheetState(() => category = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sheetField("BRAND", brandCtrl, leadingIcon: LineAwesomeIcons.tag_solid),
              const SizedBox(height: 16),
              _sheetField("MODEL", modelCtrl, leadingIcon: LineAwesomeIcons.barcode_solid),
              const SizedBox(height: 24),
            ],
          ),
        );
      case 1:
        return SingleChildScrollView(
          key: const ValueKey('specs'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetField("KEY SPEC", keySpecCtrl, leadingIcon: LineAwesomeIcons.key_solid),
              const SizedBox(height: 16),
              _sheetField("MATERIAL", materialCtrl, leadingIcon: LineAwesomeIcons.archive_solid),
              const SizedBox(height: 16),
              _sheetField("FINISH", finishCtrl, leadingIcon: LineAwesomeIcons.palette_solid),
              const SizedBox(height: 16),
              _sheetField("DIMENSIONS", dimsCtrl, leadingIcon: LineAwesomeIcons.expand_arrows_alt_solid),
              const SizedBox(height: 24),
            ],
          ),
        );
      case 2:
        return SingleChildScrollView(
          key: const ValueKey('stock'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetField("COST PRICE (GHS)", costCtrl, isAmount: true),
              const SizedBox(height: 16),
              _sheetField("SALE PRICE (GHS)", saleCtrl, isAmount: true),
              const SizedBox(height: 16),
              Text("QUANTITY", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setSheetState(() { if (stockQty > 0) stockQty--; }),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.ksc.primary900, borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(LineAwesomeIcons.minus_solid, size: 16, color: context.ksc.accent500),
                      ),
                    ),
                    const Spacer(),
                    Text("$stockQty", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 22)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setSheetState(() => stockQty++),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.ksc.primary900, borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(LineAwesomeIcons.plus_solid, size: 16, color: context.ksc.accent500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text("LOW STOCK THRESHOLD", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text("0", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
                    Expanded(
                      child: Slider(
                        value: stockThreshold.toDouble(),
                        min: 0, max: 100, divisions: 100,
                        activeColor: context.ksc.accent500,
                        inactiveColor: context.ksc.primary700,
                        onChanged: (v) => setSheetState(() => stockThreshold = v.round()),
                      ),
                    ),
                    Text("$stockThreshold", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text("LOCATION", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Row(children: [
                _buildTabChip(setSheetState, 'van', 'VAN', stockLocation, (v) => stockLocation = v),
                const SizedBox(width: 8),
                _buildTabChip(setSheetState, 'workshop', 'WORKSHOP', stockLocation, (v) => stockLocation = v),
                const SizedBox(width: 8),
                _buildTabChip(setSheetState, 'other', 'OTHER', stockLocation, (v) => stockLocation = v),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepNavBar(int currentStep, StateSetter setSheetState, bool isEditing, TextEditingController nameCtrl, InventoryItemEntity? item, BuildContext ctx, TextEditingController costCtrl, TextEditingController saleCtrl, int stockQty, int stockThreshold, String stockLocation, String itemType, String? category, bool isAutoCogs, TextEditingController brandCtrl, TextEditingController modelCtrl, TextEditingController keySpecCtrl, TextEditingController materialCtrl, TextEditingController finishCtrl, TextEditingController dimsCtrl) {
    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(top: BorderSide(color: context.ksc.primary700)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          // BACK button
          if (currentStep > 0)
            Expanded(
              child: KsButton(
                label: "BACK",
                onPressed: () => setSheetState(() => currentStep--),
                variant: KsButtonVariant.ghost,
                leadingIcon: LineAwesomeIcons.angle_left_solid,
                size: KsButtonSize.small,
                fullWidth: true,
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          // NEXT or SAVE
          Expanded(
            flex: currentStep == 0 ? 1 : 2,
            child: currentStep < 2
                ? KsButton(
                    label: "NEXT",
                    onPressed: nameCtrl.text.trim().isEmpty && currentStep == 0 ? null : () => setSheetState(() => currentStep++),
                    variant: KsButtonVariant.secondary,
                    trailingIcon: LineAwesomeIcons.angle_right_solid,
                    size: KsButtonSize.small,
                    fullWidth: true,
                  )
                : KsButton(
                    label: isEditing ? "SAVE CHANGES" : "ADD ITEM",
                    onPressed: nameCtrl.text.trim().isEmpty ? null : () async {
                      final notifier = ref.read(inventoryProvider.notifier);
                      if (isEditing) {
                        await notifier.updateItem(item!.copyWith(
                          name: nameCtrl.text.trim(),
                          itemType: itemType,
                          category: category,
                          brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                          model: modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
                          keySpec: keySpecCtrl.text.trim().isEmpty ? null : keySpecCtrl.text.trim(),
                          material: materialCtrl.text.trim().isEmpty ? null : materialCtrl.text.trim(),
                          finish: finishCtrl.text.trim().isEmpty ? null : finishCtrl.text.trim(),
                          dimensions: dimsCtrl.text.trim().isEmpty ? null : dimsCtrl.text.trim(),
                          defaultCostPrice: CurrencyFormatter.parseToPesewas(costCtrl.text.trim()),
                          defaultSalePrice: CurrencyFormatter.parseToPesewas(saleCtrl.text.trim()),
                          quantity: stockQty,
                          lowStockThreshold: stockThreshold > 0 ? stockThreshold : null,
                          location: stockLocation.isEmpty ? null : stockLocation,
                          isAutoCogs: isAutoCogs,
                        ));
                      } else {
                        await notifier.addItem(
                          itemType: itemType,
                          name: nameCtrl.text.trim(),
                          category: category,
                          brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                          model: modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
                          keySpec: keySpecCtrl.text.trim().isEmpty ? null : keySpecCtrl.text.trim(),
                          material: materialCtrl.text.trim().isEmpty ? null : materialCtrl.text.trim(),
                          finish: finishCtrl.text.trim().isEmpty ? null : finishCtrl.text.trim(),
                          dimensions: dimsCtrl.text.trim().isEmpty ? null : dimsCtrl.text.trim(),
                          defaultCostPrice: CurrencyFormatter.parseToPesewas(costCtrl.text.trim()),
                          defaultSalePrice: CurrencyFormatter.parseToPesewas(saleCtrl.text.trim()),
                          quantity: stockQty,
                          lowStockThreshold: stockThreshold > 0 ? stockThreshold : null,
                          location: stockLocation.isEmpty ? null : stockLocation,
                          isAutoCogs: isAutoCogs,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        KsSnackbar.show(context, message: isEditing ? "Item updated" : "Item added", type: KsSnackbarType.success);
                      }
                    },
                    variant: KsButtonVariant.cta,
                    trailingIcon: LineAwesomeIcons.save_solid,
                    size: KsButtonSize.small,
                    fullWidth: true,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(StateSetter setState, String value, String label, String current, ValueChanged<String> onChanged) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => setState(() => onChanged(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary800,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700, width: isSelected ? 1.5 : 1),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(
          color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        )),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController controller, {bool isNumeric = false, bool isAmount = false, IconData? leadingIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: controller,
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
              style: AppTextStyles.body.copyWith(color: context.ksc.white),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: isNumeric ? "0" : isAmount ? "0.00" : "Enter...",
                hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
                prefixIcon: leadingIcon != null ? Icon(leadingIcon, color: context.ksc.neutral500, size: 16) : null,
                prefixText: !isAmount || leadingIcon != null ? null : 'GHS ',
                prefixStyle: AppTextStyles.body.copyWith(
                  color: context.ksc.neutral500, fontWeight: FontWeight.w700),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
