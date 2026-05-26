# Template Step — Job Wizard Redesign

**Date:** 2026-05-26
**Project:** Keystone
**Feature:** Insert template selection as the first step in the Add New Job wizard

---

## Overview

Insert a new TEMPLATE step at the beginning of the 6-step Add New Job drawer wizard. All existing steps shift right by one position (7 total). The template step lets the user choose from saved job templates to pre-fill service types, additional services, hardware items, parts, and notes across the wizard — or start fresh with blank fields.

## New Step Order

| # | Step | Label | Pre-filled by template? |
|:-:|------|-------|:----------------------:|
| 0 | TEMPLATE | Clipboard/list icon | — |
| 1 | SERVICE | Wrench | Yes (service type + additional services) |
| 2 | STATUS | Flag | No |
| 3 | CUSTOMER | User | No |
| 4 | PRICING | Money | No |
| 5 | SCHEDULE | Calendar | No |
| 6 | EXTRAS | Boxes | Yes (hardware items, parts, notes) |

The KsStepDrawer steps list in `log_job_screen.dart` grows from 6 to 7 entries. All switch-case and conditional indices shift by +1.

## Template Step UI

- **Title:** "TEMPLATE"
- **Subtitle:** "Choose a template or start fresh"
- **If templates exist:**
  - Scrollable list of template cards. Each card shows:
    - Template name (white, bold)
    - Main service type with icon (from `ServiceIconMap`)
    - Summary line: e.g. "3 additional services, 2 hardware items"
    - Tapping a card → pre-fills data, advances to Step 1
  - **START FRESH** gold-outlined `OutlinedButton` at the bottom
- **If no templates exist:**
  - `KsEmptyState` with clipboard icon: "NO TEMPLATES YET"
  - **START FRESH** button below
- Tapping START FRESH or the empty state button: no pre-fill, advances to Step 1

## Pre-fill Logic

When user taps a template card:

```dart
_serviceType = template.serviceType;

_additionalServices = template.services.map((s) {
  final row = ServiceRow();
  row.serviceType = s.serviceType;
  row.qtyController.text = s.quantity.toString();
  return row;
}).toList();

_hardwareItems = template.hardwareItems.map((h) {
  final row = HardwareRow();
  row.nameController.text = h.name;
  row.qtyController.text = h.quantity.toString();
  row.inventoryItemId = h.inventoryItemId;
  if (h.inventoryItemId != null) {
    // Look up inventory item from provider for name/price
    final items = ref.read(inventoryProvider).valueOrNull ?? [];
    row.inventoryItem = items.where((i) => i.id == h.inventoryItemId).firstOrNull;
  }
  return row;
}).toList();

_parts = template.parts.map((p) {
  final row = PartRow();
  row.nameController.text = p.name;
  row.qtyController.text = p.quantity.toString();
  row.inventoryItemId = p.inventoryItemId;
  return row;
}).toList();

_notesController.text = template.notes ?? '';
```

All other fields remain at their defaults (blank/null/0). After pre-filling, call `setState()` and advance to step index 1.

## SAVE AS TEMPLATE Button

Unchanged behavior. Remains at Step 6 (EXTRAS). The current `step == 5` conditional becomes `step == 6`.

## Data Source

Template list comes from the existing `jobTemplateProvider` (Riverpod notifier). No new data layer needed.

```dart
final templates = ref.watch(jobTemplateProvider).valueOrNull ?? [];
```

The provider loads templates from local Hive storage with Supabase remote sync. Already includes `getTemplates(userId)`, `saveTemplate()`, `deleteTemplate()`, `renameTemplate()`.

## Files Changed

| File | Changes |
|------|---------|
| `log_job_screen.dart` | Add `_buildStep0()` method; insert TEMPLATE step into KsStepDrawer steps list; update `_buildStepByIndex` switch (case 0→1, 1→2, etc.); update `step == 5` → `step == 6` for save-as-template button; add template pre-fill handler |

No new files. No model changes. No new providers.

## Edge Cases

- **No templates exist:** Show KsEmptyState with "START FRESH" button. No extra step friction.
- **Template references deleted inventory item:** `inventoryItem` stays null; user sees name from template but no price from inventory. The `isFromInventory` check in HardwareRow handles this gracefully.
- **User picks template then modifies everything:** Normal — template just pre-fills starting values. No locking or restrictions.
