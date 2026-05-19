# Inventory Add/Edit Sheet — Stepper Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace TabBar with a 3-step circular progression indicator for the inventory add/edit bottom sheet.

**Architecture:** Replace `DefaultTabController` + `TabBar` + `TabBarView` with a custom step progression: horizontal step indicator at top + `AnimatedSwitcher` for page transitions + fixed bottom navigation bar (BACK/NEXT/SAVE). All changes in `inventory_screen.dart` only.

**Tech Stack:** Flutter `AnimatedSwitcher` for transitions, custom `Stack` + `Positioned` for step circles + connecting lines.

---

### Task 1: Add step state variable and remove tab imports

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart` (lines 826-877)

**Context:** Current code uses `DefaultTabController(length: 3, ...)` wrapping the entire content. Replace it with raw state + step indicator + content pages + bottom nav.

- [ ] **Step 1: Replace DefaultTabController with raw Column + step int**

Find the current structure at line 826-877:
```dart
builder: (ctx, setSheetState) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            // Header row
            const SizedBox(height: 8),
            // Tab bar
            TabBar(
              ...
              tabs: const [
                Tab(text: "GENERAL"),
                Tab(text: "SPECS"),
                Tab(text: "STOCK"),
              ],
            ),
            const SizedBox(height: 4),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1 — GENERAL
                  // TAB 2 — SPECS
                  // TAB 3 — STOCK
                ],
              ),
            ),
          ],
        ),
      ),
    );
```

Replace with:
```dart
builder: (ctx, setSheetState) {
    int currentStep = 0; // 0=GENERAL, 1=SPECS, 2=STOCK

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          // Header row
          // Step indicator (replaces tab bar)
          _buildStepIndicator(currentStep, setSheetState),
          const SizedBox(height: 8),
          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                );
              },
              child: _buildStepContent(currentStep, ctx, setSheetState),
            ),
          ),
          // Bottom nav bar
          _buildStepNavBar(currentStep, setSheetState, isEditing, nameCtrl, ctx, item, ...),
        ],
      ),
    );
```

Note: The `currentStep` variable is NOT in the outer method scope — it's inside the StatefulBuilder. This means we can use `setSheetState(() => currentStep = n)` to change it.

- [ ] **Step 2: Run flutter analyze to verify no new errors**

Run: `flutter analyze lib/features/inventory/presentation/screens/inventory_screen.dart`
Expected: 0 errors (pre-existing infos only)

- [ ] **Step 3: Commit**

---

### Task 2: Build step indicator widget

**Files:**
- Add: `_buildStepIndicator` method to `inventory_screen.dart`
- No new file needed

**Design:**
- 3 numbered circles in a Row, equally spaced
- Connecting line between circles (via the circles themselves having an accent line between them, or a Container with height)
- Labels below each circle: "GENERAL", "SPECS", "STOCK"
- Circle states:
  - Completed (step < currentStep): accent500 fill, white checkmark icon
  - Current (step == currentStep): accent500 border + fill, white step number
  - Future (step > currentStep): neutral500 border, transparent fill, neutral500 step number

- [ ] **Step 1: Add `_buildStepIndicator` method**

Add after the last existing method in the file (before the final `}`). This is a `Widget Function(int, StateSetter)` that returns:

```dart
Widget _buildStepIndicator(int currentStep, StateSetter setSheetState) {
    final steps = ['GENERAL', 'SPECS', 'STOCK'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final isCompleted = i < currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circle + connecting line
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      // Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? context.ksc.accent500
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted || isCurrent
                                ? context.ksc.accent500
                                : context.ksc.neutral500,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(LineAwesomeIcons.check_solid, size: 14, color: context.ksc.primary900)
                              : Text(
                                  '${i + 1}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isCurrent ? context.ksc.primary900 : context.ksc.neutral500,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      // Connecting line (not after last circle)
                      if (i < 2)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < currentStep
                                ? context.ksc.accent500
                                : context.ksc.primary700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  steps[i],
                  style: AppTextStyles.caption.copyWith(
                    color: isCurrent
                        ? context.ksc.accent500
                        : context.ksc.neutral500,
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze lib/features/inventory/presentation/screens/inventory_screen.dart`
Expected: 0 errors

- [ ] **Step 3: Commit**

---

### Task 3: Extract step content pages and add bottom nav bar

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart`

**Context:** The 3 tab pages (GENERAL, SPECS, STOCK) need to be extracted into a `_buildStepContent` method. The save button currently at the bottom of STOCK tab needs to be moved to a fixed bottom `_buildStepNavBar`.

- [ ] **Step 1: Create `_buildStepContent` wrapper**

This is NOT a separate widget method — it's an inline helper inside `_showItemDialog` (closest to the `build` method). Alternatively, create a new helper method that takes `currentStep` and returns the Widget for that step.

Since the content uses closures and local controllers, keep it inline within the `build` method:

```dart
Widget _buildStepContent(int step, BuildContext ctx, StateSetter setSheetState) {
    switch (step) {
      case 0:
        return SingleChildScrollView(
          key: const ValueKey('general'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NAME * field
              _sheetField("NAME *", nameCtrl, leadingIcon: LineAwesomeIcons.tag_solid),
              const SizedBox(height: 16),
              // AUTO-COGS toggle row
              // ... same as current GENERAL tab content
              const SizedBox(height: 16),
              // TYPE chips
              // ... same as current
              const SizedBox(height: 16),
              // CATEGORY dropdown
              // ... same as current
              const SizedBox(height: 16),
              // BRAND
              _sheetField("BRAND", brandCtrl, leadingIcon: LineAwesomeIcons.tag_solid),
              const SizedBox(height: 16),
              // MODEL
              _sheetField("MODEL", modelCtrl, leadingIcon: LineAwesomeIcons.barcode_solid),
              const SizedBox(height: 24), // bottom padding for scroll
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
              // Quantity stepper
              // ... same as current
              const SizedBox(height: 16),
              // Low stock slider
              // ... same as current
              const SizedBox(height: 16),
              // Location chips
              // ... same as current
              const SizedBox(height: 24),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
```

**Key change:** Remove the `KsButton` from the STOCK content — it moves to the bottom nav bar.

- [ ] **Step 2: Create `_buildStepNavBar`**

After the content (but still within the Column), add a fixed bottom bar:

```dart
// Bottom navigation bar
Container(
  decoration: BoxDecoration(
    color: context.ksc.primary800,
    border: Border(top: BorderSide(color: context.ksc.primary700)),
  ),
  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
  child: Row(
    children: [
      // BACK button (not on first step)
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
      // NEXT or SAVE button
      Expanded(
        flex: currentStep == 0 ? 1 : 2,
        child: currentStep < 2
            ? KsButton(
                label: "NEXT",
                onPressed: nameCtrl.text.trim().isEmpty && currentStep == 0
                    ? null
                    : () => setSheetState(() => currentStep++),
                variant: KsButtonVariant.secondary,
                trailingIcon: LineAwesomeIcons.angle_right_solid,
                size: KsButtonSize.small,
                fullWidth: true,
              )
            : KsButton(
                label: isEditing ? "SAVE CHANGES" : "ADD ITEM",
                onPressed: nameCtrl.text.trim().isEmpty ? null : () async {
                  // ... existing save logic unchanged
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
```

- [ ] **Step 3: Remove save button code from STOCK tab content**

In the STOCK case of `_buildStepContent`, remove these lines:
```dart
const SizedBox(height: 24),
KsButton(
  label: isEditing ? "SAVE CHANGES" : "ADD ITEM",
  ...
),
```

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze lib/features/inventory/presentation/screens/inventory_screen.dart`
Expected: 0 errors

- [ ] **Step 5: Commit**

---

### Task 4: Final verification and deploy

- [ ] **Step 1: Full flutter analyze**

Run: `flutter analyze lib/`
Expected: 0 errors (pre-existing warnings/info only)

- [ ] **Step 2: Start flutter run to phone**

Run: `export ANDROID_HOME=/home/cybocrime/Tools/android-sdk && doppler run --project keystone --config prd -- bash -c 'flutter run -d 192.168.176.55:5555 ...'`

- [ ] **Step 3: Hot restart once app loads**

Send `R` to the PTY session.

- [ ] **Step 4: Take screenshot**

`flutter screenshot -d 192.168.176.55:5555`
Verify step indicator shows correctly and no overflow.
