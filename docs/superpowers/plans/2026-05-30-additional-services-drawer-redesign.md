# Additional Services Nested Drawer Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace inline qty/price editing in the Additional Services drawer with a nested detail drawer — summary cards in Drawer 1, qty/price editing in Drawer 2.

**Architecture:** Single file change to `log_job_screen.dart`. No new models, entities, or state classes. Two new methods: `_showServiceEditDrawer` (Drawer 2) and `_buildAdditionalServiceSummaryCard` (read-only card). Rewrite `_showAdditionalServicesDrawer` to show summary cards and delegate editing to Drawer 2.

**Tech Stack:** Flutter, Riverpod, LineAwesome icons, KsColors theme.

**Note:** The current code references `_buildServiceCard` at line 663 which does not exist (bug). This plan fixes that by replacing it with the new summary card.

---

## File Structure

**Modify:** `lib/features/job_logging/presentation/screens/log_job_screen.dart`

| Responsibility | Location |
|---|---|
| Drawer 1 — service list + summary cards | Rewrite `_showAdditionalServicesDrawer()` (~lines 2017-2359) |
| Summary card widget (read-only) | New `_buildAdditionalServiceSummaryCard()` method |
| Drawer 2 — qty/price editing | New `_showServiceEditDrawer()` method |
| Step 1 inline reference | Fix `_buildStep1()` line 663 to call new summary card |

---

### Task 1: Add summary card builder + edit drawer method

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart` (insert after `_showAdditionalServicesDrawer`)

**Note on task breakdown:** Tasks 1-2 create the new methods. Task 3 rewrites Drawer 1. Task 4 wires everything together in `_buildStep1`. Tasks 5-6 test and commit.

- [ ] **Step 1: Add `_buildAdditionalServiceSummaryCard` method**

Insert this method into `_LogJobScreenState` (after `_showAdditionalServicesDrawer`). It renders a compact read-only card showing service icon, name, qty × unitPrice, total, and a remove button.

```dart
  /// Read-only summary card for a selected service in Drawer 1.
  /// Tapping opens the edit drawer (Drawer 2).
  Widget _buildAdditionalServiceSummaryCard({
    required int index,
    required _ServiceRow service,
    required List<ServiceTypeEntity> types,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final qty = int.tryParse(service.qtyController.text) ?? 1;
    final unitPrice = CurrencyFormatter.parseToPesewas(service.priceController.text.trim()) ?? 0;
    final total = qty * unitPrice;
    final svcType = types.where((t) => t.name == service.serviceType).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1E2A3A), width: 1)),
          ),
          child: Row(
            children: [
              Icon(
                ServiceIconMap.resolve(svcType?.iconName),
                size: 20,
                color: context.ksc.accent500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Qty: $qty × ${CurrencyFormatter.format(unitPrice)}",
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                    style: AppTextStyles.h3.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(LineAwesomeIcons.times_circle_solid, color: context.ksc.error500, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 2: Add `_showServiceEditDrawer` method**

Insert after `_buildAdditionalServiceSummaryCard`. This opens Drawer 2 for entering/editing qty and price for a single service.

```dart
  /// Drawer 2: Edit qty + price for a single service.
  /// If [existingIndex] is null, the service is new (ADD mode).
  /// If [existingIndex] is set, it's editing an existing service.
  Future<void> _showServiceEditDrawer({
    required _ServiceRow service,
    required int? existingIndex,
    required List<_ServiceRow> localServices,
    required VoidCallback onChanged,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final qty = int.tryParse(service.qtyController.text) ?? 1;
            final unitPrice = CurrencyFormatter.parseToPesewas(service.priceController.text.trim()) ?? 0;
            final total = qty * unitPrice;
            final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
            final svcType = types.where((t) => t.name == service.serviceType).firstOrNull;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existingIndex != null ? "EDIT SERVICE" : "ADD SERVICE",
                            style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Service icon + name (read-only)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(
                          ServiceIconMap.resolve(svcType?.iconName),
                          size: 24,
                          color: context.ksc.accent500,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            service.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: context.ksc.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Qty row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text("QTY",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral600,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildDrawerQtyStepper(service.qtyController, () => setSheetState(() {})),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Unit price field (underline only)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("UNIT PRICE (GHS)",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral600,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: service.priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [CurrencyInputFormatter()],
                                onChanged: (_) => setSheetState(() {}),
                                style: AppTextStyles.body.copyWith(
                                  color: context.ksc.accent500,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: "0.00",
                                  hintStyle: AppTextStyles.body.copyWith(
                                    color: context.ksc.neutral600,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(bottom: 4),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                                  ),
                                  filled: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("GHS",
                              style: AppTextStyles.caption.copyWith(
                                color: context.ksc.neutral500,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Total display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("TOTAL",
                              style: AppTextStyles.caption.copyWith(
                                color: context.ksc.neutral600,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                              style: AppTextStyles.h2.copyWith(
                                color: context.ksc.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text("CANCEL",
                              style: AppTextStyles.label.copyWith(
                                color: context.ksc.neutral400,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.ksc.accent500,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text(
                              existingIndex != null ? "SAVE" : "ADD",
                              style: AppTextStyles.label.copyWith(
                                color: context.ksc.primary900,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
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

    if (result == true) {
      // Service was already mutated via controllers — just trigger rebuild
      onChanged();
    }
  }
```

---

### Task 2: Rewrite `_showAdditionalServicesDrawer` to use summary cards + edit drawer

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart` (replace `_showAdditionalServicesDrawer` method body, lines 2017-2359)

- [ ] **Step 1: Rewrite Drawer 1**

Replace the entire `_showAdditionalServicesDrawer` method. The new version:
- Shows selected services as **summary cards** (using `_buildAdditionalServiceSummaryCard`)
- Tapping a summary card → opens `_showServiceEditDrawer` for editing
- Shows available services grouped by category (same UI as current)
- Tapping an available service → creates `_ServiceRow`, opens `_showServiceEditDrawer` for qty/price
- Has a DONE button that commits to parent

Replace lines 2017-2359 (the entire `_showAdditionalServicesDrawer` method) with:

```dart
  void _showAdditionalServicesDrawer() {
    final localServices = _additionalServices.map((s) {
      final copy = _ServiceRow();
      copy.serviceType = s.serviceType;
      copy.qtyController.text = s.qtyController.text;
      copy.priceController.text = s.priceController.text;
      return copy;
    }).toList();
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final typesAsync = ref.watch(serviceTypeProvider);
            final types = typesAsync.valueOrNull ?? [];

            // Group by category
            final grouped = <String, List>{};
            for (final t in types) {
              grouped.putIfAbsent(t.category, () => []).add(t);
            }
            final categories = grouped.keys.toList()..sort();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ADDITIONAL SERVICES",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                localServices.isNotEmpty
                                    ? "${localServices.length} service${localServices.length > 1 ? 's' : ''}"
                                    : "Tap a service below to add it to this job",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Selected services — summary cards (read-only)
                          if (localServices.isNotEmpty) ...[
                            ...localServices.asMap().entries.map((entry) {
                              return _buildAdditionalServiceSummaryCard(
                                index: entry.key,
                                service: entry.value,
                                types: types,
                                onTap: () {
                                  _showServiceEditDrawer(
                                    service: entry.value,
                                    existingIndex: entry.key,
                                    localServices: localServices,
                                    onChanged: () {
                                      dirty = true;
                                      setSheetState(() {});
                                    },
                                  );
                                },
                                onRemove: () {
                                  localServices.removeAt(entry.key);
                                  entry.value.dispose();
                                  dirty = true;
                                  setSheetState(() {});
                                },
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                          // Category sections
                          ...categories.map((cat) {
                            final items = grouped[cat]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(cat.toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.ksc.neutral500,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                ...items.map((type) {
                                  final alreadyAdded = localServices.any((s) => s.serviceType == type.name);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: InkWell(
                                      onTap: alreadyAdded ? null : () {
                                        final row = _ServiceRow();
                                        row.serviceType = type.name;
                                        if (type.defaultPrice != null) {
                                          row.priceController.text = (type.defaultPrice! / 100.0).toStringAsFixed(2);
                                        }
                                        // Open edit drawer for qty+price, then add
                                        _showServiceEditDrawer(
                                          service: row,
                                          existingIndex: null,
                                          localServices: localServices,
                                          onChanged: () {
                                            localServices.add(row);
                                            dirty = true;
                                            setSheetState(() {});
                                          },
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: alreadyAdded ? context.ksc.primary700.withValues(alpha: 0.3) : context.ksc.primary800,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: alreadyAdded ? context.ksc.neutral600 : context.ksc.primary700,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              ServiceIconMap.resolve(type.iconName),
                                              size: 18,
                                              color: alreadyAdded ? context.ksc.neutral600 : context.ksc.accent500,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(type.name.replaceAll('_', ' ').toUpperCase(),
                                                style: AppTextStyles.body.copyWith(
                                                  color: alreadyAdded ? context.ksc.neutral600 : context.ksc.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            if (type.defaultPrice != null && type.defaultPrice! > 0)
                                              Text(CurrencyFormatter.format(type.defaultPrice!),
                                                style: AppTextStyles.caption.copyWith(
                                                  color: alreadyAdded ? context.ksc.neutral600 : context.ksc.accent500,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            if (alreadyAdded)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Icon(LineAwesomeIcons.check_circle_solid, size: 16, color: context.ksc.neutral600),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  // Pinned DONE button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _additionalServices
                              ..clear()
                              ..addAll(localServices);
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.ksc.accent500,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text("DONE",
                          style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
```

---

### Task 3: Fix `_buildStep1` to use the new summary cards

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart` line 663

- [ ] **Step 1: Fix line 663 in `_buildStep1`**

The current code at line 663 calls `_buildServiceCard` which doesn't exist. Replace it with inline cards showing service name + total (tapping the "ADD SERVICE" button opens the drawer, so the Step 1 inline view should show a compact summary that opens the drawer on tap).

Replace line 663:
```dart
          ..._additionalServices.asMap().entries.map((entry) => _buildServiceCard(entry.key, entry.value)),
```

With a new compact inline summary that opens the drawer when tapped:

```dart
          ..._additionalServices.asMap().entries.map((entry) {
            final svc = entry.value;
            final qty = int.tryParse(svc.qtyController.text) ?? 1;
            final unitPrice = CurrencyFormatter.parseToPesewas(svc.priceController.text.trim()) ?? 0;
            final total = qty * unitPrice;
            final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
            final svcType = types.where((t) => t.name == svc.serviceType).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _showAdditionalServicesDrawer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.ksc.primary800,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.ksc.primary700),
                  ),
                  child: Row(
                    children: [
                      Icon(ServiceIconMap.resolve(svcType?.iconName), size: 16, color: context.ksc.accent500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          svc.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                          style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                        style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
```

---

### Task 4: Build and verify

- [ ] **Step 1: Run build**

```bash
cd projects/keystone && flutter build apk --debug 2>&1 | tail -50
```

Expected: BUILD SUCCESSFUL, no compilation errors.

- [ ] **Step 2: Verify the UI manually (visual check)**

Run on device/emulator and verify:
1. Tap "ADD SERVICE" → Drawer 1 opens with available services list
2. Tap an available service → Drawer 2 opens with qty stepper + price field
3. Set qty and price → tap "ADD" → Drawer 2 closes, service appears as summary card in Drawer 1
4. Tap the summary card → Drawer 2 opens with pre-filled qty/price
5. Change values → tap "SAVE" → summary card updates
6. Tap ✕ on summary card → it's removed
7. Tap "DONE" → changes reflected in Step 1 inline view

---

### Task 5: Commit

- [ ] **Step 1: Commit**

```bash
cd projects/keystone && git add lib/features/job_logging/presentation/screens/log_job_screen.dart && git commit -m "feat: additional services nested drawer — editing moved to dedicated bottom sheet

Replace inline qty/price editing in the Additional Services drawer
with a nested detail drawer. Selected services now show as read-only
summary cards. Tapping a service opens a second bottom sheet for
qty/price entry. Fix missing _buildServiceCard reference in _buildStep1."
```

---

## Spec Coverage Check

| Spec Section | Task(s) |
|---|---|
| Drawer 1 — summary list | Task 2 (rewrite `_showAdditionalServicesDrawer`) |
| Drawer 2 — edit service | Task 1 Step 2 (`_showServiceEditDrawer`) |
| Summary card widget | Task 1 Step 1 (`_buildAdditionalServiceSummaryCard`) |
| Price field: underline only, no background | Task 1 Step 2 (price field decoration) |
| Step 1 inline view update | Task 3 (replace `_buildServiceCard` reference) |
| Dirty tracking + discard confirmation | Task 2 (retained from current code) |
| Local working copy pattern | Task 2 (retained from current code) |
| Available services grouped by category | Task 2 (retained from current code) |
| Disabled-if-already-added in available list | Task 2 (retained from current code) |
