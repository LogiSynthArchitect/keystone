import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/search_panel_body.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import 'package:keystone/core/widgets/ks_success_moment.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/widgets/ks_summary_strip.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_category_fields.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../data/services/inventory_search_isolate.dart';

enum _ImageUploadState { idle, uploading, uploaded, error }

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
  bool _searchOpen = false;
  String? _coverImagePath;
  String? _coverImageName;
  int? _coverImageSize;
  String? _coverImageUrl;
  _ImageUploadState _uploadState = _ImageUploadState.idle;
  InventoryItemCategory _dialogCategory = InventoryItemCategory.consumable;
  Map<String, dynamic> _dialogAttributes = {};
  int _dialogStockQty = 0;
  int _dialogStockThreshold = 0;
  String _dialogStockLocation = '';
  bool _dialogAutoCogs = false;
  final _searchController = TextEditingController();
  final _searchIsolate = InventorySearchIsolate();
  List<int>? _searchMatchedIndices;
  int _searchSequence = 0;
  bool _searchIsolateInitialized = false;

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

  void _ensureSearchIsolate(List<InventoryItemEntity> items) {
    if (!_searchIsolateInitialized && items.isNotEmpty) {
      _searchIsolateInitialized = true;
      _searchIsolate.initialize(items.map((i) => i.searchIndex ?? '').toList());
    }
  }

  void _onSearchChanged(String query) {
    _searchSequence++;
    final seq = _searchSequence;

    if (query.trim().isEmpty) {
      setState(() => _searchMatchedIndices = null);
      return;
    }

    _searchIsolate.search(query).then((indices) {
      if (mounted && seq == _searchSequence) {
        setState(() => _searchMatchedIndices = indices);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchIsolate.dispose();
    super.dispose();
  }

  List<String> _locations(List<InventoryItemEntity> items) {
    final locs = items.map((i) => i.location).whereType<String>().toSet().toList()..sort();
    return locs;
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final currentType = _filter;
    final currentLocation = _locationFilter;
    final currentView = _groupByLocation ? 'group' : 'flat';
    final allItems = ref.read(inventoryProvider).maybeWhen(
      data: (d) => d,
      orElse: () => <InventoryItemEntity>[],
    );
    final locs = _locations(allItems);

    // Compute counts for each filter option
    final totalCount = allItems.length;
    final catCounts = <InventoryItemCategory, int>{};
    final locCounts = <String, int>{};
    for (final item in allItems) {
      catCounts[item.category] = (catCounts[item.category] ?? 0) + 1;
      if (item.location != null) {
        locCounts[item.location!] = (locCounts[item.location!] ?? 0) + 1;
      }
    }

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
        var draftView = currentView;
        return StatefulBuilder(
          builder: (context, setInnerState) => KsFilterSheet(
            title: "FILTER INVENTORY",
            onApply: () {
              setState(() {
                _filter = draftType;
                _locationFilter = draftLocation;
                _groupByLocation = draftView == 'group';
              });
            },
            onClear: () {
              draftType = 'all';
              draftLocation = 'all';
              draftView = 'flat';
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "TYPE",
                selected: draftType,
                onSelect: (v) => setInnerState(() { if (v != null) draftType = v; }),
                options: [
                  KsFilterOption(value: 'all', display: 'ALL', icon: '📦', count: totalCount),
                  ...InventoryItemCategory.values.map((cat) => KsFilterOption(
                    value: 'cat_${cat.dbValue}',
                    display: cat.displayName,
                    icon: _categoryIcon(cat),
                    count: catCounts[cat] ?? 0,
                  )),
                ],
              ),
              if (locs.isNotEmpty)
                KsFilterChipGroup(
                  label: "LOCATION",
                  selected: draftLocation,
                  onSelect: (v) => setInnerState(() { if (v != null) draftLocation = v; }),
                  options: [
                    KsFilterOption(value: 'all', display: 'ALL LOCATIONS', icon: '📍', count: totalCount),
                    ...locs.map((l) => KsFilterOption(
                      value: l,
                      display: l.toUpperCase(),
                      icon: '🏪',
                      count: locCounts[l] ?? 0,
                    )),
                  ],
                ),
              KsFilterChipGroup(
                label: "VIEW",
                selected: draftView,
                onSelect: (v) => setInnerState(() { if (v != null) draftView = v; }),
                options: const [
                  KsFilterOption(value: 'flat', display: 'FLAT LIST', icon: '📋'),
                  KsFilterOption(value: 'group', display: 'GROUP BY LOCATION', icon: '📂'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<InventoryItemEntity> _filtered(List<InventoryItemEntity> items) {
    _ensureSearchIsolate(items);

    var result = items;
    if (_filter.startsWith('cat_')) {
      final cat = InventoryItemCategory.fromDb(_filter.substring(4));
      result = result.where((i) => i.category == cat).toList();
    }
    if (_locationFilter != 'all') {
      result = result.where((i) => i.location == _locationFilter).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      if (_searchMatchedIndices != null) {
        // Use isolate results — fast O(1) index-set lookup per item
        final indexSet = _searchMatchedIndices!.toSet();
        final indexById = <String, int>{};
        for (int i = 0; i < items.length; i++) {
          indexById[items[i].id] = i;
        }
        result = result.where((i) => indexSet.contains(indexById[i.id])).toList();
      } else {
        // Synchronous fallback — uses searchIndex (single string contains)
        result = result.where((i) => i.searchIndex?.contains(query) ?? false).toList();
      }
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
                  // COGS impact when removing stock
                  if (mode == 'remove' && item.defaultCostPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: qtyCtrl,
                        builder: (ctx, val, _) {
                          final qty = int.tryParse(val.text.trim());
                          if (qty == null || qty <= 0) return const SizedBox.shrink();
                          final cost = qty * item.defaultCostPrice!;
                          return Text(
                            'COGS impact: ~${CurrencyFormatter.format(cost)}',
                            style: AppTextStyles.caption.copyWith(color: context.ksc.error500, fontWeight: FontWeight.w800, fontSize: 10),
                          );
                        },
                      ),
                    ),
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
                        if (mode == 'remove' && qty > item.quantity) {
                          KsSlidingNotification.show(ctx, message: 'Cannot remove more than current stock (${item.quantity})', type: KsNotificationType.error);
                          return;
                        }
                        final change = mode == 'add' ? qty : -qty;
                        await ref.read(inventoryProvider.notifier).adjustStock(
                          itemId: item.id,
                          quantityChange: change,
                          adjustmentType: mode == 'add' ? 'manual_add' : 'manual_remove',
                          reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          KsSlidingNotification.show(context, message: "Stock updated", type: KsNotificationType.success);
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
                        // P0-3a: Warn if unit cost is zero — would skew Auto-COGS
                        if (cost <= 0) {
                          final proceed = await KsConfirmDialog.show(
                            ctx,
                            title: 'ZERO COST',
                            message: 'Zero cost will skew Auto-COGS profit calculations. Proceed?',
                            confirmLabel: 'PROCEED',
                            cancelLabel: 'CANCEL',
                            onConfirm: () {},
                          );
                          if (proceed != true) return;
                        }
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
                          KsSlidingNotification.show(context, message: "Restock recorded", type: KsNotificationType.success);
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
        goldStyle: true,
        searchable: true,
        isSearchOpen: _searchOpen,
        onSearchToggle: () => setState(() => _searchOpen = !_searchOpen),
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.filter_solid,
              color: _filter != 'all' || _locationFilter != 'all' ? context.ksc.accent500 : context.ksc.neutral400,
              size: 22),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: Icon(_showArchived ? LineAwesomeIcons.inbox_solid : LineAwesomeIcons.archive_solid, color: _showArchived ? context.ksc.accent500 : context.ksc.neutral400, size: 20),
            tooltip: "Toggle archived",
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
            },
          ),
        ],
      ),
      body: SearchPanelBody(
        isOpen: _searchOpen,
        searchContent: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: KsSearchBar(
            hint: "Search items...",
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const KsOfflineBanner(),
            // Summary strip
            itemsAsync.whenOrNull(
              data: (items) {
                final filtered = _filtered(items);
                final hasFilter = _filter != 'all' || _locationFilter != 'all' || _searchController.text.trim().isNotEmpty;
                final lowStockCount = items.where((i) => i.isLowStock && !i.isLowStockSnoozed).length;
                final categories = items.map((i) => i.category).toSet().length;
                return KsSummaryStrip(
                  value: hasFilter ? '${filtered.length}' : '${items.length}',
                  label: hasFilter ? "FILTERED ITEMS" : (_showArchived ? "ALL ITEMS (INCL. ARCHIVED)" : "ALL ITEMS"),
                  subtitle: '$lowStockCount low stock ● $categories categories${hasFilter ? ' ● ${filtered.length} shown' : ''}',
                  subtitleIcon: LineAwesomeIcons.cubes_solid,
                );
              },
            ) ?? const SizedBox.shrink(),
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
    final isLow = item.isLowStock;
    final theme = context.ksc;

    // Stock status
    String stockLabel;
    Color stockColor;
    if (item.quantity == 0) {
      stockLabel = 'OUT OF STOCK';
      stockColor = theme.error500;
    } else if (isLow && item.isLowStockSnoozed) {
      stockLabel = 'SNOOZED';
      stockColor = theme.neutral500;
    } else if (isLow) {
      stockLabel = 'LOW STOCK';
      stockColor = theme.warning500;
    } else {
      stockLabel = 'IN STOCK';
      stockColor = const Color(0xFF4CAF50);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.primary800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? theme.warning500.withValues(alpha: 0.5) : theme.primary700,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDialog(item: item),
          onLongPress: () => _confirmDelete(item),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: Photo + Info + Tags ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo thumbnail
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                            ? theme.primary800
                            : theme.primary900,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                              ? theme.accent500.withValues(alpha: 0.2)
                              : theme.primary700,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                          ? Image.network(item.coverImageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(child: Text(_categoryIcon(item.category), style: const TextStyle(fontSize: 26))))
                          : Center(child: Text(_categoryIcon(item.category), style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(item.name.toUpperCase(),
                                    style: AppTextStyles.body.copyWith(color: theme.white, fontWeight: FontWeight.w800),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (item.isArchived)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: theme.neutral500.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                                  child: Text("ARCHIVED", style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontSize: 9, fontWeight: FontWeight.w800)),
                                ),
                            ],
                          ),
                          if (item.brand != null || item.model != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (item.brand != null)
                                  Text(item.brand!, style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontWeight: FontWeight.w600)),
                                if (item.brand != null && item.model != null) ...[
                                  const SizedBox(width: 6),
                                  Text("·", style: AppTextStyles.caption.copyWith(color: theme.neutral600)),
                                  const SizedBox(width: 6),
                                ],
                                if (item.model != null)
                                  Text(item.model!, style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                          // Tags
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              // Category tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.accent500.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(item.category.displayName,
                                    style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: theme.accent500, letterSpacing: 0.5)),
                              ),
                              // Location tag
                              if (item.location != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.primary700.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LineAwesomeIcons.map_pin_solid, size: 9, color: theme.neutral500),
                                      const SizedBox(width: 3),
                                      Text(item.location!.toUpperCase(),
                                          style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: theme.neutral500, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ),
                              // AUTO-COGS tag
                              if (item.isAutoCogs)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.primary500.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text("AUTO-COGS",
                                      style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: theme.primary500, letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──
              Container(height: 1, color: theme.primary700, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),

              // ── Bottom: Stock + Price ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Row(
                  children: [
                    // Stock status
                    Row(
                      children: [
                        Text('${item.quantity}',
                            style: AppTextStyles.h2.copyWith(
                              color: stockColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            )),
                        const SizedBox(width: 6),
                        Text(stockLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: theme.neutral500,
                              letterSpacing: 1,
                            )),
                      ],
                    ),
                    const Spacer(),
                    // Sale price
                    if (item.defaultSalePrice != null || item.defaultCostPrice != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.defaultCostPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(CurrencyFormatter.format(item.defaultCostPrice!),
                                      style: AppTextStyles.body.copyWith(color: theme.neutral500, fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text("COST",
                                      style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w800, color: theme.neutral600, letterSpacing: 1)),
                                ],
                              ),
                            ),
                          if (item.defaultSalePrice != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(CurrencyFormatter.format(item.defaultSalePrice!),
                                    style: AppTextStyles.body.copyWith(color: theme.accent500, fontWeight: FontWeight.w900, fontSize: 14)),
                                Text("SALE",
                                    style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w800, color: theme.neutral600, letterSpacing: 1)),
                              ],
                            ),
                          // Margin indicator (when both cost and sale are set)
                          if (item.defaultCostPrice != null && item.defaultSalePrice != null && item.defaultSalePrice! > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  () {
                                    final profit = item.defaultSalePrice! - item.defaultCostPrice!;
                                    final marginPct = (profit / item.defaultSalePrice! * 100).round();
                                    final color = profit >= 0 ? const Color(0xFF4CAF50) : theme.error500;
                                    return Text('${profit >= 0 ? '+' : ''}${CurrencyFormatter.format(profit)}',
                                        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 10));
                                  }(),
                                  () {
                                    final profit = item.defaultSalePrice! - item.defaultCostPrice!;
                                    final marginPct = item.defaultCostPrice! > 0
                                        ? (profit / item.defaultCostPrice! * 100).round()
                                        : 0;
                                    final color = profit >= 0 ? const Color(0xFF4CAF50) : theme.error500;
                                    return Text('${profit >= 0 ? '+' : ''}$marginPct%',
                                        style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5));
                                  }(),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // ── Attribute chips (own section to prevent overflow) ──
              if (item.attributes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _displayAttributes(item).map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primary700.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: theme.primary700, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${a.$1}: ',
                                style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w700, color: theme.neutral600)),
                            Text(a.$2,
                                style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.w800, color: theme.neutral400)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extracts displayable (label, value) pairs from an item's attributes map,
  /// ordered by the field definitions for the item's category.
  List<(String, String)> _displayAttributes(InventoryItemEntity item) {
    final attrs = item.attributes;
    if (attrs.isEmpty) return [];

    // Map of attribute key → short display label
    const labels = <String, String>{
      'blankNumber': 'Blank', 'keywayType': 'Keyway',
      'hasTransponder': 'TP', 'transponderFrequency': 'Freq',
      'keyMaterial': 'Matrl',
      'lockType': 'Type', 'finish': 'Finish',
      'backset': 'Backset', 'boreSize': 'Bore',
      'securityGrade': 'Grade', 'keyRetainable': 'Key Ret',
      'vehicleMake': 'Make', 'vehicleModels': 'Models',
      'yearStart': 'Year', 'transponderType': 'Chip',
      'immobilizerSystem': 'Immob', 'programmingMethod': 'Prog',
      'protocol': 'Proto', 'voltage': 'Volt', 'connectionType': 'Conn',
      'maxUsers': 'Users',
      'safeType': 'Type', 'fireRating': 'Fire',
      'lockMechanism': 'Mech', 'weight': 'Wt', 'capacity': 'Cap',
      'material': 'Matrl', 'unitType': 'Unit',
      'unitsPerPack': 'Pack', 'supplier': 'Supp',
    };

    // Field keys in display order matching category definitions
    const fieldOrder = [
      'blankNumber', 'keywayType', 'hasTransponder', 'transponderFrequency', 'keyMaterial',
      'lockType', 'finish', 'backset', 'boreSize', 'securityGrade', 'keyRetainable',
      'vehicleMake', 'vehicleModels', 'yearStart', 'yearEnd', 'transponderType', 'immobilizerSystem', 'programmingMethod',
      'protocol', 'voltage', 'connectionType', 'maxUsers',
      'safeType', 'fireRating', 'lockMechanism', 'weight', 'capacity',
      'material', 'unitType', 'unitsPerPack', 'supplier',
    ];

    // For year range, merge yearStart + yearEnd into one entry
    bool hasYearStart = attrs.containsKey('yearStart') && attrs['yearStart'] != null && attrs['yearStart'] != '';
    bool hasYearEnd = attrs.containsKey('yearEnd') && attrs['yearEnd'] != null && attrs['yearEnd'] != '';

    final result = <(String, String)>[];
    for (final key in fieldOrder) {
      if (key == 'yearEnd') continue; // handled with yearStart
      if (key == 'yearStart') {
        if (hasYearStart || hasYearEnd) {
          final startVal = attrs['yearStart']?.toString() ?? '';
          final endVal = attrs['yearEnd']?.toString() ?? '';
          result.add(('Year', hasYearEnd ? '$startVal-$endVal' : startVal));
        }
        continue;
      }
      final val = attrs[key];
      if (val == null || val == '' || val == false) continue;
      final label = labels[key] ?? key;
      String displayVal;
      if (val is bool) {
        displayVal = 'Yes';
      } else {
        displayVal = val.toString();
      }
      result.add((label, displayVal));
    }
    return result;
  }

  Future<void> _pickInventoryImage(StateSetter ss) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    _coverImagePath = picked.path;
    _coverImageName = picked.name;
    _coverImageSize = file.lengthSync();
    _uploadState = _ImageUploadState.uploading;
    ss(() {});

    // Phase 1: Upload to Cloudinary
    final cloudService = CloudinaryService();
    final cloudUrl = await cloudService.uploadMedia(
      file: file,
      publicId: 'inventory_${const Uuid().v4()}',
    );
    if (cloudUrl != null) {
      _coverImageUrl = cloudUrl;
      _uploadState = _ImageUploadState.uploaded;
      ss(() {});
      return;
    }

    // Phase 1b: Fallback to Supabase Storage
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id ?? 'unknown';
      final storagePath = '$userId/${const Uuid().v4()}.jpg';
      await supabase.storage.from('inventory-photos').upload(storagePath, file);
      final publicUrl = supabase.storage.from('inventory-photos').getPublicUrl(storagePath);
      _coverImageUrl = publicUrl;
      _uploadState = _ImageUploadState.uploaded;
      ss(() {});
      return;
    } catch (_) {
      _uploadState = _ImageUploadState.error;
      ss(() {});
    }
  }

  void _clearImage(StateSetter ss) {
    _coverImagePath = null;
    _coverImageName = null;
    _coverImageSize = null;
    _coverImageUrl = null;
    _uploadState = _ImageUploadState.idle;
    ss(() {});
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
        KsSlidingNotification.show(context, message: "Item deleted", type: KsNotificationType.success);
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

    _dialogAutoCogs = item?.isAutoCogs ?? false;
    _dialogStockQty = item?.quantity ?? 0;
    _dialogStockThreshold = item?.lowStockThreshold ?? 0;
    _dialogStockLocation = item?.location ?? '';
    _coverImagePath = null;
    _coverImageName = null;
    _coverImageSize = null;
    _coverImageUrl = item?.coverImageUrl;
    _uploadState = item?.coverImageUrl != null ? _ImageUploadState.uploaded : _ImageUploadState.idle;
    _dialogCategory = item?.category ?? InventoryItemCategory.consumable;
    _dialogAttributes = Map<String, dynamic>.from(item?.attributes ?? {});

    // Snapshot initial values for dirty tracking
    final initialName = item?.name ?? '';
    final initialBrand = item?.brand ?? '';
    final initialModel = item?.model ?? '';
    final initialKeySpec = item?.keySpec ?? '';
    final initialMaterial = item?.material ?? '';
    final initialFinish = item?.finish ?? '';
    final initialDims = item?.dimensions ?? '';
    final initialCostPesewas = item?.defaultCostPrice;
    final initialSalePesewas = item?.defaultSalePrice;
    final initialQty = item?.quantity ?? 0;
    final initialThreshold = item?.lowStockThreshold ?? 0;
    final initialLocation = item?.location ?? '';
    final initialAutoCogs = item?.isAutoCogs ?? false;
    final initialCategory = item?.category ?? InventoryItemCategory.consumable;
    final initialAttributes = Map<String, dynamic>.from(item?.attributes ?? {});
    final hadInitialPhoto = item?.coverImageUrl != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        // Dirty tracking — compares current state against initial snapshot
        bool _hasUnsavedChanges() {
          if (nameCtrl.text.trim() != initialName) return true;
          if (brandCtrl.text.trim() != initialBrand) return true;
          if (modelCtrl.text.trim() != initialModel) return true;
          if (keySpecCtrl.text.trim() != initialKeySpec) return true;
          if (materialCtrl.text.trim() != initialMaterial) return true;
          if (finishCtrl.text.trim() != initialFinish) return true;
          if (dimsCtrl.text.trim() != initialDims) return true;
          if (_dialogCategory != initialCategory) return true;
          // Deep-compare attributes map
          if (_dialogAttributes.length != initialAttributes.length) return true;
          for (final k in initialAttributes.keys) {
            if (_dialogAttributes[k] != initialAttributes[k]) return true;
          }
          for (final k in _dialogAttributes.keys) {
            if (!initialAttributes.containsKey(k)) return true;
          }
          if (_dialogStockQty != initialQty) return true;
          if (_dialogStockThreshold != initialThreshold) return true;
          if (_dialogStockLocation != initialLocation) return true;
          if (_dialogAutoCogs != initialAutoCogs) return true;
          final costP = CurrencyFormatter.parseToPesewas(costCtrl.text.trim());
          final saleP = CurrencyFormatter.parseToPesewas(saleCtrl.text.trim());
          if (costP != initialCostPesewas) return true;
          if (saleP != initialSalePesewas) return true;
          if ((_coverImagePath != null) != hadInitialPhoto) return true;
          return false;
        }

        Future<void> _confirmDiscardSheet() async {
          if (!_hasUnsavedChanges()) {
            if (ctx.mounted) Navigator.pop(ctx);
            return;
          }
          final discard = await KsConfirmDialog.show(
            ctx,
            title: 'DISCARD CHANGES',
            message: 'Item changes have not been saved. Discard them?',
            confirmLabel: 'DISCARD',
            cancelLabel: 'KEEP EDITING',
            isDanger: true,
            onConfirm: () {},
          );
          if (discard == true && ctx.mounted) Navigator.pop(ctx);
        }

        // Save logic moved here for KsStepDrawer.onSave
        Future<void> _handleSave() async {
          // Validate price formats
          final costText = costCtrl.text.trim();
          final saleText = saleCtrl.text.trim();
          final costParsed = CurrencyFormatter.parseToPesewas(costText);
          final saleParsed = CurrencyFormatter.parseToPesewas(saleText);

          if (costText.isNotEmpty && costParsed == null) {
            KsSlidingNotification.show(ctx, message: 'Cost price format is invalid', type: KsNotificationType.error);
            return;
          }
          if (saleText.isNotEmpty && saleParsed == null) {
            KsSlidingNotification.show(ctx, message: 'Sale price format is invalid', type: KsNotificationType.error);
            return;
          }
          // Validation: warn if zero stock
          if (_dialogStockQty == 0) {
            final proceed = await KsConfirmDialog.show(
              ctx,
              title: 'ZERO STOCK',
              message: 'This item has 0 in stock. Save anyway?',
              confirmLabel: 'SAVE ANYWAY',
              cancelLabel: 'CANCEL',
              onConfirm: () {},
            );
            if (proceed != true) return;
          }
          // Validation: warn if cost set but no sale price
          if (costParsed != null && saleParsed == null) {
            KsSlidingNotification.show(ctx,
              title: 'Missing Sale Price',
              message: 'Cost is set but sale price is empty',
              entity: nameCtrl.text.trim(),
              metadata: {'Cost': CurrencyFormatter.format(costParsed!)},
              type: KsNotificationType.info);
          }

          final notifier = ref.read(inventoryProvider.notifier);
          if (isEditing) {
            await notifier.updateItem(item.copyWith(
              name: nameCtrl.text.trim(),
              category: _dialogCategory,
              attributes: _dialogAttributes,
              brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
              model: modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
              keySpec: keySpecCtrl.text.trim().isEmpty ? null : keySpecCtrl.text.trim(),
              material: materialCtrl.text.trim().isEmpty ? null : materialCtrl.text.trim(),
              finish: finishCtrl.text.trim().isEmpty ? null : finishCtrl.text.trim(),
              dimensions: dimsCtrl.text.trim().isEmpty ? null : dimsCtrl.text.trim(),
              defaultCostPrice: costParsed,
              defaultSalePrice: saleParsed,
              quantity: _dialogStockQty,
              lowStockThreshold: _dialogStockThreshold > 0 ? _dialogStockThreshold : null,
              location: _dialogStockLocation.isEmpty ? null : _dialogStockLocation,
              isAutoCogs: _dialogAutoCogs,
              coverImageUrl: _coverImageUrl ?? item.coverImageUrl,
            ));
          } else {
            await notifier.addItem(
              category: _dialogCategory,
              name: nameCtrl.text.trim(),
              attributes: _dialogAttributes,
              brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
              model: modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
              keySpec: keySpecCtrl.text.trim().isEmpty ? null : keySpecCtrl.text.trim(),
              material: materialCtrl.text.trim().isEmpty ? null : materialCtrl.text.trim(),
              finish: finishCtrl.text.trim().isEmpty ? null : finishCtrl.text.trim(),
              dimensions: dimsCtrl.text.trim().isEmpty ? null : dimsCtrl.text.trim(),
              defaultCostPrice: costParsed,
              defaultSalePrice: saleParsed,
              quantity: _dialogStockQty,
              lowStockThreshold: _dialogStockThreshold > 0 ? _dialogStockThreshold : null,
              location: _dialogStockLocation.isEmpty ? null : _dialogStockLocation,
              isAutoCogs: _dialogAutoCogs,
              coverImageUrl: _coverImageUrl,
            );
          }
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) {
            final itemName = nameCtrl.text.trim();
            final details = [
              if (_dialogStockQty > 0) 'Qty: $_dialogStockQty',
              if (_dialogStockLocation.isNotEmpty) _dialogStockLocation,
            ].join(' · ');
            await KsSuccessMoment.show(context,
              title: isEditing ? 'Item Updated' : 'Item Added',
              subtitle: details.isNotEmpty ? '$itemName\n$details' : itemName,
            );
          }
        }

        return KsStepDrawer(
          title: isEditing ? "EDIT ITEM" : "ADD ITEM",
          steps: [
            const KsStep(label: 'IDENTITY', icon: LineAwesomeIcons.tag_solid, subSteps: 2,
              tip: 'Give your item a clear name you\'ll recognize later',
              imageAsset: 'assets/icons/3d/transparent/66b0f8-pencil.png'),
            const KsStep(label: 'DETAILS', icon: LineAwesomeIcons.key_solid, subSteps: 3,
              tip: 'Choose the category and fill in item-specific details',
              imageAsset: 'assets/icons/3d/transparent/778c78-key.png'),
            const KsStep(label: 'SPECS', icon: LineAwesomeIcons.cog_solid,
              tip: 'Add specs and set where this item is stored',
              imageAsset: 'assets/icons/3d/transparent/ff5be0-tools.png'),
            const KsStep(label: 'STOCK', icon: LineAwesomeIcons.cubes_solid,
              tip: 'Set pricing and track how many you have in stock',
              imageAsset: 'assets/icons/3d/transparent/4f52f8-cube.png'),
          ],
          showBackArrow: true,
          onBack: _confirmDiscardSheet,
          nextLabel: "NEXT",
          saveLabel: isEditing ? "SAVE CHANGES" : "ADD ITEM",
          onClose: _confirmDiscardSheet,
          canAdvance: (step, subStep) {
            if (step == 0 && subStep == 0) return nameCtrl.text.trim().isNotEmpty;
            return true;
          },
          onSave: _handleSave,
          stepContent: (step, subStep, setSheetState, _) => _buildStepContent(
            step, subStep,
            nameCtrl, brandCtrl, modelCtrl, keySpecCtrl, materialCtrl,
            finishCtrl, dimsCtrl, costCtrl, saleCtrl,
            setSheetState,
          ),
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      brandCtrl.dispose();
      modelCtrl.dispose();
      keySpecCtrl.dispose();
      materialCtrl.dispose();
      finishCtrl.dispose();
      dimsCtrl.dispose();
      costCtrl.dispose();
      saleCtrl.dispose();
    });
  }

  Widget _buildStepContent(int step, int subStep, TextEditingController nameCtrl, TextEditingController brandCtrl, TextEditingController modelCtrl, TextEditingController keySpecCtrl, TextEditingController materialCtrl, TextEditingController finishCtrl, TextEditingController dimsCtrl, TextEditingController costCtrl, TextEditingController saleCtrl, StateSetter setSheetState) {
    // Sub-step content for step 0 (IDENTITY)
    if (step == 0) {
      if (subStep == 0) {
        // Name only
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(setSheetState, nameCtrl),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
      // subStep == 1: Photo only
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PHOTO", style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text("Add a photo so you can visually identify this item", style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral600, fontSize: 10)),
            const SizedBox(height: 12),
            _buildImageUploadArea(setSheetState),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Sub-step content for step 1 (DETAILS)
    if (step == 1) {
      if (subStep == 0) {
        // Category selection only
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("CATEGORY", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text("Select the type of item", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral600, fontSize: 10)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: InventoryItemCategory.values.map((cat) {
                  final isSelected = _dialogCategory == cat;
                  return GestureDetector(
                    onTap: () async {
                      if (cat == _dialogCategory) return;
                      if (_dialogAttributes.isNotEmpty) {
                        final proceed = await KsConfirmDialog.show(
                          context,
                          title: 'CHANGE CATEGORY',
                          message: 'This will clear the current category fields. Continue?',
                          confirmLabel: 'CHANGE',
                          cancelLabel: 'KEEP',
                          onConfirm: () {},
                        );
                        if (proceed != true) return;
                      }
                      setSheetState(() {
                        _dialogCategory = cat;
                        _dialogAttributes = {};
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary800,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_categoryIcon(cat), style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(cat.displayName,
                            style: AppTextStyles.caption.copyWith(
                              color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
                              fontWeight: FontWeight.w900, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
      if (subStep == 1) {
        // Category-specific fields
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dialogCategory.displayName, style: AppTextStyles.caption.copyWith(
                color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text("Fill in the details for this type of item", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral600, fontSize: 10)),
              const SizedBox(height: 12),
              InventoryCategoryFields(
                category: _dialogCategory,
                attributes: _dialogAttributes,
                onChanged: (updated) => _dialogAttributes = updated,
                rebuild: setSheetState,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
      // subStep == 2: Brand + Model
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("BRAND & MODEL", style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text("Optional brand and model information", style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral600, fontSize: 10)),
            const SizedBox(height: 12),
            _buildPickerField("BRAND", brandCtrl, LineAwesomeIcons.tag_solid,
              const ['Schlage', 'Kwikset', 'Yale', 'Master Lock', 'Mul-T-Lock', 'Abus', 'Medeco', 'Cisa', 'ASSA', 'Baldwin', 'Emtek', 'Stanley', 'Dexter', 'Weiser', 'Von Duprin', 'Hager', 'Cal-Royal', 'Sargent', 'Corbin', 'Dorma', 'Adams Rite', 'Allegion', 'Lockwood'],
              rebuild: setSheetState),
            const SizedBox(height: 16),
            _sheetField("MODEL", modelCtrl, leadingIcon: LineAwesomeIcons.barcode_solid),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // Fall through to original switch for steps 2-3 (SPECS, STOCK)
    switch (step) {
      case 2:
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legacy fields (keySpec, material, finish, dimensions) removed —
              // replaced by category-specific attributes in step 1 (DETAILS).
              // Controllers remain for backward-compatible data preservation.
              // AUTO-COGS toggle
              _buildAutoCogsToggle(setSheetState),
              const SizedBox(height: 16),
              // LOCATION chips
              _buildLocationChips(setSheetState),
              const SizedBox(height: 24),
            ],
          ),
        );
      case 3:
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceField("COST PRICE", costCtrl),
              const SizedBox(height: 16),
              _buildPriceField("SALE PRICE", saleCtrl),
              const SizedBox(height: 16),
              _buildQuantityStepper(setSheetState),
              const SizedBox(height: 16),
              _buildThresholdSlider(setSheetState),
              const SizedBox(height: 24),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _categoryIcon(InventoryItemCategory cat) {
    switch (cat) {
      case InventoryItemCategory.key: return '🔑';
      case InventoryItemCategory.lock: return '🔒';
      case InventoryItemCategory.automotive: return '🚗';
      case InventoryItemCategory.electronic: return '⚡';
      case InventoryItemCategory.safe: return '🔐';
      case InventoryItemCategory.consumable: return '📦';
    }
  }

  Widget _buildAutoCogsToggle(StateSetter ss) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Icon(LineAwesomeIcons.cog_solid, color: context.ksc.neutral500, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("AUTO-COGS", style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'When enabled, the item cost is auto-deducted from job revenue when used in a job',
                      child: Icon(LineAwesomeIcons.question_circle_solid, color: context.ksc.neutral500, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text("Auto-deduct from job revenue", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral600, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: _dialogAutoCogs,
            onChanged: (v) => ss(() => _dialogAutoCogs = v),
            activeThumbColor: context.ksc.accent500,
            activeTrackColor: context.ksc.accent500.withValues(alpha: 0.3),
            inactiveThumbColor: context.ksc.neutral500,
            inactiveTrackColor: context.ksc.primary700,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChips(StateSetter ss) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("LOCATION", style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Row(children: [
          _locationChip(ss, 'van', '🚐 VAN'),
          const SizedBox(width: 8),
          _locationChip(ss, 'workshop', '🔧 WORKSHOP'),
          const SizedBox(width: 8),
          _locationChip(ss, 'other', '📦 OTHER'),
        ]),
      ],
    );
  }

  Widget _locationChip(StateSetter ss, String value, String label) {
    final isSelected = _dialogStockLocation == value;
    return GestureDetector(
      onTap: () => ss(() => _dialogStockLocation = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary800,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(
          color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        )),
      ),
    );
  }

  Widget _buildNameField(StateSetter ss, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("NAME *", style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                Icon(LineAwesomeIcons.tag_solid, color: context.ksc.neutral500, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    onChanged: (_) => ss(() {}),
                    style: AppTextStyles.body.copyWith(color: context.ksc.white),
                    cursorColor: context.ksc.accent500,
                    decoration: const InputDecoration(
                      hintText: "Enter item name...",
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Picker field — shows a value, tapping opens a bottom sheet with options
  Widget _buildPickerField(String label, TextEditingController ctrl, IconData icon, List<String> options, {StateSetter? rebuild}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showOptionsPicker(context, label, ctrl, options, rebuild: rebuild),
          child: Container(
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
            ),
            child: Row(
              children: [
                Icon(icon, color: context.ksc.neutral500, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ctrl.text.isNotEmpty ? ctrl.text : "Select...",
                    style: AppTextStyles.body.copyWith(
                      color: ctrl.text.isNotEmpty ? context.ksc.white : context.ksc.neutral500,
                      fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(LineAwesomeIcons.angle_down_solid, color: context.ksc.neutral500, size: 14),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsPicker(BuildContext context, String label, TextEditingController ctrl, List<String> options, {StateSetter? rebuild}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((opt) {
                      final isSelected = ctrl.text == opt;
                      return GestureDetector(
                        onTap: () {
                          ctrl.text = opt;
                          ctrl.selection = TextSelection.fromPosition(TextPosition(offset: opt.length));
                          Navigator.pop(ctx);
                          rebuild?.call(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? context.ksc.accent500.withValues(alpha: 0.10) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: context.ksc.primary700)),
                          ),
                          child: Row(
                            children: [
                              Text(opt, style: AppTextStyles.body.copyWith(
                                color: isSelected ? context.ksc.accent500 : context.ksc.white,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              )),
                              const Spacer(),
                              if (isSelected)
                                Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceField(String label, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: context.ksc.accent500.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(LineAwesomeIcons.coins_solid, color: context.ksc.accent500, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 1.0)),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.h2.copyWith(
                    color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 20),
                  cursorColor: context.ksc.accent500,
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: AppTextStyles.h2.copyWith(
                      color: context.ksc.neutral500, fontWeight: FontWeight.w900, fontSize: 20),
                    prefixText: 'GHS ',
                    prefixStyle: AppTextStyles.h2.copyWith(
                      color: context.ksc.neutral500, fontWeight: FontWeight.w900, fontSize: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(StateSetter ss) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("QUANTITY", style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(LineAwesomeIcons.cubes_solid, color: context.ksc.neutral500, size: 16),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => ss(() { if (_dialogStockQty > 0) _dialogStockQty--; }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.ksc.primary900, borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(LineAwesomeIcons.minus_solid, size: 16, color: context.ksc.accent500),
                ),
              ),
              const Spacer(),
              Text("$_dialogStockQty", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 22)),
              const Spacer(),
              GestureDetector(
                onTap: () => ss(() => _dialogStockQty++),
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
      ],
    );
  }

  Widget _buildThresholdSlider(StateSetter ss) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("LOW STOCK THRESHOLD", style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(LineAwesomeIcons.bell_solid, color: context.ksc.neutral500, size: 16),
              const SizedBox(width: 12),
              Text("0", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
              Expanded(
                child: Slider(
                  value: _dialogStockThreshold.toDouble(),
                  min: 0, max: 100, divisions: 100,
                  activeColor: context.ksc.accent500,
                  inactiveColor: context.ksc.primary700,
                  onChanged: (v) => ss(() => _dialogStockThreshold = v.round()),
                ),
              ),
              Text("$_dialogStockThreshold", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadArea(StateSetter ss) {
    switch (_uploadState) {
      case _ImageUploadState.idle:
        return GestureDetector(
          onTap: () => _pickInventoryImage(ss),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.ksc.primary600, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(LineAwesomeIcons.camera_solid, color: context.ksc.neutral500, size: 32),
                const SizedBox(height: 8),
                Text("ADD PHOTO", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral400, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text("Tap to select from gallery", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral600, fontSize: 11)),
              ],
            ),
          ),
        );

      case _ImageUploadState.uploading:
        if (_coverImagePath == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Row(
            children: [
              // Preview with spinner overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(_coverImagePath!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A017)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("UPLOADING...", style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(_coverImageName ?? "image", style: AppTextStyles.body.copyWith(
                      color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                    if (_coverImageSize != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(_formatFileSize(_coverImageSize!), style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              // Cancel icon (used when upload is restored)
              GestureDetector(
                onTap: () => _clearImage(ss),
                child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
              ),
            ],
          ),
        );

      case _ImageUploadState.uploaded:
        if (_coverImagePath == null && _coverImageUrl == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ksc.accent500, width: 1.5),
          ),
          child: Row(
            children: [
              // Preview with checkmark badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _coverImagePath != null
                        ? Image.file(File(_coverImagePath!), width: 100, height: 100, fit: BoxFit.cover)
                        : Container(
                            width: 100,
                            height: 100,
                            color: context.ksc.primary700,
                            child: Icon(LineAwesomeIcons.image_solid, color: context.ksc.neutral500, size: 32),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4A017),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Icon(LineAwesomeIcons.check_solid, size: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("UPLOADED", style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(_coverImageName ?? "image", style: AppTextStyles.body.copyWith(
                      color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                    if (_coverImageSize != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(_formatFileSize(_coverImageSize!), style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              // Trash icon
              GestureDetector(
                onTap: () async {
                  final confirmed = await KsConfirmDialog.show(
                    context,
                    title: 'REMOVE PHOTO',
                    message: 'Remove this photo from the item?',
                    confirmLabel: 'REMOVE',
                    cancelLabel: 'KEEP',
                    onConfirm: () {},
                  );
                  if (confirmed == true) _clearImage(ss);
                },
                child: Icon(LineAwesomeIcons.trash_solid, color: context.ksc.error500, size: 18),
              ),
            ],
          ),
        );

      case _ImageUploadState.error:
        return GestureDetector(
          onTap: () => _pickInventoryImage(ss),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.ksc.error500),
            ),
            child: Column(
              children: [
                Icon(LineAwesomeIcons.exclamation_triangle_solid, color: context.ksc.error500, size: 28),
                const SizedBox(height: 8),
                Text("UPLOAD FAILED", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.error500, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text("Tap to retry", style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral600, fontSize: 11)),
              ],
            ),
          ),
        );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _sheetField(String label, TextEditingController controller, {bool isNumeric = false, bool isAmount = false, IconData? leadingIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
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
                prefixIcon: leadingIcon != null && !isAmount
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(leadingIcon, color: context.ksc.neutral500, size: 16),
                      )
                    : null,
                prefix: leadingIcon != null && isAmount
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(leadingIcon, color: context.ksc.neutral500, size: 16),
                          const SizedBox(width: 8),
                          Text('GHS ',
                            style: AppTextStyles.body.copyWith(
                                color: context.ksc.neutral500, fontWeight: FontWeight.w700)),
                        ],
                      )
                    : null,
                prefixText: isAmount && leadingIcon == null ? 'GHS ' : null,
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
