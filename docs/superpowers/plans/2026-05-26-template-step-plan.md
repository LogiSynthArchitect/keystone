# Template Step — Job Wizard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Insert a TEMPLATE step at position 0 of the Add New Job wizard, shifting all 6 existing steps to positions 1–6.

**Architecture:** Single-file change to `log_job_screen.dart` (~3175 lines). No new files, no model changes, no new providers. TEMPLATE step reads from existing `jobTemplateProvider` and pre-fills state fields before user walks through remaining steps.

**Tech Stack:** Flutter/Dart, Riverpod, LineAwesome Icons, KsStepDrawer, KsEmptyState

---

### Task 1: Insert TEMPLATE step into steps list + shift step indices

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart` lines 511–600

- [ ] **Step 1: Prepend TEMPLATE KsStep to the steps list (line ~517)**

Change from 6 steps to 7. Add TEMPLATE as the first entry. Use `LineAwesomeIcons.clipboard_solid` icon. No 3D icon asset exists for templates — use icon-only (the `imageAsset` field remains null, which triggers the icon fallback in `_BigProgressRing`).

```dart
      steps: const [
        KsStep(label: 'TEMPLATE', icon: LineAwesomeIcons.clipboard_solid, subSteps: 1,
          tip: 'Choose a saved template or start fresh'),
        KsStep(label: 'SERVICE', icon: LineAwesomeIcons.wrench_solid, subSteps: 1,
          tip: 'Select the main service performed',
          imageAsset: 'assets/icons/3d/transparent/ff5be0-tools.png'),
        KsStep(label: 'STATUS', icon: LineAwesomeIcons.flag_solid, subSteps: 1,
          tip: 'Set the job status',
          imageAsset: 'assets/icons/3d/transparent/e9828b-flag.png'),
        KsStep(label: 'CUSTOMER', icon: LineAwesomeIcons.user_solid, subSteps: 1,
          tip: 'Enter customer information',
          imageAsset: 'assets/icons/3d/transparent/eec43d-chat-bubble.png'),
        KsStep(label: 'PRICING', icon: LineAwesomeIcons.money_bill_wave_alt_solid, subSteps: 1,
          tip: 'Set the quoted or final amount',
          imageAsset: 'assets/icons/3d/transparent/b801dc-3d-coin.png'),
        KsStep(label: 'SCHEDULE', icon: LineAwesomeIcons.calendar_solid, subSteps: 1,
          tip: 'Set the job date and schedule',
          imageAsset: 'assets/icons/3d/transparent/781f28-calendar.png'),
        KsStep(label: 'EXTRAS', icon: LineAwesomeIcons.boxes_solid, subSteps: 1,
          tip: 'Add parts, expenses, photos, and notes',
          imageAsset: 'assets/icons/3d/transparent/4f52f8-cube.png'),
      ],
```

- [ ] **Step 2: Update `_buildStepByIndex` switch cases (line ~590)**

Old: `case 0` → `_buildStep1()`, `case 5` → `_buildStep6()`, `default` → empty.
New: `case 0` → `_buildStep0()` (new), `case 1` → `_buildStep1()`, ..., `case 6` → `_buildStep6()`.

```dart
  Widget _buildStepByIndex(int step) {
    switch (step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      case 5: return _buildStep5();
      case 6: return _buildStep6();
      default: return const SizedBox.shrink();
    }
  }
```

- [ ] **Step 3: Update `_canMoveForwardForStep` cases (line ~169)**

Old: `case 0` through `case 5`, **with `case 0` requiring `_serviceType != null`**.
New: `case 0` → always true (template step), `case 1` → requires `_serviceType != null` (was case 0), cases 2–6 → same as old cases 1–5.

```dart
  bool _canMoveForwardForStep(int step) {
    final hasCustomer = _finalCustomerId != null;
    switch (step) {
      case 0: return true; // TEMPLATE — always can proceed
      case 1: return _serviceType != null && _serviceType!.isNotEmpty;
      case 2: return true;
      case 3:
        if (_customerController.text.trim().isEmpty) return false;
        if (hasCustomer) return true;
        final phone = _phoneController.text.trim();
        return (phone.length == 10 && phone.startsWith('0')) ||
               (phone.length == 9 && !phone.startsWith('0'));
      case 4:
        final amountText = _amountController.text.trim();
        if (amountText.isEmpty) return true;
        final amount = CurrencyFormatter.parseToPesewas(amountText);
        return amount != null && amount >= 0;
      case 5: return true;
      case 6: return true;
      default: return false;
    }
  }
```

- [ ] **Step 4: Update save-as-template button conditional in `stepContent` (line ~546)**

Old: `if (step == 5)` (which was EXTRAS at index 5).
New: `if (step == 6)` (EXTRAS shifted to index 6).

```dart
      stepContent: (step, subStep, rebuild) {
        // Inject save-as-template button into step 6 (was step 5)
        if (step == 6) {
```

- [ ] **Step 5: Verify with `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze`
Expected: 0 errors, 0 warnings (only the same pre-existing ones about unused imports if any).

---

### Task 2: Add `_buildStep0()` template UI

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart` (insert before `_buildStep1` at line ~602)

- [ ] **Step 1: Add state fields for template tracking**

Add two new instance fields to `_LogJobSheetState` after the existing fields (around line 104):

```dart
  List<JobTemplateEntity> _availableTemplates = [];
  bool _templatesLoaded = false;
```

- [ ] **Step 2: Load templates in `initState`**

Add template loading inside the existing `addPostFrameCallback` in `initState` (around line ~131, after the inventory load):

```dart
      final userId = ref.read(currentUserProvider).valueOrNull?.id;
      if (userId != null) {
        final invItems = ref.read(inventoryProvider.notifier);
        invItems.loadItems(userId);

        // Load templates for the new step 0
        ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
      }
```

- [ ] **Step 3: Add `_buildStep0()` method (insert before `_buildStep1` at line ~602)**

```dart
  Widget _buildStep0() {
    final templatesAsync = ref.watch(jobTemplateProvider);
    final templates = templatesAsync.valueOrNull ?? [];

    if (templates.isEmpty) {
      return KsEmptyState(
        icon: LineAwesomeIcons.clipboard_solid,
        title: 'NO TEMPLATES YET',
        subtitle: 'Save a job as a template from the EXTRAS step\nto reuse it here.',
        actionLabel: 'START FRESH',
        onAction: () {
          // No pre-fill — user manually advances to step 1 via NEXT
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Template cards list
        ...templates.map((t) => _buildTemplateCard(t)),
        const SizedBox(height: 16),
        // START FRESH outlined button
        OutlinedButton.icon(
          onPressed: () {
            // No pre-fill — user manually advances to step 1 via NEXT
          },
          icon: const Icon(LineAwesomeIcons.plus_solid, size: 14),
          label: const Text('START FRESH'),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.ksc.accent500,
            side: BorderSide(color: context.ksc.accent500),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 4: Add `_buildTemplateCard()` helper method**

Insert after `_buildStep0()`:

```dart
  Widget _buildTemplateCard(JobTemplateEntity template) {
    final serviceIcon = ServiceIconMap.getIcon(template.serviceType) ?? LineAwesomeIcons.wrench_solid;
    final partsCount = template.hardwareItems.length + template.parts.length;
    final partsSummary = <String>[];
    if (template.services.isNotEmpty) {
      partsSummary.add('${template.services.length} additional service${template.services.length > 1 ? 's' : ''}');
    }
    if (template.hardwareItems.isNotEmpty) {
      partsSummary.add('${template.hardwareItems.length} hardware item${template.hardwareItems.length > 1 ? 's' : ''}');
    }
    if (template.parts.isNotEmpty) {
      partsSummary.add('${template.parts.length} part${template.parts.length > 1 ? 's' : ''}');
    }
    final summaryStr = partsSummary.isNotEmpty ? partsSummary.join(', ') : 'No additional items';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _applyTemplate(template),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.ksc.primary700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(serviceIcon, color: context.ksc.accent500, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(template.serviceType,
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(summaryStr,
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500, fontSize: 10)),
                  ],
                ),
              ),
              Icon(LineAwesomeIcons.angle_right_solid,
                color: context.ksc.neutral500, size: 16),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 5: Verify with `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze`
Expected: 0 errors (ServiceIconMap must be imported — it should already be imported at line 16).

---

### Task 3: Add `_applyTemplate()` pre-fill logic

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart` (insert new method)

- [ ] **Step 1: Add `_applyTemplate()` method**

Insert before `_saveAsTemplate()` (around line ~192). This method pre-fills state fields from a template entity.

The template stores `hardwareItems` and `parts` in separate lists (TemplateHardwareItem, TemplatePartItem). When loading back, these go into `_items` as ItemRow objects — matching where `_saveAsTemplate` reads them from.

```dart
  void _applyTemplate(JobTemplateEntity template) {
    setState(() {
      // Service type
      _serviceType = template.serviceType;

      // Additional services
      // Dispose existing controllers first
      for (final s in _additionalServices) { s.dispose(); }
      _additionalServices.clear();
      for (final s in template.services) {
        final row = ServiceRow();
        row.serviceType = s.serviceType;
        row.qtyController.text = s.quantity.toString();
        _additionalServices.add(row);
      }

      // Items (hardware + parts) — match _saveAsTemplate split
      for (final i in _items) { i.dispose(); }
      _items.clear();
      final invItems = ref.read(inventoryProvider).valueOrNull ?? [];

      // Hardware items (from inventory)
      for (final h in template.hardwareItems) {
        final row = ItemRow();
        row.nameController.text = h.name;
        row.qtyController.text = h.quantity.toString();
        row.inventoryItemId = h.inventoryItemId;
        if (h.inventoryItemId != null) {
          row.inventoryItem = invItems.where((i) => i.id == h.inventoryItemId).firstOrNull;
        }
        _items.add(row);
      }

      // Parts (non-inventory)
      for (final p in template.parts) {
        final row = ItemRow();
        row.nameController.text = p.name;
        row.qtyController.text = p.quantity.toString();
        row.inventoryItemId = p.inventoryItemId;
        _items.add(row);
      }

      // Notes
      _notesController.text = template.notes ?? '';
    });

    // Show confirmation
    KsSnackbar.show(context, message: 'Template applied — tap NEXT to review', type: KsSnackbarType.info);
  }
```

Note: `ref.read(inventoryProvider)` must be accessible here. The `_LogJobSheetState` already has `ref` from the `ConsumerState` mixin. The `inventoryProvider` is already imported (line 27).

- [ ] **Step 2: Wire `_buildStep0()` and `_buildTemplateCard()` tap to `_applyTemplate`**

The onTap in `_buildTemplateCard()` already calls `_applyTemplate(template)`. The START FRESH button and KsEmptyState action need no pre-fill — the user taps NEXT to proceed with blank fields. The snackbar in `_applyTemplate` tells them what to do.

- [ ] **Step 3: Verify with `flutter analyze`**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze`
Expected: 0 errors.

---

### Task 4: Shift disposal indices + verify `_isDirty` still accurate

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

Since we added no new disposable fields that need changing (`_availableTemplates` and `_templatesLoaded` are plain lists/bools), the `dispose()` method needs no changes. The `_isDirty` getter also needs no changes since it checks `_parts`, `_additionalServices`, `_hardwareItems`, `_items` which are all pre-filled by the template.

- [ ] **Step 1: Run full analyzer**

Run: `/home/cybocrime/Tools/flutter/bin/flutter analyze`
Expected: 0 errors.

- [ ] **Step 2: Run existing service picker tests**

Run: `/home/cybocrime/Tools/flutter/bin/flutter test test/features/job_logging/`
Expected: All pass. Template step addition shouldn't break any existing tests since no existing step logic was changed, only shifted.

---

### Task 5: Hot restart and smoke test on device

- [ ] **Step 1: Hot restart the app**

Run: `pty_write(job_log_screen_session, "R\n")`
Or if using a separate terminal: trigger hot restart.

- [ ] **Step 2: Verify on device**

Open the Add New Job drawer. Confirm:
1. Drawer now shows 7 steps in the ring, step 1/7 says "TEMPLATE"
2. Template step shows template list or empty state
3. Tapping a template card pre-fills the service type and shows snackbar
4. Tapping NEXT advances to SERVICE step with service type pre-selected
5. START FRESH button visible with no pre-fill
6. Navigating through all 7 steps works end-to-end
7. SAVE AS TEMPLATE button still visible at EXTRAS step (now step 6/7)
