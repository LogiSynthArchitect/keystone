# Extras Tab Drawer Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace flat inline Extras tab sections with summary cards that open modal bottom sheet drawers.

**Architecture:** Single-file refactor of `log_job_screen.dart`. Add `_buildExtrasCard()` helper and 5 `_show*Drawer()` methods. Existing row builders and state lists stay unchanged. Drawers use `showModalBottomSheet` + `StatefulBuilder` for local state.

**Tech Stack:** Flutter, Riverpod, existing theme tokens

---

### Task 1: Add `_buildExtrasCard()` helper + rewrite `_buildStep4()`

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Add `_buildExtrasCard()` helper method** after `_buildStep4()` closing brace

```dart
Widget _buildExtrasCard({
  required Widget icon,
  required String title,
  required String subtitle,
  required Widget trailing,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.ksc.primary700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
            const SizedBox(width: 8),
            Icon(LineAwesomeIcons.angle_right_solid,
              color: context.ksc.neutral500, size: 16),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 2: Add helper methods for trailing widgets**

```dart
Widget _extrasCountTrailing(String count, {String? amount}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(count,
        style: AppTextStyles.caption.copyWith(
          color: context.ksc.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      if (amount != null)
        Text(amount,
          style: AppTextStyles.caption.copyWith(
            color: context.ksc.accent500,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
    ],
  );
}

Widget _extrasEmptyTrailing() {
  return Text("No items",
    style: AppTextStyles.caption.copyWith(
      color: context.ksc.neutral600,
      fontSize: 11,
    ),
  );
}

Widget _extrasNoteTrailing() {
  final text = _notesController.text.trim();
  if (text.isEmpty) {
    return Text("No notes",
      style: AppTextStyles.caption.copyWith(
        color: context.ksc.neutral600,
        fontSize: 11,
      ),
    );
  }
  return Text(text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTextStyles.caption.copyWith(
      color: context.ksc.neutral500,
      fontSize: 11,
      fontStyle: FontStyle.italic,
    ),
  );
}
```

- [ ] **Step 3: Replace `_buildStep4()` body** to use cards instead of inline sections

Replace the content of `_buildStep4()` (lines ~974-1047). The new body:

```dart
Widget _buildStep4() {
  final hwCount = _hardwareItems.length;
  final hwTotal = _hardwareItems.fold<int>(0, (sum, h) {
    final qty = int.tryParse(h.qtyController.text) ?? 1;
    final price = CurrencyFormatter.parseToPesewas(h.salePriceController.text.trim()) ?? 0;
    return sum + (qty * price);
  });
  final expCount = _expenses.length;
  final expTotal = _expenses.fold<int>(0, (sum, e) {
    return sum + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0);
  });
  final partCount = _parts.length;
  final partTotal = _parts.fold<int>(0, (sum, p) {
    return sum + (CurrencyFormatter.parseToPesewas(p.priceController.text.trim()) ?? 0) * (int.tryParse(p.qtyController.text.trim()) ?? 1);
  });
  final photoCount = _beforePhotos.length + _afterPhotos.length;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_finalCustomerId != null)
        _buildCustomerHistorySuggestions(),
      const SizedBox(height: 24),
      _buildExtrasCard(
        icon: Icon(LineAwesomeIcons.lock_solid, size: 16, color: context.ksc.accent500),
        title: "Hardware Items",
        subtitle: "Locks, cylinders, remotes",
        trailing: hwCount > 0
            ? _extrasCountTrailing("$hwCount item${hwCount > 1 ? 's' : ''}", amount: CurrencyFormatter.format(hwTotal))
            : _extrasEmptyTrailing(),
        onTap: () => _showHardwareDrawer(),
      ),
      _buildExtrasCard(
        icon: Icon(LineAwesomeIcons.wallet_solid, size: 16, color: context.ksc.accent500),
        title: "Expenses",
        subtitle: "Transport, parking, subs",
        trailing: expCount > 0
            ? _extrasCountTrailing("$expCount item${expCount > 1 ? 's' : ''}", amount: CurrencyFormatter.format(expTotal))
            : _extrasEmptyTrailing(),
        onTap: () => _showExpensesDrawer(),
      ),
      _buildExtrasCard(
        icon: Icon(LineAwesomeIcons.tools_solid, size: 16, color: context.ksc.accent500),
        title: "Parts Used",
        subtitle: "Parts and supplies",
        trailing: partCount > 0
            ? _extrasCountTrailing("$partCount item${partCount > 1 ? 's' : ''}", amount: CurrencyFormatter.format(partTotal))
            : _extrasEmptyTrailing(),
        onTap: () => _showPartsDrawer(),
      ),
      _buildExtrasCard(
        icon: Icon(LineAwesomeIcons.camera_solid, size: 16, color: context.ksc.accent500),
        title: "Photos",
        subtitle: "Before & after photos",
        trailing: photoCount > 0
            ? _extrasCountTrailing("$photoCount photo${photoCount > 1 ? 's' : ''}")
            : _extrasEmptyTrailing(),
        onTap: () => _showPhotosDrawer(),
      ),
      _buildExtrasCard(
        icon: Icon(LineAwesomeIcons.edit_solid, size: 16, color: context.ksc.accent500),
        title: "Notes",
        subtitle: "Job notes",
        trailing: _extrasNoteTrailing(),
        onTap: () => _showNotesDrawer(),
      ),
      const SizedBox(height: 48),
    ],
  );
}
```

- [ ] **Step 4: Add imports if needed** (check LineAwesomeIcons icons exist)

Check that `LineAwesomeIcons.wallet_solid`, `LineAwesomeIcons.tools_solid`, `LineAwesomeIcons.edit_solid`, `LineAwesomeIcons.angle_right_solid` work. If not, substitute with existing imported icons.

- [ ] **Step 5: Commit after approval** (all tasks done)

---

### Task 2: Create `_showHardwareDrawer()`

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Add `_showHardwareDrawer()` method** after `_buildStep4()`

Uses `showModalBottomSheet` with `StatefulBuilder`. Contains:
- Drag handle
- Header: "HARDWARE ITEMS" + count/total summary
- "SELECT FROM INVENTORY" button (accent, full width) that calls existing `_showInventoryPicker()`
- Existing hardware items as compact cards (reuse `_buildInventoryHardwareCard` / `_buildHardwareRow`)
- "ADD MANUAL ENTRY" button (dashed outline)
- DONE button

```dart
void _showHardwareDrawer() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.ksc.primary800,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final hwCount = _hardwareItems.length;
          final hwTotal = _hardwareItems.fold<int>(0, (sum, h) {
            final qty = int.tryParse(h.qtyController.text) ?? 1;
            final price = CurrencyFormatter.parseToPesewas(h.salePriceController.text.trim()) ?? 0;
            return sum + (qty * price);
          });

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
                            Text("HARDWARE ITEMS",
                              style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              hwCount > 0
                                  ? "$hwCount item${hwCount > 1 ? 's' : ''} · ${CurrencyFormatter.format(hwTotal)}"
                                  : "No items added",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Select from inventory
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showInventoryPicker();
                            },
                            icon: Icon(LineAwesomeIcons.search_solid, size: 16, color: context.ksc.primary900),
                            label: Text("SELECT FROM INVENTORY",
                              style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.ksc.accent500,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Existing items
                        ..._hardwareItems.asMap().entries.map((entry) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildInventoryHardwareCard(entry.key, entry.value),
                          ),
                        ),
                        if (_hardwareItems.isNotEmpty) const SizedBox(height: 8),
                        // Manual entry
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() => _hardwareItems.add(_HardwareRow()));
                              setSheetState(() {});
                            },
                            icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.neutral500),
                            label: Text("Add Manual Entry",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Done button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
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
                        const SizedBox(height: 16),
                      ],
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

### Task 3: Create `_showExpensesDrawer()`

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Add `_showExpensesDrawer()` method**

```dart
void _showExpensesDrawer() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.ksc.primary800,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final expCount = _expenses.length;
          final expTotal = _expenses.fold<int>(0, (sum, e) {
            return sum + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0);
          });

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("EXPENSES",
                              style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              expCount > 0
                                  ? "$expCount item${expCount > 1 ? 's' : ''} · ${CurrencyFormatter.format(expTotal)}"
                                  : "No expenses added",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        ..._expenses.asMap().entries.map((entry) =>
                          _buildExpenseRow(entry.key, entry.value)),
                        if (_expenses.length < 10)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _expenses.add(_ExpenseRow()));
                              setSheetState(() {});
                            },
                            icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
                            label: Text("ADD EXPENSE",
                              style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
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
                        const SizedBox(height: 16),
                      ],
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

### Task 4: Create `_showPartsDrawer()`

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Add `_showPartsDrawer()` method**

Same pattern as expenses drawer but with parts rows and inventory suggestions.

```dart
void _showPartsDrawer() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.ksc.primary800,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final partCount = _parts.length;
          final partTotal = _parts.fold<int>(0, (sum, p) {
            return sum + (CurrencyFormatter.parseToPesewas(p.priceController.text.trim()) ?? 0) * (int.tryParse(p.qtyController.text.trim()) ?? 1);
          });

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("PARTS USED",
                              style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              partCount > 0
                                  ? "$partCount item${partCount > 1 ? 's' : ''} · ${CurrencyFormatter.format(partTotal)}"
                                  : "No parts added",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        ..._parts.asMap().entries.map((entry) =>
                          _buildPartRow(entry.key, entry.value)),
                        if (_parts.length < 20)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _parts.add(_PartRow()));
                              setSheetState(() {});
                            },
                            icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
                            label: Text("ADD PART",
                              style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
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
                        const SizedBox(height: 16),
                      ],
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

### Task 5: Create `_showPhotosDrawer()`

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Add `_showPhotosDrawer()` method**

```dart
void _showPhotosDrawer() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.ksc.primary800,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final photoCount = _beforePhotos.length + _afterPhotos.length;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("PHOTOS",
                              style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              photoCount > 0
                                  ? "$photoCount photo${photoCount > 1 ? 's' : ''}"
                                  : "No photos added",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildPhotoGroup("BEFORE PHOTOS", _beforePhotos),
                        const SizedBox(height: 16),
                        _buildPhotoGroup("AFTER PHOTOS", _afterPhotos),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
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
                        const SizedBox(height: 16),
                      ],
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

### Task 6: Create `_showNotesDrawer()`

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Add `_showNotesDrawer()` method**

```dart
void _showNotesDrawer() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.ksc.primary800,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("NOTES",
                              style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text("Job notes and comments",
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildDarkField(
                          label: "Notes",
                          hint: "Specific hardware used...",
                          controller: _notesController,
                          maxLines: 5,
                          maxLength: 2000,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
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
                        const SizedBox(height: 16),
                      ],
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

### Task 7: Verify and build

- [ ] **Step 1: Check that all referenced icons are valid imports**

Verify `LineAwesomeIcons.wallet_solid`, `tools_solid`, `edit_solid`, `angle_right_solid` exist in the `line_awesome_flutter` package. If not, substitute:
- `wallet_solid` → use `money_solid` or similar
- `tools_solid` → use `wrench_solid` or similar
- `edit_solid` → use `pen_solid` or `pencil_alt_solid`
- `angle_right_solid` → use `chevron_right_solid`

- [ ] **Step 2: Build the app**

Run: `flutter build apk --debug` to verify compilation.
